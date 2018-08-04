#!/bin/bash

instanceKey="../keys/CloudLatencyExpInstance.private"
bastionKey="~/.ssh/CloudLatencyExpBastion.private"
bastionUser="ec2-user"
bastionIP=`./getBastionIP.sh`

# upload the key so bastion can ssh to instances
scp -i ${bastionKey} ${instanceKey} ${bastionUser}@${bastionIP}:.ssh/instanceKey.private
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "chmod 600 .ssh/instanceKey.private"

# create a handy .ssh/config file on the bastion
echo 'IdentityFile ~/.ssh/instanceKey.private' > config.temp
echo 'StrictHostKeyChecking no' >> config.temp
echo 'UserKnownHostsFile=/dev/null' >> config.temp
scp -i ${bastionKey} config.temp ${bastionUser}@${bastionIP}:.ssh/config
rm config.temp

# force bastion to checkout repository
repo=`./getSetting.sh repo`
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "sudo yum install -y git"
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "git clone ${repo} repo"

# hand off to bastion configuration script
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "~/repo/setup/bastion/configure.sh"
