#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
benchDir=${DIR}/..

resultDir=/nfs/results/micro
pingpongIters=10000
pingpongSeconds=
iperfSeconds=10
allreduceIters=5
pingpongMaxBytes=8192

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
--resultDir)
    resultDir="$2"
    shift # past argument
    shift # past value
    ;;
--expType)
	expType="$2"
	shift
	shift
	;;
*)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z "${expType}" ]; then
	echo "usage: $0 <experiment type>"
	exit
fi

mkdir -p ${resultDir}

if [ -z "${pingpongSeconds}" ]; then
	pingpongDuration="--iters ${pingpongIters}"
else
	pingpongDuration="--seconds ${pingpongSeconds}"
fi

case $expType in
gcp-single-az-vm)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	;;
gcp-multi-az-vm)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	;;
aws-cluster-metal)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
#	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
#	${benchDir}/intel/run.sh ${expType} allreduce
	;;
aws-cluster-vm)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
#	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
#	${benchDir}/intel/run.sh ${expType} allreduce
	;;
aws-spread-metal)
#	${benchDir}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes}
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
#	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
#	${benchDir}/intel/run.sh ${expType} allreduce
	;;
aws-spread-vm)
#	${benchDir}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes}
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
#	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
#	${benchDir}/intel/run.sh ${expType} allreduce
	;;
aws-multi-az-metal)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
#	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
#	${benchDir}/intel/run.sh ${expType} allreduce
	;;
aws-multi-az-vm)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
#	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
#	${benchDir}/intel/run.sh ${expType} allreduce
	;;
*) # unknown
	echo "Unknown experiment type '${expType}'."
	exit
	;;
esac
