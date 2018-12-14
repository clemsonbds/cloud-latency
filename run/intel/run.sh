#!/bin/bash

utilDir=/nfs/repos/project/util

resultDir=.
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
    hosts=`${utilDir}/hostfileToHosts.sh ${hostfile} 2`
fi

nhosts=`echo ${hosts} | awk -F, '{ print NF; exit }'`

mpiParams+="-np ${nhosts} --host ${hosts}"

if [[ ! -z "${rankfile}" ]]; then
    mpiParams+=" --rankfile ${rankfile}"
fi

mpiParams+=" --map-by node --mca plm_rsh_no_tree_spawn 1"

executable="/nfs/repos/benchmarks/intelmpi/IMB-MPI1"
benchArgs=

nodeClasses=`${utilDir}/classifyNodes.sh ${hosts} ${nodeClassifier}`
timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/impi.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"

echo Running Intel-MPI benchmark.
mpirun ${mpiParams} ${executable} ${benchArgs}  1> ${outFile}

# throw away?
[ -z "$trash" ] || rm -f ${outFile}
