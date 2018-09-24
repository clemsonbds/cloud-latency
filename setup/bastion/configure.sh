#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

# installing needed stuff
sudo yum update -y -q
sudo yum install -y -q nmap # testing SSH to instances
sudo yum install -y -q nfs-utils rpcbind # NFS server
sudo yum install -y -q openmpi openmpi-devel # MPI benchmarks
echo 'export PATH=$PATH:/usr/lib64/openmpi/bin' >> ~/.bashrc

# create NFS
echo -e "\nStarting NFS server on bastion."
echo "/nfs 10.0.0.0/16(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo firewall-cmd --permanent --zone=public --add-service=nfs,mountd,rpc-bind
sudo firewall-cmd --reload
sudo exportfs -a
sudo service rpcbind start
sudo service nfs start
