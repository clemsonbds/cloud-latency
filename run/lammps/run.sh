#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

resultDir=.
resultName=none
hostfile="/nfs/mpi.hosts"
groupClass=none
nodeClasses=none

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
--resultDir)
    resultDir="$2"
    shift # past argument
    shift # past value
    ;;
--resultName)
    resultName="$2"
    shift # past argument
    shift # past value
    ;;
--hostfilter)
    hostfilter="$2"
    shift
    shift
    ;;
--hostfile)
    hostfile="$2"
    shift
    shift
    ;;
--rankfile)
    rankfile="$2"
    shift
    shift
    ;;
--nhosts)
    nhosts="$2"
    shift
    shift
    ;;
--nodeClassifier)
    nodeClassifier="$2"
    shift
    shift
    ;;
--groupClass)
    groupClass="$2"
    shift
    shift
    ;;
--dryrun)
    dryrun="T"
    shift
    ;;
--trash)
    trash="T"
    shift
    ;;
*)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


[ -z "${hostfilter}" ] && hostfilter=`${UTIL}/hostfileToHosts.sh ${hostfile} ${nhosts}`

# MPI run parameters
mpiParams+=" -np 128"
mpiParams+=" --hostfile ${hostfile}"
mpiParams+=" --host ${hostfilter}" # filter the hostfile
mpiParams+=" --map-by node"
mpiParams+=" --mca plm_rsh_no_tree_spawn 1"
[ ! -z "${rankfile}" ] && mpiParams+=" --rankfile ${rankfile}"

executable="/nfs/bin/lammps/lmp_mpi"
benchArgs="-in /nfs/repos/benchmarks/lammps/micelle/in.micelle $@"

[ ! -z "${nodeClassifier}" ] && nodeClasses=`${UTIL}/classifyNodes.sh ${hostfilter} ${nodeClassifier}`
timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/lammps.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"

echo Running LAMMPS benchmark.
command="mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}"

if [ -z "$dryrun" ]; then
    curDir=`pwd`
    cd /nfs/repos/benchmarks/lammps/micelle/
    eval ${command}

    # throw away?
    [ -z "$trash" ] || rm -f ${outFile}

    cd ${curDir}
else
    echo ${command}
fi

echo ""