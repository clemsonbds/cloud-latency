#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# place a list of instance IPs on bastion
echo -e "\nUploading instance IPs to bastion."
${utilDir}/getInstanceIPs.sh > instances
${utilDir}/scpBastion.sh instances /nfs/instances
rm instances

# hand off to local instance config script on bastion
${utilDir}/sshBastion.sh "~/project/setup/bastion/configureInstances.sh"
