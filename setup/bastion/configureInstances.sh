#!/bin/bash

bastionLocalIP=`ifconfig | grep eth0 -A 1 | tail -n 1 | awk '{print $2}'`

# wait for all instances to accept SSH
for instanceIP in `cat ~/hostfile`; do
	canSSH=
	while [ -z "${canSSH}" ]; do
		echo "Waiting for instance ${instanceIP} to accept SSH connections..."
		sleep 1
		canSSH=`nmap ${instanceIP} -PN -p ssh | grep open`
	done
done

# force all instances to mount NFS
echo -e "\nMounting NFS share on instances."
for instanceIP in `cat ~/hostfile`; do
	ssh ${instanceIP} "sudo mkdir -p /nfs"
	ssh ${instanceIP} "sudo chmod 777 /nfs"
	ssh ${instanceIP} "sudo mount -t nfs ${bastionLocalIP}:/nfs /nfs"
done

# force all instances to run their config scripts
for instanceIP in `cat ~/hostfile`; do
	ssh ${instanceIP} "/nfs/repos/project/setup/instance/configure.sh"
done
