#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# place a list of instance IPs on bastion
echo -e "\nUploading instance IPs to bastion."
instances=`${utilDir}/getInstanceIPs.sh`
${utilDir}/sshBastion.sh "echo ${instances} > /nfs/instances"

# hand off to local instance config script on bastion
${utilDir}/sshBastion.sh "~/project/setup/bastion/configureInstances.sh"
