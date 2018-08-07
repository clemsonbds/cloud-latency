#!/bin/bash

region=`./getSetting.sh region`
expName=`./getSetting.sh expName`

echo "Starting Bastion host cloud resources."
./createNetworkBastionHost.py --create --name ${expName} --region ${region} --keyName JasonAnderson

bastionIP=`./getBastionIP.sh`

# wait for bastion to accept SSH
canSSH=
while [ -z "${canSSH}" ]; do
	echo "Waiting for Bastion to accept SSH connections..."
	sleep 1
	canSSH=`nmap ${bastionIP} -PN -p ssh | grep open`
done

./configureBastion.sh
