#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# just a set of shortcuts to start an experiment

profile=${1:-"default"}
creds=${2:-"default"}

shift
extraArgs=$*

case $profile in
gcp-single-az-vm)
	platform="gcp"
	expType="single-az"
	instanceType="n1-highmem-64"
	numInstances="7"
	azs="b"
	;;
gcp-multi-az-vm)
	platform="gcp"
	expType="multi-az"
	instanceType="n1-highmem-64"
	numInstances="3"
	azs="b,c,d"
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

expName=`${utilDir}/getSetting.sh expName ${platform} | awk '{print tolower($0)}'`
region=`${utilDir}/getSetting.sh region ${platform}`
keyName=`${utilDir}/getSetting.sh instanceKeyPair ${platform}`

options="--create --name ${expName} --cloudProvider ${platform}  --region ${region} --keyName ${keyName} --azs ${azs} --experimentType ${expType} --profile ${creds}"

# platform-specific options
if [ "${platform}" == "aws" ]; then
	if [ ! -z "${placementGroup}" ]; then
		options+=" --placementGroup ${placementGroup}"
	fi
fi

if [ "${platform}" == "gcp" ]; then
	projectID=`${utilDir}/getSetting.sh projectID ${platform}`
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

${DIR}/configureInstances.sh ${platform}
