#!/bin/bash

# create NFS
echo -e "\nStarting NFS server on bastion."
sudo yum install -y nfs-utils rpcbind
echo "/nfs 10.0.0.0/16(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -a
sudo service rpcbind start
sudo service nfs start

# installing needed stuff
sudo yum install -y openmpi openmpi-devel
echo "export PATH=$PATH:/usr/lib64/openmpi/bin" >> ~/.bashrc

# fetch benchmarks
git clone https://github.com/Rakurai/mpi-pingpong.git /nfs/repos/benchmarks/pingpong
