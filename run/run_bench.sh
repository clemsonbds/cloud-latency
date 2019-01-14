#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util
setupDir=${DIR}/../setup

bastionUtilDir="/nfs/repos/project/util"
nodeClassifier="/nfs/resources/getCpuIdentity.sh"
hostfile="/nfs/mpi.hosts"
numItersPerSet=1
numItersPerProvision=1

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
aws)
    platform="aws"
    shift # past argument
    ;;
gcp)
	platform="gcp"
	shift
	;;
--platform)
	platform="$2"
	shift
	shift
	;;
--hostfile)
	hostfile="$2"
	shift
	shift
	;;
--numSets)
	numItersPerSet="$2"
	shift
	shift
	;;
--numIters)
	numItersPerProvision="$2"
	shift
	shift
	;;
--groupTypes)
	groupTypes=`echo "$2" | tr ',' ' '`
	shift
	shift
	;;
--instanceTypes)
	instanceTypes=`echo "$2" | tr ',' ' '`
	shift
	shift
	;;
--skip_warmup)
	skip_warmup=1
	shift
	;;
--skip_micro)
	skip_micro=1
	shift
	;;
--skip_bench)
	skip_bench=1
	shift
	;;
*)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# extra arguments will be passed to the calls to run_bench.sh and run_micro.sh on bastion

case ${platform} in
aws)
	[ -z "${groupTypes}" ] && groupTypes="cluster spread multi-az"
	[ -z "${instanceTypes}" ] && instanceTypes="vm vmc5 metal"
	groupClassifier="${bastionUtilDir}/bandwidthGroupClassifier.sh"
	groupClassLabels="15Gb 10Gb 5Gb" # in order, most desirable class first
	groupClassMeans="15000000000 10000000000 5000000000"
	groupClassOrder="descending" # match class order above
	groupReqHosts=4
	;;
gcp)
	[ -z "${groupTypes}" ] && groupTypes="single-az multi-az"
	[ -z "${instanceTypes}" ] && instanceTypes="vm"
	groupClassifier="${bastionUtilDir}/bandwidthGroupClassifier.sh"
	groupClassLabels="16Gb 10Gb" # in order, most desirable class first
	groupClassMeans="15000000000 10000000000"
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
		runParams=" --hostfile ${hostfile}" # must be included, --host acts as a filter

		${setupDir}/stopInstances.sh ${platform}
		${setupDir}/startInstances.sh ${expType}

		[ ! -z "${nodeClassifier}" ] && runParams+=" --nodeClassifier ${nodeClassifier}"

		if [ ! -z "${groupClassifier}" ]; then
			${utilDir}/sshBastion.sh ${platform} "${groupClassifier} ${hostfile} --class_names ${groupClassLabels} --class_means ${groupClassMeans} --${groupClassOrder}"
			foundClass=

			for class in `echo ${groupClasses} | tr ',' ' '`; do
				classHostfile="/nfs/${class}.hosts"
				hosts=`${utilDir}/sshBastion.sh ${platform} "${bastionUtilDir}/hostfileToHosts.sh ${classHostfile} ${groupReqHosts}"`
				nhosts=`echo ${hosts} | tr ',' ' ' | wc -w`

				if [ "${nhosts}" -ge "${groupReqHosts}" ]; then
					echo "Found the required ${nhosts} in class ${class}."
					runParams+=" --groupClass ${class} --host ${hosts}"
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

		if [ -z "${skip_warmup}" ]; then
			echo Running warmup.
			${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_bench.sh --expType warmup ${runParams} $@"
		fi

		for j in `seq 1 ${numItersPerProvision}`; do
			echo Starting iteration ${i}-${j}.

			if [ -z "${skip_micro}" ]; then
				echo Running micro measurements.
				${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_micro.sh --expType ${expType} ${runParams} $@"
			fi

			if [ -z "${skip_bench}" ]; then
				echo Running benchmarks.
				${utilDir}/sshBastion.sh ${platform} "~/project/run/bastion/run_bench.sh --expType ${expType} ${runParams} $@"
			fi
		done

		completed=1
	done
done
done
done

${setupDir}/stopInstances.sh ${platform}
