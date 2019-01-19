#!/bin/bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util
SETUP=${REPO}/setup

platform=${1:-"aws"}
creds=${2:-"default"}

# tear down any resources for this experiment

region=`${UTIL}/getSetting.sh region ${platform}`
expName=`${UTIL}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`
projectID=`${UTIL}/getSetting.sh projectID ${platform}`

${SETUP}/launchInstances.py --delete --cloudProvider ${platform} --name ${expName} --region ${region} --projectId ${projectID} --profile ${creds}
