#!/bin/bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util
SETUP=${REPO}/setup

BASTION_REPO="/nfs/repos/project"
BASTION_UTIL="${BASTION_REPO}/util"
BASTION_RUN="${BASTION_REPO}/run"
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
--groupClass)
	groupReqClass="$2"
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
	groupClassifier="${BASTION_UTIL}/bandwidthGroupClassifier.sh"
	groupClassLabels="15Gb 10Gb 5Gb" # in order, descending
	groupClassThresholds="9800000000 5500000000" # must match class label order
	groupReqHosts=4
	;;
gcp)
	[ -z "${groupTypes}" ] && groupTypes="single-az multi-az"
	[ -z "${instanceTypes}" ] && instanceTypes="vm"
	groupClassifier="${BASTION_UTIL}/bandwidthGroupClassifier.sh"
	groupClassLabels="16Gb 10Gb" # in order, descending
	groupClassThresholds="9800000000" # must match class label order
	groupReqHosts=4
	;;
*) # unknown
	echo "Unknown platform '${platform}', valid types are 'aws' and 'gcp'."
	exit
	;;
esac

for outer_iter in `seq 1 ${numItersPerSet}`; do
for groupType in ${groupTypes}; do
for instanceType in ${instanceTypes}; do

	completed=
	while [ -z "${completed}" ]; do
		expType="${platform}.${instanceType}.${groupType}"
		runParams=" --hostfile ${hostfile}" # must be included, the MPI parameter --host acts as a filter

		${SETUP}/stopInstances.sh ${platform}
		${SETUP}/startInstances.sh ${expType}

		# specify a node classifier to be run by all experiments
		[ ! -z "${nodeClassifier}" ] && runParams+=" --nodeClassifier ${nodeClassifier}"

		# make sure we're running experiments with all the same class of node
		if [ ! -z "${groupClassifier}" ]; then
			# classify the nodes
			nclasses=`echo ${groupClassLabels} | wc -w`
			classes_csv=`${UTIL}/sshBastion.sh ${platform} "${groupClassifier} ${hostfile} --labels ${groupClassLabels} --thresholds ${groupClassThresholds}" | tail -n ${nclasses}`
			foundClass=

			# limit to classes with enough nodes to run our experiment
			for line in `echo ${classes_csv}`; do
				class=`echo ${line} | cut -d, -f1`

				# if we specified a particular class, we don't care about others
				[ ! -z "${groupReqClass}" ] && [ "${groupReqClass}" != "${class}" ] && continue

				# get and count the hosts in the class
				hostfilter=`echo ${line} | cut -d, -f2-`
				nhosts=`echo ${hostfilter} | tr ',' ' ' | wc -w`

				# if there isn't enough in this class, keep looking
				# TODO: start deprovisioning the hosts we don't need
				[ "${nhosts}" -lt "${groupReqHosts}" ] && continue

				# if there is enough, we can stop looking and move on
				echo "Found ${nhosts} of the required ${groupReqHosts} in class ${class}."

				# shorten to the first N hosts that we require
				hostfilter=`echo ${hostfilter} | cut -d, -f1-"${groupReqHosts}"`

				# set our run parameters for all the experiments
				runParams+=" --groupClass ${class} --hostfilter ${hostfilter}"
				foundClass=1
				break
			done

			# TODO: throw away some and get new ones instead of grabbing another random bunch of hosts
			if [ -z "${foundClass}" ]; then
				echo "Unable to acquire enough hosts in the same class, reprovisioning."
				continue
			fi
		fi

		echo -e "\nRunning benchmarks for experiment configuration '${expType}'.\n"

		if [ -z "${skip_warmup}" ]; then
			echo Running warmup.
			${UTIL}/sshBastion.sh ${platform} "${BASTION_RUN}/run_bench.sh --expType warmup ${runParams} $@"
		fi

		for inner_iter in `seq 1 ${numItersPerProvision}`; do
			echo Starting iteration ${outer_iter}-${inner_iter}.

			if [ -z "${skip_micro}" ]; then
				echo Running micro measurements.
				${UTIL}/sshBastion.sh ${platform} "${BASTION_RUN}/run_micro.sh --expType ${expType} ${runParams} $@"
			fi

			if [ -z "${skip_bench}" ]; then
				echo Running benchmarks.
				${UTIL}/sshBastion.sh ${platform} "${BASTION_RUN}/run_bench.sh --expType ${expType} ${runParams} $@"
			fi
		done

		completed=1
	done
done
done
done

${setupDir}/stopInstances.sh ${platform}
