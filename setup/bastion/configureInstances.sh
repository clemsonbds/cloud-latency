#!/bin/bash

# force all instances to mount NFS
echo -e "\nMounting NFS share on instances."
for instance in `cat ~/instances.txt`; do
	ssh ${instance} "sudo mkdir -p /nfs"
	ssh ${instance} "sudo chmod 777 /nfs"
	ssh ${instance} "sudo mount -t nfs ${bastionIP}:/nfs /nfs"
done

# force all instances to run their config scripts
for instance in `cat ~/instances.txt`; do
	ssh ${instance} "/nfs/repo/setup/instance/configure.sh"
done
