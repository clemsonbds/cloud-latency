#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# just a set of shortcuts to start an experiment

profile=${1:-"default"}

shift
extraArgs=$*

case $profile in 
cluster-metal)
	expType="single-az"
	placementGroup="cluster"
#	instanceType="i3.metal"
	instanceType="i3.16xlarge"
	azs="a"
	;;
cluster-vm)
	expType="single-az"
	placementGroup="cluster"
	instanceType="i3.16xlarge"
	azs="a"
	;;
spread-metal)
	expType="single-az"
	placementGroup="spread"
#	instanceType="i3.metal"
	instanceType="i3.16xlarge"
	azs="a"
	;;
spread-vm)
	expType="single-az"
	placementGroup="spread"
	instanceType="i3.16xlarge"
	azs="a"
	;;
multi-az-metal)
	expType="multi-az"
#	instanceType="i3.metal"
	instanceType="i3.16xlarge"
	azs="a,b,d,e,f"
	numInstances="5"
	;;
multi-az-vm)
	expType="multi-az"
	instanceType="i3.16xlarge"
	azs="a,b,d,e,f"
	numInstances="5"
	;;
default)
	expType="single-az"
	azs="a"
	;;
*)
	echo "Unknown experiment profile '${profile}'."
	exit
	;;
esac

#instanceType="c4.large"
region=`${utilDir}/getSetting.sh region`
expName=`${utilDir}/getSetting.sh expName`
options="--create --name ${expName} --region ${region} --keyName CloudLatencyExpInstance --azs ${azs} --experimentType ${expType}"

if [ ! -z "${placementGroup}" ]; then
	options+=" --placementGroup ${placementGroup}"
fi

if [ ! -z "${instanceType}" ]; then
	options+=" --instanceType ${instanceType}"
fi

if [ ! -z "${numInstances}" ]; then
	options+=" --numInstances ${numInstances}"
fi

echo "Starting experiment '$profile' cloud resources."
${DIR}/launchInstances.py ${options}

${DIR}/configureInstances.sh ${profile}
