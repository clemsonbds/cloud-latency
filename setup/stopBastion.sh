#!/bin/bash

# tear down any resources for this experiment

region=`./getSetting.sh region`
expName=`./getSetting.sh expName`

./createNetworkBastionHost.py --delete --name ${expName} --region ${region}
