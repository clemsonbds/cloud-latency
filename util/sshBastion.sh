#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

platform=${1:-"aws"}
shift

bastionIP=`${UTIL}/getBastionIP.sh ${platform}`
bastionKey=`${UTIL}/getSetting.sh bastionPrivateKey ${platform}`
bastionUser=`${UTIL}/getSetting.sh bastionUser ${platform}`

ssh -q -i ${bastionKey} ${bastionUser}@${bastionIP} $@
