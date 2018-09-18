#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

setupDir=${DIR}/../setup
utilDir=${DIR}/../util

platform=${1:-"aws"}
shift

# extra arguments will be passed to the call to run_micro.sh on bastion

case ${platform} in
aws)
	numIterations=10
	groupTypes="cluster spread multi-az"
	instanceTypes="vm metal"
	;;
gcp)
	numIterations=1
	groupTypes="single-az multi-az"
	instanceTypes="vm"
	;;
*) # unknown
	echo "Unknown platform '${platform}', valid types are 'aws' and 'gcp'."
	exit
	;;
esac

for i in `seq 1 ${numIterations}`; do
	for groupType in ${groupTypes}; do
		for instanceType in ${instanceTypes}; do
			expType="${platform}-${groupType}-${instanceType}"
			${setupDir}/stopInstances.sh
			${setupDir}/startInstances.sh ${expType}

			echo -e "\nRunning benchmarks for experiment configuration '${expType}'.\n"
			${utilDir}/sshBastion.sh "~/project/run/bastion/run_micro.sh --expType ${expType} $@"
		done
	done
done

${setupDir}/stopInstances.sh
