#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# tear down any resources for this experiment

region=`${utilDir}/getSetting.sh region`
expName=`${utilDir}/getSetting.sh expName`

${DIR}/launchInstances.py --delete --name ${expName} --region ${region}
