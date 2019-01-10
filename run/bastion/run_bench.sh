#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
benchDir=${DIR}/..

resultDir=/nfs/results/bench

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
"warmup"| \
"gcp.vm.single-az"|"gcp.vm.multi-az"| \
"aws.metal.cluster"|"aws.vm.cluster"|"aws.vmc5.cluster"| \
"aws.metal.spread"|"aws.vm.spread"|"aws.vmc5.spread"| \
"aws.metal.multi-az"|"aws.vm.multi-az"|"aws.vmc5.multi-az")
	expType="$1"
	shift
	;;
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
--skip_npb)
	skip_npb=1
	shift
	;;
--skip_lammps)
	skip_lammps=1
	shift
	;;
*)
	if [ -z "${expType}" ]; then
		echo "Unknown experiment type $1."
		exit
	fi

    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z "${expType}" ]; then
	echo "usage: $0 <experiment type> [kwargs]"
	exit
fi

mkdir -p ${resultDir}

if [ "${expType}" == "warmup" ]; then
	${benchDir}/npb/run.sh --ep_only --trash $@
	exit
fi

[ -z "${skip_npb}" ]    && ${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
[ -z "${skip_lammps}" ] && ${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
