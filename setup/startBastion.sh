#!/bin/bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util
SETUP=${REPO}/setup

platform=${1:-"aws"}
creds=${2:-"default"}

region=`${UTIL}/getSetting.sh region ${platform}`
expName=`${UTIL}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`
projectID=`${UTIL}/getSetting.sh projectID ${platform}`
keyName=`${UTIL}/getSetting.sh bastionKeyPair ${platform}`

echo "Starting Bastion host cloud resources."
${SETUP}/createNetworkBastionHost.py --create --cloudProvider ${platform} --name ${expName} --region ${region} --keyName ${keyName} --projectId ${projectID} --profile ${creds}

bastionIP=`${UTIL}/getBastionIP.sh ${platform}`

# wait for bastion to accept SSH
canSSH=
while [ -z "${canSSH}" ]; do
	echo "Waiting for Bastion to accept SSH connections..."
	sleep 1
	canSSH=`nmap ${bastionIP} -PN -p ssh | grep open`
done

${SETUP}/configureBastion.sh ${platform}
