#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

setupDir=${DIR}/../setup
#setupDir=${DIR}/.
utilDir=${DIR}/../util

groupTypes=
groupTypes+="cluster "
groupTypes+="spread "
groupTypes+="multi-az "

instanceTypes=
#instanceTypes+="metal "
instanceTypes+="vm "

# cluster grouping, bare metal
for group in ${groupTypes}; do
	for instance in ${instanceTypes}; do
		expType="${group}-${instance}"
		${setupDir}/stopInstances.sh
		${setupDir}/startInstances.sh ${expType}

		echo -e "\nRunning benchmarks for experiment configuration '${expType}'.\n"
		${utilDir}/sshBastion.sh "~/project/run/bastion/run_micro.sh --expType ${expType} $@"
	done
done

${setupDir}/stopInstances.sh
