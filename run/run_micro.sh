#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

setupDir=${DIR}/../setup
utilDir=${DIR}/../util

# cluster grouping, bare metal
for group in cluster spread multi-az; do
	for instance in metal vm; do
		expType="${group}-${instance}"
		${setupDir}/stopInstances.sh
		${setupDir}/startInstances.sh ${expType}

		echo -e "\nRunning benchmarks for experiment configuration '${expType}'.\n"
		${utilDir}/sshBastion.sh "~/project/run/bastion/run_micro.sh --expType ${expType} $@"
	done
done

${setupDir}/stopInstances.sh
