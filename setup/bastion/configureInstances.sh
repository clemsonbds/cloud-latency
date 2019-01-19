#!/bin/bash

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)

bastionLocalIP=`/usr/sbin/ifconfig | grep eth0 -A 1 | tail -n 1 | awk '{print $2}'`

# wait for all instances to accept SSH
for instanceIP in `cat /nfs/instances`; do
	canSSH=
	while [ -z "${canSSH}" ]; do
		echo "Waiting for instance ${instanceIP} to accept SSH connections..."
		sleep 1
		canSSH=`nmap ${instanceIP} -PN -p ssh | grep open`
	done
done

# make sure the instances have nfs-utils installed, might as well do yum update here too -- done in Image
#echo -e "\nInstalling packages on instances for NFS filesystem."
#for instanceIP in `cat /nfs/instances`; do
#	ssh -q ${instanceIP} "sudo yum update -y -q; sudo yum install -y -q nfs-utils" &
#done

# wait for them all to be done
wait

# force all instances to mount NFS
echo -e "\nMounting NFS share on instances."
for instanceIP in `cat /nfs/instances`; do
	ssh -q ${instanceIP} "sudo mkdir -p /nfs"
	ssh -q ${instanceIP} "sudo chmod 777 /nfs"
#	ssh -q ${instanceIP} "sudo firewall-cmd --permanent --zone=public --add-service=nfs"
#	ssh -q ${instanceIP} "sudo firewall-cmd --permanent --zone=public --add-service=mountd"
#	ssh -q ${instanceIP} "sudo firewall-cmd --permanent --zone=public --add-service=rpc-bind"
#   ssh -q ${instanceIP} "sudo firewall-cmd --reload"
	ssh -q ${instanceIP} "sudo mount -t nfs ${bastionLocalIP}:/nfs /nfs"
done

# force all instances to run their config scripts
for instanceIP in `cat /nfs/instances`; do
	ssh -q ${instanceIP} "/nfs/repos/project/setup/instance/configure.sh" &
done

# wait for them all to be done
wait
