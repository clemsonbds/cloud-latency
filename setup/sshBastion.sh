#!/bin/bash

bastionIP=`./getBastionIP.sh`
bastionKey="~/.ssh/CloudLatencyExpBastion.private"

ssh -i ${bastionKey} ec2-user@${bastionIP}
