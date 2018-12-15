#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

provider=${1:-"aws"}

instanceKey="${DIR}/../assets/ssh/CloudLatencyExpInstance.private"
sshConfig="${DIR}/../assets/ssh/config"

# upload the key and config file so bastion can ssh to instances
echo -e "\nConfiguring SSH between bastion and instances."
${utilDir}/scpBastion.sh ${provider} ${instanceKey} .ssh/instanceKey.private
${utilDir}/sshBastion.sh ${provider} "chmod 600 .ssh/instanceKey.private"
${utilDir}/scpBastion.sh ${provider} ${sshConfig} .ssh/config
${utilDir}/sshBastion.sh ${provider} "chmod 600 .ssh/config"

# force bastion to checkout repository
echo -e "\nChecking out repository on bastion."
repo=`${utilDir}/getSetting.sh repo`
${utilDir}/sshBastion.sh ${provider} "sudo yum install -y git"
${utilDir}/sshBastion.sh ${provider} "sudo mkdir -p /nfs"
${utilDir}/sshBastion.sh ${provider} "sudo chmod 777 /nfs"
${utilDir}/sshBastion.sh ${provider} "git clone ${repo} /nfs/repos/project"
${utilDir}/sshBastion.sh ${provider} "ln -s /nfs/repos/project ~/project"
${utilDir}/sshBastion.sh ${provider} "sudo mkdir -p /nfs/resources"

# Write out the script to identify the CPU Family for the instance
${utilDir}/sshBastion.sh ${provider} "~/project/util/generateCpuIdentityScript.sh ${provider}"

# hand off to bastion local configuration script
${utilDir}/sshBastion.sh ${provider} "~/project/setup/bastion/configure.sh"

# MPI location dependent on platform
if [ "${provider}" == "gcp" ]; then
	# use newer 2.1.1 from source, yum installs 1.7.x on Centos
	mpiDir="/opt/ompi-2-1-1"
else
	# use the yum installed openmpi, 2.1.1 currently on AWS
	mpiDir="/usr/lib64/openmpi"
fi

${utilDir}/sshBastion.sh ${provider} "echo 'export PATH="'$PATH'":"${mpiDir}"/bin' > /nfs/resources/mpi_bin_bashrc"

# point PATH at the right MPI directory
${utilDir}/sshBastion.sh ${provider} "cat /nfs/resources/mpi_bin_bashrc >> ~/.bashrc"

# special Makefile for Intel MPI benchmarks
${utilDir}/sshBastion.sh ${provider} "cp ~/project/intelmpi/Makefile.${provider} /nfs/resources/Makefile.intelmpi"

${utilDir}/sshBastion.sh ${provider} "~/project/setup/bastion/prepareBenchmarks.sh"
