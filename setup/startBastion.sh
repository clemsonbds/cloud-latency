#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

platform=${1:-"aws"}
creds=${2:-"default"}

region=`${utilDir}/getSetting.sh region ${platform}`
expName=`${utilDir}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`
projectID=`${utilDir}/getSetting.sh projectID ${platform}`
keyName=`${utilDir}/getSetting.sh bastionKeyPair ${platform}`

echo "Starting Bastion host cloud resources."
${DIR}/createNetworkBastionHost.py --create --cloudProvider ${platform} --name ${expName} --region ${region} --keyName ${keyName} --projectId ${projectID} --profile ${creds}

bastionIP=`${utilDir}/getBastionIP.sh ${platform}`

# wait for bastion to accept SSH
canSSH=
while [ -z "${canSSH}" ]; do
	echo "Waiting for Bastion to accept SSH connections..."
	sleep 1
	canSSH=`nmap ${bastionIP} -PN -p ssh | grep open`
done

${DIR}/configureBastion.sh ${platform}
