#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

instanceKey="${DIR}/ssh/CloudLatencyExpInstance.private"
sshConfig="${DIR}/ssh/config"

# upload the key and config file so bastion can ssh to instances
echo -e "\nConfiguring SSH between bastion and instances."
${utilDir}/scpBastion.sh ${instanceKey} .ssh/instanceKey.private
${utilDir}/sshBastion.sh "chmod 600 .ssh/instanceKey.private"
${utilDir}/scpBastion.sh ${sshConfig} .ssh/config

# force bastion to checkout repository
echo -e "\nChecking out repository on bastion."
repo=`${utilDir}/getSetting.sh repo`
${utilDir}/sshBastion.sh "sudo yum install -y git"
${utilDir}/sshBastion.sh "sudo mkdir -p /nfs"
${utilDir}/sshBastion.sh "sudo chmod 777 /nfs"
${utilDir}/sshBastion.sh "git clone ${repo} /nfs/repos/project"
${utilDir}/sshBastion.sh "ln -s /nfs/repos/project ~/project"

# hand off to bastion local configuration script
${utilDir}/sshBastion.sh "~/project/setup/bastion/configure.sh"
