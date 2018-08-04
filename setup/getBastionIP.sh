#!/bin/bash

region=`./getSetting.sh region`
expName=`./getSetting.sh expName`

aws ec2 --region ${region} describe-instances --filters "Name=tag:Name,Values=${expName}-BastionHost" "Name=instance-state-name,Values=running" | grep INSTANCES | awk '{$1=$1};1' | cut -d' ' -s -f14
