#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../util

# just a set of shortcuts to start an experiment

profile=${1:-"default"}
shift
extraArgs=$*

case $profile in 
cluster-bare)
	expType="single-az"
	placementGroup="cluster"
	instanceType="i3.metal"
	azs="a"
	;;
cluster-hv)
	expType="single-az"
	placementGroup="cluster"
	instanceType="i3.16xlarge"
	azs="a"
	;;
spread-bare)
	expType="single-az"
	placementGroup="spread"
	instanceType="i3.metal"
	azs="a"
	;;
spread-hv)
	expType="single-az"
	placementGroup="spread"
	instanceType="i3.16xlarge"
	azs="a"
	;;
multi-az-bare)
	expType="multi-az"
	instanceType="i3.metal"
	azs="a,b,c,d,e,f"
	;;
multi-az-hv)
	expType="multi-az"
	instanceType="i3.16xlarge"
	azs="a,b,c,d,e,f"
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

instanceType="c4.large"

region=`${utilDir}/getSetting.sh region`
expName=`${utilDir}/getSetting.sh expName`

echo "Starting experiment '$profile' cloud resources."
${DIR}/launchInstances.py --create --name ${expName} --region ${region} --keyName CloudLatencyExpInstance --azs ${azs} --experimentType ${expType} --placementGroup ${placementGroup} --instanceType=${instanceType}

${DIR}/configureInstances.sh ${profile}
