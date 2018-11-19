#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

setupDir=${DIR}/../setup
utilDir=${DIR}/../util

platform=${1:-"aws"}
shift

# extra arguments will be passed to the call to run_bench.sh on bastion

case ${platform} in
aws)
	numIterations=1
	groupTypes="cluster spread multi-az"
	instanceTypes="vm metal"
	;;
gcp)
	numIterations=10
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
			expType="${platform}.${instanceType}.${groupType}"
			${setupDir}/stopInstances.sh ${platform}
			${setupDir}/startInstances.sh ${expType}

			echo -e "\nRunning benchmarks for experiment configuration '${expType}'.\n"
			${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_bench.sh --expType ${expType} $@"
		done
	done
done

${setupDir}/stopInstances.sh ${platform}
