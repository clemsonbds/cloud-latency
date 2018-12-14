#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

setupDir=${DIR}/../setup
utilDir=${DIR}/../util

platform=${1:-"aws"}
shift

# extra arguments will be passed to the call to run_bench.sh on bastion
nodeClassifier="/nfs/getCpuIdentity.sh"

case ${platform} in
aws)
	numItersPerSet=5
	numItersPerProvision=1
	groupTypes+=" cluster"
#	groupTypes+=" spread"
#	groupTypes+=" multi-az"
	instanceTypes+=" vm"
#	instanceTypes+=" vmc5"
#	instanceTypes+=" metal"
	;;
gcp)
	numItersPerSet=6
	numItersPerProvision=5
	groupTypes+=" single-az"
	groupTypes+=" multi-az"
	instanceTypes+=" vm"
	groupClassifier="/nfs/repos/project/util/bandwidthGroupClassifier.sh"
	groupClasses="10Gb,16Gb"
	groupReqHosts=4
	;;
*) # unknown
	echo "Unknown platform '${platform}', valid types are 'aws' and 'gcp'."
	exit
	;;
esac

for i in `seq 1 ${numItersPerSet}`; do
for groupType in ${groupTypes}; do
for instanceType in ${instanceTypes}; do

	completed=
	while [ -z "${completed}" ]; do
		expType="${platform}.${instanceType}.${groupType}"

		runParams="--expType ${expType}"

		${setupDir}/stopInstances.sh ${platform}
		${setupDir}/startInstances.sh ${expType}

		[ ! -z "${nodeClassifier}" ] && runParams+=" --nodeClassifier ${nodeClassifier}"

		if [ ! -z "${groupClassifier}" ]; then
			hostfile="/nfs/instances"
			groupClass=`${utilDir}/classifyGroup.sh ${platform} ${hostfile} ${groupClassifier} ${groupClasses}`
			runParams+=" --groupClass ${groupClass}"

			hostfile="/nfs/${groupClass}.hosts"

			nhosts=`${utilDir}/sshBastion.sh ${platform} "cat ${hostfile} | wc -l"

			if [ "${nhosts}" < "${groupReqHosts}" ]; then
				echo Unable to acquire enough hosts in the same class, reprovisioning.
				continue
			fi

			${utilDir}/sshBastion.sh ${platform} "head -n ${groupReqHosts} ${hostfile} > temp.hosts; mv temp.hosts ${hostfile}"
		fi

		echo -e "\nRunning benchmarks for experiment configuration '${expType}'.\n"

		for j in `seq 1 ${numItersPerProvision}`; do
			echo Starting iteration ${i}-${j}.

			echo Running warmup.
			${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_bench.sh ${runParams} --ep_only --trash $@"

			echo Running micro measurements.
			${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_micro.sh ${runParams} $@"

			echo Running benchmarks.
			${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_bench.sh ${runParams} $@"
		done

		completed=1
	done
done
done
done

${setupDir}/stopInstances.sh ${platform}
