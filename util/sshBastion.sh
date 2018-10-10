#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

platform=${1:-"aws"}
shift

bastionIP=`${DIR}/getBastionIP.sh ${platform}`
bastionKey=`${DIR}/getSetting.sh bastionPrivateKey ${platform}`
bastionUser=`${DIR}/getSetting.sh bastionUser ${platform}`

ssh -q -i ${bastionKey} ${bastionUser}@${bastionIP} $@
