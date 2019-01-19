#!/bin/bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

platform=${1:-"aws"}

expName=`${UTIL}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`

[ "${platform}" == "aws" ] && place=`${UTIL}/getSetting.sh region ${platform}`
[ "${platform}" == "gcp" ] && place=`${UTIL}/getSetting.sh projectID ${platform}`

${UTIL}/getIpAddresses.py "internal" ${expName} ${platform} ${place}
