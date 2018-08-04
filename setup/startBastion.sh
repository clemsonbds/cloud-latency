#!/bin/bash

region=`./getSetting.sh region`
expName=`./getSetting.sh expName`

echo "Starting Bastion host cloud resources."
./createNetworkBastionHost.py --create --name ${expName} --region ${region} --keyName JasonAnderson

./configureBastion.sh
