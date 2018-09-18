#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# just a set of shortcuts to start an experiment

profile=${1:-"default"}

shift
extraArgs=$*

case $profile in 
gcp-single-az-vm)
	platform="gcp"
	expType="single-az"
	instanceType="???"
	numInstances="2"
	azs="a"
	;;
gcp-multi-az-vm)
	platform="gcp"
	expType="single-az"
	instanceType="???"
	numInstances="2"
	azs="a,b,c"
	;;
aws-cluster-metal)
	platform="aws"
	expType="single-az"
	placementGroup="cluster"
	instanceType="i3.metal"
	azs="a"
	numInstances="7"
	;;
aws-cluster-vm)
	platform="aws"
	expType="single-az"
	placementGroup="cluster"
	instanceType="i3.16xlarge"
	azs="a"
	numInstances="7"
	;;
aws-spread-metal)
	platform="aws"
	expType="single-az"
	placementGroup="spread"
	instanceType="i3.metal"
	azs="a"
	numInstances="7"
	;;
aws-spread-vm)
	platform="aws"
	expType="single-az"
	placementGroup="spread"
	instanceType="i3.16xlarge"
	azs="a"
	numInstances="7"
	;;
aws-multi-az-metal)
	platform="aws"
	expType="multi-az"
	instanceType="i3.metal"
	azs="a,b,d,e,f"
	numInstances="5"
	;;
aws-multi-az-vm)
	platform="aws"
	expType="multi-az"
	instanceType="i3.16xlarge"
	azs="a,b,d,e,f"
	numInstances="5"
	;;
*)
	echo "Unknown experiment profile '${profile}'."
	exit
	;;
esac

#instanceType="c4.large"

expName=`${utilDir}/getSetting.sh expName ${platform}`
region=`${utilDir}/getSetting.sh region ${platform}`
options="--create --name ${expName} --cloudProvider ${platform}  --region ${region} --keyName CloudLatencyExpInstance --azs ${azs} --experimentType ${expType}"

# platform-specific options
if [ "${platform}" == "aws" ]; then
	if [ ! -z "${placementGroup}" ]; then
		options+=" --placementGroup ${placementGroup}"
	fi
fi

if [ "${platform}" == "gcp" ]; then
	projectID=`${utilDir}/getSetting.sh gcpProjectID`
	options+=" --projectId ${projectID}"
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
