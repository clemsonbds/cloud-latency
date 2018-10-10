#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

platform=${1:-"aws"}
src=$2
dst=$3

bastionIP=`${DIR}/getBastionIP.sh ${platform}`
bastionKey=`${DIR}/getSetting.sh bastionPrivateKey ${platform}`
bastionUser=`${DIR}/getSetting.sh bastionUser ${platform}`

scp -q -i ${bastionKey} ${src} ${bastionUser}@${bastionIP}:${dst}
