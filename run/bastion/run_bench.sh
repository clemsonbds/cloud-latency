#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
benchDir=${DIR}/..

resultDir=/nfs/results/bench

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
gcp.vm.single-az)
	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
gcp.vm.multi-az)
	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.metal.cluster)
#	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
#	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vm.cluster)
#	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
#	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.metal.spread)
#	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
#	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vm.spread)
#	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
#	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.metal.multi-az)
#	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
#	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
aws.vm.multi-az)
#	${benchDir}/npb/run.sh --resultName ${expType} --resultDir ${resultDir} $@
#	${benchDir}/lammps/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	${benchDir}/intel/run.sh --resultName ${expType} --resultDir ${resultDir} $@
	;;
*) # unknown
	echo "Unknown experiment type '${expType}'."
	exit
	;;
esac
