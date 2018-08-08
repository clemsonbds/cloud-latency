#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

resultDir=/nfs/results/micro
expType=

pingpongIters=10000
iperfSeconds=60
allreduceIters=5

mkdir -p ${resultDir}

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

if [ -z "${expType}"]; then
	echo "usage: $0 <experiment type>"
	exit
fi

cd ..

case $expType in
cluster-bare)
	pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	iperf/run.sh ${expType}
	intel/run.sh ${expType} allreduce
	;;
cluster-hv)
	pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	iperf/run.sh ${expType}
	intel/run.sh ${expType} allreduce
	;;
spread-bare)
	pingpong/run_sizes.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	iperf/run.sh ${expType}
	intel/run.sh ${expType} allreduce
	;;
spread-hv)
	pingpong/run_sizes.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	iperf/run.sh ${expType}
	intel/run.sh ${expType} allreduce
	;;
multi-az-bare)
	pingpong/run_cross.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	iperf/run_cross.sh ${expType}
	pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	iperf/run.sh ${expType}
	intel/run.sh ${expType} allreduce
	;;
multi-az-hv)
	pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
	iperf/run.sh ${expType}
	intel/run.sh ${expType} allreduce
	;;
*) # unknown
	echo "Unknown experiment type '${expType}'."
	exit
	;;
esac
