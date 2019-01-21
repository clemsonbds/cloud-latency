#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

platform=${1:-"aws"}
src=$2
dst=$3

bastionIP=`${UTIL}/getBastionIP.sh ${platform}`
bastionKey=`${UTIL}/getSetting.sh bastionPrivateKey ${platform}`
bastionUser=`${UTIL}/getSetting.sh bastionUser ${platform}`

scp -q -i ${bastionKey} ${bastionUser}@${bastionIP}:${src} ${dst}
