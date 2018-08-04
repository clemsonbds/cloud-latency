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
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "sudo mkdir -p /nfs"
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "sudo chmod 777 /nfs"
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "git clone ${repo} /nfs/repo"

# place a list of instance IPs on bastion
./getInstanceIPs.sh > instances.txt
scp -i ${bastionKey} instances.txt ${bastionUser}@${bastionIP}:.
rm instances.txt

# hand off to bastion configuration script
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "/nfs/repo/setup/bastion/configure.sh"
