#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

platform=${1:-"aws"}

region=`${DIR}/getSetting.sh region ${platform}`
expName=`${DIR}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`
projectID=`${DIR}/getSetting.sh projectID ${platform}`

if [ "${platform}" == "aws" ]; then
	aws ec2 --region ${region} describe-instances --filters "Name=tag:Name,Values=${expName}-BastionHost" "Name=instance-state-name,Values=running" | grep INSTANCES | awk '{$1=$1};1' | cut -d' ' -s -f14
elif [ "${platform}" == "gcp" ]; then
	python ${DIR}/getGcpIpAddresses.py ${projectID} ${expName} "bastion"
fi
