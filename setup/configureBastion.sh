#!/bin/bash

instanceKey="ssh/CloudLatencyExpInstance.private"
sshConfig="ssh/config"

bastionKey=`./getSetting.sh bastionKey`
bastionUser=`./getSetting.sh bastionUser`
bastionIP=`./getBastionIP.sh`

# upload the key and config file so bastion can ssh to instances
echo -e "\nConfiguring SSH between bastion and instances."
scp -i ${bastionKey} ${instanceKey} ${bastionUser}@${bastionIP}:.ssh/instanceKey.private
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "chmod 600 .ssh/instanceKey.private"
scp -i ${bastionKey} ${sshConfig} ${bastionUser}@${bastionIP}:.ssh/config

# force bastion to checkout repository
echo -e "\nChecking out repository on bastion."
repo=`./getSetting.sh repo`
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "sudo yum install -y git"
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "sudo mkdir -p /nfs"
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "sudo chmod 777 /nfs"
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "git clone ${repo} /nfs/repos/project"

# hand off to bastion local configuration script
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "/nfs/repos/project/setup/bastion/configure.sh"
