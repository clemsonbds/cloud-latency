#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# just a set of shortcuts to start an experiment

profile=${1:-"default"}
creds=${2:-"default"}

shift
extraArgs=$*

case $profile in
gcp.vm.single-az)
	platform="gcp"
	expType="single-az"
	instanceType="n1-highmem-64"
#	numInstances="7"
	numInstances="4"
	azs="b"
	;;
gcp.vm.multi-az)
	platform="gcp"
	expType="multi-az"
	instanceType="n1-highmem-64"
	numInstances="3"
	azs="b,c,d"
	;;
aws.metal.cluster)
	platform="aws"
	expType="single-az"
	placementGroup="cluster"
	instanceType="i3.metal"
	azs="a"
#	numInstances="7"
	numInstances="4"
	;;
aws.vm.cluster)
	platform="aws"
	expType="single-az"
	placementGroup="cluster"
	instanceType="i3.16xlarge"
	azs="a"
#	numInstances="7"
	numInstances="4"
	;;
aws.metal.spread)
	platform="aws"
	expType="single-az"
	placementGroup="spread"
	instanceType="i3.metal"
	azs="a"
#	numInstances="7"
	numInstances="4"
	;;
aws.vm.spread)
	platform="aws"
	expType="single-az"
	placementGroup="spread"
	instanceType="i3.16xlarge"
	azs="a"
#	numInstances="7"
	numInstances="4"
	;;
aws.metal.multi-az)
	platform="aws"
	expType="multi-az"
	instanceType="i3.metal"
	azs="a,b,d,e,f"
#	numInstances="5"
	numInstances="4"
	;;
aws.vm.multi-az)
	platform="aws"
	expType="multi-az"
	instanceType="i3.16xlarge"
	azs="a,b,d,e,f"
#	numInstances="5"
	numInstances="4"
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
