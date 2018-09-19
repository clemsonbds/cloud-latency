#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

platform=${1:-"aws"}

# tear down any resources for this experiment

region=`${utilDir}/getSetting.sh region ${platform}`
expName=`${utilDir}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`
projectID=`${utilDir}/getSetting.sh projectID ${platform}`

${DIR}/launchInstances.py --delete --cloudProvider ${platform} --name ${expName} --region ${region} --projectId ${projectID}
