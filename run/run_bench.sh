#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

setupDir=${DIR}/../setup
utilDir=${DIR}/../util
bastionUtilDir="/nfs/repos/project/util"

platform=${1:-"aws"}
shift

# extra arguments will be passed to the call to run_bench.sh on bastion
nodeClassifier="/nfs/resources/getCpuIdentity.sh"
hostfile="/nfs/instances"

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
	groupClassifier="${bastionUtilDir}/bandwidthGroupClassifier.sh"
	groupClasses="16Gb,10Gb" # in order, most desirable class first
	groupClassOrder="descending" # match class order above
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
			${utilDir}/classifyGroup.sh ${platform} ${hostfile} ${groupClassifier} ${groupClasses} ${groupClassOrder}
			foundClass=

			for class in `echo ${groupClasses} | tr ',' ' '`; do
				classHostfile="/nfs/${class}.hosts"
				hosts=`${utilDir}/sshBastion.sh ${platform} "${bastionUtilDir}/hostfileToHosts.sh ${classHostfile} ${groupReqHosts}"`
				nhosts=`echo ${hosts} | tr ',' ' ' | wc -w`

				if [ "${nhosts}" -gte "${groupReqHosts}" ]; then
					echo "Found the required ${nhosts} in class ${class}."
					runParams+=" --groupClass ${class} --hosts ${hosts}"
					foundClass=1
					break
				fi
			done

			if [ -z "${foundClass}" ]; then
				echo "Unable to acquire enough hosts in the same class, reprovisioning."
				continue
			fi
		else
			runParams+=" --hostfile ${hostfile}"
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
