#!/bin/bash

# Usage : AutoScale4BKS3.sh <SourceDir> <DestBacketName>

InstanceID=`curl http://169.254.169.254/latest/meta-data/instance-id`
SrcDir=$1
Backet=$2

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

## S3にsync
Backup2S3 $1 $2
if [ $? -ne 0 ] ;then
	exit 2
fi
exit 0
