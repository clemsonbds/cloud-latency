#!/bin/bash

bastionLocalIP=`ifconfig | grep eth0 -A 1 | tail -n 1 | awk '{print $2}'`

# force all instances to mount NFS
echo -e "\nMounting NFS share on instances."
for instance in `cat ~/instances.txt`; do
	ssh ${instance} "sudo mkdir -p /nfs"
	ssh ${instance} "sudo chmod 777 /nfs"
	ssh ${instance} "sudo mount -t nfs ${bastionLocalIP}:/nfs /nfs"
done

# force all instances to run their config scripts
for instance in `cat ~/instances.txt`; do
	ssh ${instance} "/nfs/repos/project/setup/instance/configure.sh"
done
