#!/bin/bash

# Usage : AutoScale4BKS3.sh <SourceDir> <DestBacketName> B|R

InstanceID=`curl http://169.254.169.254/latest/meta-data/instance-id`
SrcDir=$1
Backet=$2
flgfile=/tmp/AutoScale4BKS3.tmp

Backup2S3(){
	aws s3 sync \
		--region ap-northeast-1 \
		${SrcDir} \
		s3://${Backet} \
		--delete
	if [ $? -eq 0 ] ; then
		return 0
	else
		return 2
	fi
}

RestoreS3() {
	aws s3 sync \
		--region ap-northeast-1 \
		s3://${Backet} \
		${SrcDir} \
		--delete
	if [ $? -eq 0 ] ; then
		return 0
	else
		return 2
	fi
}

CheckSrcDst(){
	if [ ! -d ${SrcDir} ] ; then
		return 2
	fi
	aws s3 ls \
		--region ap-northeast-1 \
		s3://${Backet} > /dev/null
	if [ $? -ne 0 ] ;then
		return 2
	fi
	return 0
}

CheckLaunchAutoScale(){
	aws autoscaling describe-auto-scaling-instances \
		--region ap-northeast-1 \
		--instance-ids ${InstanceID} \
		| jq '.AutoScalingInstances[] | .InstanceId' \
		| grep ${InstanceID}
	if [ $? -eq 0 ] ; then
		return 0
	else
		return 2
	fi
}

## オートスケールで起動したインスタンスであることを確認
CheckLaunchAutoScale
if [ $? -ne 0 ] ;then
	exit 2
fi

## SourceとDestの存在確認
CheckSrcDst $1 $2
if [ $? -ne 0 ] ;then
	exit 2
fi

case $3 in
	"B" ) ## S3にsync
		if [ ! -f ${flgfile} ] ;then
			Backup2S3
			if [ $? -ne 0 ] ;then
				exit 2
			fi
		fi
		;;
	"R" ) ## S3からリストア
		date > ${flgfile}
		RestoreS3
		rc=$?
		rm -f ${flgfile}
		if [ ${rc} -ne 0 ] ;then
			exit 2
		fi
		;;
	* ) ## オプションの指定が間違っている場合
		echo "B or R"
		;;
esac
exit 0
