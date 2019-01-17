#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

platform=${1:-"aws"}

expName=`${DIR}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`

[ "${platform}" == "aws" ] && place=`${DIR}/getSetting.sh region ${platform}`
[ "${platform}" == "gcp" ] && place=`${DIR}/getSetting.sh projectID ${platform}`

${DIR}/getIpAddresses.py "internal" ${expName} ${platform} ${place}
