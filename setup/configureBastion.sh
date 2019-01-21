#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

provider=${1:-"aws"}

instanceKey="${REPO}/assets/ssh/CloudLatencyExpInstance.private"
sshConfig="${REPO}/assets/ssh/config"

# remove yum-installed openmpi
# ${UTIL}/sshBastion.sh ${provider} "sudo yum remove -y openmpi"

# upload the key and config file so bastion can ssh to instances
echo -e "\nConfiguring SSH between bastion and instances."
${UTIL}/scpBastion.sh ${provider} ${instanceKey} .ssh/instanceKey.private
${UTIL}/sshBastion.sh ${provider} "chmod 600 .ssh/instanceKey.private"
${UTIL}/scpBastion.sh ${provider} ${sshConfig} .ssh/config
${UTIL}/sshBastion.sh ${provider} "chmod 600 .ssh/config"

# force bastion to checkout repository
echo -e "\nChecking out repository on bastion."
repo=`${UTIL}/getSetting.sh repo`
# ${UTIL}/sshBastion.sh ${provider} "sudo yum install -y git"
${UTIL}/sshBastion.sh ${provider} "sudo mkdir -p /nfs"
${UTIL}/sshBastion.sh ${provider} "sudo chmod 777 /nfs"
${UTIL}/sshBastion.sh ${provider} "git clone ${repo} /nfs/repos/project"
${UTIL}/sshBastion.sh ${provider} "ln -s /nfs/repos/project ~/project"
${UTIL}/sshBastion.sh ${provider} "mkdir -p /nfs/resources"

# platform-specific files for instances
${UTIL}/sshBastion.sh ${provider} "cp ~/project/assets/bash/bashrc.instance.${provider} /nfs/resources/bashrc.instance"
${UTIL}/sshBastion.sh ${provider} "~/project/util/generateCpuIdentityScript.sh ${provider}"
${UTIL}/sshBastion.sh ${provider} "cp ~/project/benchmarks/intelmpi/Makefile.${provider} /nfs/resources/Makefile.intelmpi"

# hand off to bastion local configuration scripts
${UTIL}/sshBastion.sh ${provider} "~/project/setup/bastion/configure.sh"

${UTIL}/sshBastion.sh ${provider} "~/project/setup/bastion/prepareBenchmarks.sh"
