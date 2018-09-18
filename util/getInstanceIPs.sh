#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

platform=${1:-"aws"}

region=`${DIR}/getSetting.sh region ${platform}`
expName=`${DIR}/getSetting.sh expName ${platform}`

if [ "${platform}" == "aws" ]; then
	aws ec2 --region ${region} describe-instances --filters "Name=tag:Name,Values=${expName}-Instance" "Name=instance-state-name,Values=running" | grep PRIVATEIPADDRESSES | awk '{$1=$1};1' | cut -d' ' -s -f3 | sort -u
elif [ "${platform}" == "gcp" ]; then
	echo NOT YET IMPLEMENTED
fi
