#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

setupDir=${DIR}/../setup
utilDir=${DIR}/../util

platform=${1:-"aws"}
shift

# extra arguments will be passed to the call to run_bench.sh on bastion

case ${platform} in
aws)
	numItersPerSet=5
	numItersPerProvision=1
	groupTypes="cluster spread multi-az"
#	groupTypes="spread"
	instanceTypes="vm vmc5 metal"
#	instanceTypes="vm"
	;;
gcp)
	numItersPerSet=6
	numItersPerProvision=5
	groupTypes="single-az multi-az"
	instanceTypes="vm"
	;;
*) # unknown
	echo "Unknown platform '${platform}', valid types are 'aws' and 'gcp'."
	exit
	;;
esac

for i in `seq 1 ${numItersPerSet}`; do
	echo Starting outer iteration ${i}.

	for groupType in ${groupTypes}; do
		for instanceType in ${instanceTypes}; do
			expType="${platform}.${instanceType}.${groupType}"
			${setupDir}/stopInstances.sh ${platform}
			${setupDir}/startInstances.sh ${expType}

			echo -e "\nRunning benchmarks for experiment configuration '${expType}'.\n"
			trash="--trash"

			for j in `seq 0 ${numItersPerProvision}`; do
				[ "$j" -eq "1" ] && trash=""

				echo Starting inner iteration ${j}.

				${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_bench.sh --expType ${expType} ${trash} $@"
			done
		done
	done
done

${setupDir}/stopInstances.sh ${platform}
