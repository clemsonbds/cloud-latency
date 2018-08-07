#!/bin/bash

bastionKey=`./getSetting.sh bastionKey`
bastionUser=`./getSetting.sh bastionUser`
bastionIP=`./getBastionIP.sh`

# place a list of instance IPs on bastion
echo -e "\nUploading instance IPs to bastion."
./getInstanceIPs.sh > hostfile
scp -i ${bastionKey} hostfile ${bastionUser}@${bastionIP}:.
rm hostfile

# hand off to local instance config script on bastion
ssh -i ${bastionKey} ${bastionUser}@${bastionIP} "/nfs/repos/project/setup/bastion/configureInstances.sh"
