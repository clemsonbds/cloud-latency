#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
benchDir=${DIR}/..

resultDir=/nfs/results/micro
pingpongIters=10000
pingpongSeconds=
iperfSeconds=10
allreduceIters=5
pingpongMaxBytes=65536

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
gcp.vm.single-az)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
gcp.vm.multi-az)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.metal.cluster)
	${benchDir}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes}
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.vm.cluster)
	${benchDir}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes}
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.vmc5.cluster)
	${benchDir}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes}
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.metal.spread)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.vm.spread)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.vmc5.spread)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.metal.multi-az)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.vm.multi-az)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
aws.vmc5.multi-az)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir}
	;;
*) # unknown
	echo "Unknown experiment type '${expType}'."
	exit
	;;
esac
