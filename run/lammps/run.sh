#!/bin/bash

utilDir=/nfs/repos/project/util

resultDir=`pwd`
resultName=none
hostfile="/nfs/instances"
groupClass=none

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
--hosts)
    hosts="$2"
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


if [ -z "${hosts}" ]; then
    hosts=`${utilDir}/hostfileToHosts.sh ${hostfile}`
fi

mpiParams="-np 128 --host ${hosts} --map-by node --mca plm_rsh_no_tree_spawn 1"

if [[ ! -z "${rankfile}" ]]; then
    mpiParams+=" --rankfile ${rankfile}"
fi

executable="/nfs/repos/benchmarks/lammps/micelle/lmp_mpi"
benchArgs="-in /nfs/repos/benchmarks/lammps/micelle/in.micelle"

nodeClasses=`${utilDir}/classifyNodes.sh ${hosts} ${nodeClassifier}`
timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/lammps.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"

echo Running LAMMPS benchmark.
curDir=`pwd`
cd /nfs/repos/benchmarks/lammps/micelle/
mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}

# throw away?
[ -z "$trash" ] || rm -f ${outFile}

cd ${curDir}
