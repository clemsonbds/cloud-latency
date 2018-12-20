#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

provider=${1:-"aws"}

instanceKey="${DIR}/../assets/ssh/CloudLatencyExpInstance.private"
sshConfig="${DIR}/../assets/ssh/config"

# remove yum-installed openmpi
# ${utilDir}/sshBastion.sh ${provider} "sudo yum remove -y openmpi"

# upload the key and config file so bastion can ssh to instances
echo -e "\nConfiguring SSH between bastion and instances."
${utilDir}/scpBastion.sh ${provider} ${instanceKey} .ssh/instanceKey.private
${utilDir}/sshBastion.sh ${provider} "chmod 600 .ssh/instanceKey.private"
${utilDir}/scpBastion.sh ${provider} ${sshConfig} .ssh/config
${utilDir}/sshBastion.sh ${provider} "chmod 600 .ssh/config"

# force bastion to checkout repository
echo -e "\nChecking out repository on bastion."
repo=`${utilDir}/getSetting.sh repo`
# ${utilDir}/sshBastion.sh ${provider} "sudo yum install -y git"
${utilDir}/sshBastion.sh ${provider} "sudo mkdir -p /nfs"
${utilDir}/sshBastion.sh ${provider} "sudo chmod 777 /nfs"
${utilDir}/sshBastion.sh ${provider} "git clone ${repo} /nfs/repos/project"
${utilDir}/sshBastion.sh ${provider} "ln -s /nfs/repos/project ~/project"
${utilDir}/sshBastion.sh ${provider} "mkdir -p /nfs/resources"

# platform-specific files for instances
${utilDir}/sshBastion.sh ${provider} "cp ~/project/assets/bash/bashrc.instance.${provider} /nfs/resources/bashrc.instance"
${utilDir}/sshBastion.sh ${provider} "~/project/util/generateCpuIdentityScript.sh ${provider}"
${utilDir}/sshBastion.sh ${provider} "cp ~/project/intelmpi/Makefile.${provider} /nfs/resources/Makefile.intelmpi"

# hand off to bastion local configuration scripts
${utilDir}/sshBastion.sh ${provider} "~/project/setup/bastion/configure.sh"

${utilDir}/sshBastion.sh ${provider} "~/project/setup/bastion/prepareBenchmarks.sh"
