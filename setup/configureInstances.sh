#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

platform=${1:-"aws"}

# place a list of instance IPs on bastion
echo -e "\nUploading instance IPs to bastion."
${utilDir}/getInstanceIPs.sh ${platform} > instances
${utilDir}/scpBastion.sh ${platform} instances /nfs/instances
rm instances

# hand off to local instance config script on bastion
${utilDir}/sshBastion.sh ${platform} "~/project/setup/bastion/configureInstances.sh"
