#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

platform=${1:-"aws"}

# tear down any resources for this experiment

region=`${utilDir}/getSetting.sh region ${platform}`
expName=`${utilDir}/getSetting.sh expName ${platform}`

${DIR}/createNetworkBastionHost.py --delete --cloudProvider ${platform} --name ${expName} --region ${region}
