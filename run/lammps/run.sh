#!/bin/bash

resultDir=.
resultName=none
hostfile="/nfs/instances"

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
*)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


mpiParams="-np 128 --map-by node --mca plm_rsh_no_tree_spawn 1"

if [[ ! -z "${hosts}" ]]; then
    mpiParams+=" --host ${hosts}"
    src=`echo ${hosts} | awk -F "," '{print $1}'`
    dst=`echo ${hosts} | awk -F "," '{print $2}'`
else
    mpiParams+=" --hostfile ${hostfile}"
    src=`head -n1 ${hostfile}`
    dst=`head -n2 ${hostfile} | tail -n1`
fi

if [[ ! -z "${rankfile}" ]]; then
    mpiParams+=" --rankfile ${rankfile}"
fi

timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/lammps.${resultName}.${timestamp}.raw"

executable="/nfs/repos/benchmarks/lammps/micelle/lmp_mpi"
benchArgs="-in /nfs/repos/benchmarks/lammps/micelle/in.micelle"

echo Running LAMMPS benchmark.
curDir=`pwd`
cd /nfs/repos/benchmarks/lammps/micelle/
mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}
cd ${curDir}