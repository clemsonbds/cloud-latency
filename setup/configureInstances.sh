#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

platform=${1:-"aws"}
mpi_slots=${2:-1}

# delete the known hosts on the bastion in case there are IP conflicts
${utilDir}/sshBastion ${platform} "rm ~/.ssh/known_hosts"

# place a list of instance IPs on bastion
echo -e "\nUploading instance IPs to bastion."
${utilDir}/getInstanceIPs.sh ${platform} > instances
${utilDir}/scpBastion.sh ${platform} instances /nfs/instances

# use the instances to describe MPI hosts
cat instances | awk '{print $0, " slots='${mpi_slots}'"}' > mpi.hosts
${utilDir}/scpBastion.sh ${platform} mpi.hosts /nfs/mpi.hosts

rm instances
rm mpi.hosts

# hand off to local instance config script on bastion
${utilDir}/sshBastion.sh ${platform} "~/project/setup/bastion/configureInstances.sh"
