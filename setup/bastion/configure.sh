#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)

# installing needed stuff
# sudo yum update -y -q
# sudo yum install -y -q nmap # testing SSH to instances
# sudo yum install -y -q nfs-utils rpcbind # NFS server
# sudo yum install -y -q openmpi openmpi-devel # MPI benchmarks
# sudo yum install -y -q gcc-c++ wget # LAMMPS
# sudo yum install -y -q python-pip # needed to get networkx
# sudo pip install networkx # needed for iperf classifier
sudo yum install -y -q python3

# create NFS
echo -e "\nStarting NFS server on bastion."
echo "/nfs 10.0.0.0/16(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
# sudo firewall-cmd --permanent --zone=public --add-service=nfs
# sudo firewall-cmd --permanent --zone=public --add-service=mountd
# sudo firewall-cmd --permanent --zone=public --add-service=rpc-bind
# sudo firewall-cmd --reload
sudo exportfs -a
sudo service rpcbind start
sudo service nfs start

echo "source /nfs/resources/bashrc.instance" >> ~/.bashrc
