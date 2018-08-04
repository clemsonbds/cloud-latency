#!/bin/bash

# tear down any resources for this experiment

region=`./getSetting.sh region`
expName=`./getSetting.sh expName`

./launchInstances.py --delete --name ${expName} --region ${region}
./createNetworkBastionHost.py --delete --name ${expName} --region ${region}
