#!/bin/bash

bastionIP=`ifconfig | grep eth0 -A 1 | grep inet | awk '{print $2}'`

# create NFS
sudo yum install nfs-utils rpcbind
echo "/nfs 10.0.0.0/16(rw,sync,no_subtree_check)" | sudo tee -a /etc/exports

sudo exportfs -a
sudo service rpcbind start
sudo service nfs start

# force all instances to mount NFS
for instance in `cat ~/instances.txt`; do
	ssh ${instance} "sudo mkdir -p /nfs"
	ssh ${instance} "sudo chmod 777 /nfs"
	ssh ${instance} "sudo mount -t nfs ${bastionIP}:/nfs /nfs"
done

# force all instances to run their config scripts
for instance in `cat ~/instances.txt`; do
	ssh ${instance} "/nfs/repo/setup/instance/configure.sh"
done
