#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
RUN=${REPO}/benchmarks

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
--skip_pingpong)
	skip_pingpong=1
	shift
	;;
--skip_iperf)
	skip_iperf=1
	shift
	;;
--skip_intel)
	skip_intel=1
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
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
gcp.vm.multi-az)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.metal.cluster)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes} $@
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vm.cluster)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes} $@
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vmc5.cluster)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_sizes.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} --maxBytes ${pingpongMaxBytes} $@
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.metal.spread)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vm.spread)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vmc5.spread)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.metal.multi-az)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vm.multi-az)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vmc5.multi-az)
	[ -z "${skip_pingpong}" ] && ${RUN}/pingpong/run_cross.sh --resultName ${expType} --resultDir ${resultDir} ${pingpongDuration} $@
	[ -z "${skip_iperf}" ]    && ${RUN}/iperf/run_cross.sh --resultName ${expType} --resultDir ${resultDir} --seconds ${iperfSeconds} $@
	[ -z "${skip_intel}" ]    && ${RUN}/intel/run.sh ${expType} --resultName ${expType} --resultDir ${resultDir} $@
	;;
*) # unknown
	echo "Unknown experiment type '${expType}'."
	exit
	;;
esac
