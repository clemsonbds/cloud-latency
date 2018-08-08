#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

region=`${DIR}/getSetting.sh region`
expName=`${DIR}/getSetting.sh expName`

aws ec2 --region ${region} describe-instances --filters "Name=tag:Name,Values=${expName}-BastionHost" "Name=instance-state-name,Values=running" | grep INSTANCES | awk '{$1=$1};1' | cut -d' ' -s -f14
