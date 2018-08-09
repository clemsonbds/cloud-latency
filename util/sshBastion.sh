#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

bastionIP=`${DIR}/getBastionIP.sh`
bastionKey="~/.ssh/CloudLatencyExpBastion.private"
bastionUser=`${DIR}/getSetting.sh bastionUser`

ssh -q -i ${bastionKey} ${bastionUser}@${bastionIP} $@
