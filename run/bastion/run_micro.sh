#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
benchDir=${DIR}/..

resultDir=/nfs/results/micro
pingpongIters=10000
iperfSeconds=60
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

case $expType in
cluster-metal)
	${benchDir}/pingpong/run.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	${benchDir}/iperf/run.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} allreduce
	;;
cluster-vm)
	${benchDir}/pingpong/run.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	${benchDir}/iperf/run.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} allreduce
	;;
spread-metal)
	${benchDir}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters} --maxBytes ${pingpongMaxBytes}
	${benchDir}/pingpong/run.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	${benchDir}/iperf/run.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} allreduce
	;;
spread-vm)
	${benchDir}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters} --maxBytes ${pingpongMaxBytes}
	${benchDir}/pingpong/run.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	${benchDir}/iperf/run.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} allreduce
	;;
multi-az-metal)
	${benchDir}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	${benchDir}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/pingpong/run.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	${benchDir}/iperf/run.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} allreduce
	;;
multi-az-vm)
	${benchDir}/pingpong/run.sh --resultName ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	${benchDir}/iperf/run.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds}
	${benchDir}/intel/run.sh ${expType} allreduce
	;;
*) # unknown
	echo "Unknown experiment type '${expType}'."
	exit
	;;
esac
