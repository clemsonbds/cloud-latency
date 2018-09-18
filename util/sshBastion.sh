#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

platform=${1:-"aws"}

bastionIP=`${DIR}/getBastionIP.sh ${platform}`
bastionKey=`${DIR}/getSetting.sh bastionKey ${platform}`
bastionUser=`${DIR}/getSetting.sh bastionUser ${platform}`

ssh -q -i ${bastionKey} ${bastionUser}@${bastionIP} $@
