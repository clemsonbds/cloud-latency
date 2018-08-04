#!/bin/bash

# just a set of shortcuts to start an experiment

profile=${1:-"default"}
shift
extraArgs=$*

case $profile in 
default)
	expType="single-az"
	azs="a"
	;;
*)
	echo "Unknown experiment profile '${profile}'."
	exit
	;;
esac

region=`./getSetting.sh region`
expName=`./getSetting.sh expName`

./createNetworkBastionHost.py --create --name ${expName} --region ${region} --keyName JasonAnderson
./launchInstances.py --create --name ${expName} --region ${region} --keyName CloudLatencyExpInstance --azs ${azs} --experimentType ${expType}
