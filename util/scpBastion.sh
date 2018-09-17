#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

bastionIP=`${DIR}/getBastionIP.sh`
bastionKey=`${DIR}/getSetting.sh bastionKey`
bastionUser=`${DIR}/getSetting.sh bastionUser`

scp -q -i ${bastionKey} $1 ${bastionUser}@${bastionIP}:$2
