#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

#setupDir=${DIR}/../setup
setupDir=${DIR}/.

# cluster grouping, bare metal
for grouping in cluster spread multi-az; do
	for instance_type in bare hv; do
		expType="${grouping}-${instance_type}"
		${setupDir}/stopInstances.sh
		${setupDir}/startInstances.sh ${expType}
		${setupDir}/sshBastion.sh "~/project/run/bastion/run_micro.sh ${expType} $@"
	done
done
