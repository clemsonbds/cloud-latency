#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

region=`${utilDir}/getSetting.sh region`
expName=`${utilDir}/getSetting.sh expName`

echo "Starting Bastion host cloud resources."
./createNetworkBastionHost.py --create --name ${expName} --region ${region} --keyName JasonAnderson

bastionIP=`${utilDir}/getBastionIP.sh`

# wait for bastion to accept SSH
canSSH=
while [ -z "${canSSH}" ]; do
	echo "Waiting for Bastion to accept SSH connections..."
	sleep 1
	canSSH=`nmap ${bastionIP} -PN -p ssh | grep open`
done

${DIR}/configureBastion.sh
