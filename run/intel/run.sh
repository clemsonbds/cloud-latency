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


if [[ ! -z "${hosts}" ]]; then
	nhosts=`echo ${hosts} | awk -F, '{ print NF; exit }'`
    mpiParams+="-np ${nhosts} --host ${hosts}"
elif [[ ! -z "${hostfile}" ]]; then
	nhosts=`cat ${hostfile} | sed '/^\s*$/d' | wc -l`
    mpiParams+="-np ${nhosts} --hostfile ${hostfile}"
fi

if [[ ! -z "${rankfile}" ]]; then
    mpiParams+=" --rankfile ${rankfile}"
fi

mpiParams+=" --map-by node --mca plm_rsh_no_tree_spawn 1"

timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/impi.${resultName}.${timestamp}.raw"

executable="/nfs/repos/benchmarks/intelmpi/IMB-MPI1"
benchArgs=

echo Running Intel-MPI benchmark.
mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}

# throw away?
[ -z "$trash" ] || rm -f ${outFile}
