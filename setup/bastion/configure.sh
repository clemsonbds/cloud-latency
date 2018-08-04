#!/bin/bash

# create NFS
sudo yum install nfs-utils rpcbind
sudo mkdir -p /nfs
sudo chmod 777 /nfs
echo "/nfs 10.0.0.0/16(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

sudo exportfs -a
sudo service rpcbind start
sudo service nfs start

# hard link to repo in nfs

