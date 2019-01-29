#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

platform=${1:-"aws"}
mpi_slots=${2:-1}

# delete the known hosts on the bastion in case there are IP conflicts
${UTIL}/sshBastion.sh ${platform} "rm -f ~/.ssh/known_hosts"

# place a list of instance IPs on bastion
echo -e "\nUploading instance IPs to bastion."
${UTIL}/getInstanceIPs.sh ${platform} > instances
${UTIL}/scpBastion.sh ${platform} instances /nfs/instances

# use the instances to describe MPI hosts
cat instances | awk '{print $0, " slots='${mpi_slots}'"}' > mpi.hosts
${UTIL}/scpBastion.sh ${platform} mpi.hosts /nfs/mpi.hosts

rm instances
rm mpi.hosts

# hand off to local instance config script on bastion
${UTIL}/sshBastion.sh ${platform} "~/project/setup/bastion/configureInstances.sh"
