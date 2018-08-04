#!/bin/bash

region=`./getSetting.sh region`
expName=`./getSetting.sh expName`

aws ec2 --region ${region} describe-instances --filters "Name=tag:Name,Values=${expName}-Instance" "Name=instance-state-name,Values=running" | grep PRIVATEIPADDRESSES | awk '{$1=$1};1' | cut -d' ' -s -f3 | sort -u
