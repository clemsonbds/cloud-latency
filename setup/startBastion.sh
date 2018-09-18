#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

platform=${1:-"aws"}

region=`${utilDir}/getSetting.sh region ${platform}`
expName=`${utilDir}/getSetting.sh expName ${platform}`

echo "Starting Bastion host cloud resources."
./createNetworkBastionHost.py --create --cloudProvider ${platform} --name ${expName} --region ${region} --keyName JasonAnderson

bastionIP=`${utilDir}/getBastionIP.sh ${platform}`

# wait for bastion to accept SSH
canSSH=
while [ -z "${canSSH}" ]; do
	echo "Waiting for Bastion to accept SSH connections..."
	sleep 1
	canSSH=`nmap ${bastionIP} -PN -p ssh | grep open`
done

${DIR}/configureBastion.sh ${platform}
