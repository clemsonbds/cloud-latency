#!/bin/bash

baseDir=/nfs/repos/project
utilDir=${baseDir}/util

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


[ -z "${hosts}" ] && hosts=`${utilDir}/hostfileToHosts.sh ${hostfile}`
nhosts=`echo ${hosts} | awk -F, '{ print NF; exit }'`

# MPI run parameters
mpiParams+=" -np ${nhosts}"
mpiParams+=" --hostfile ${hostfile}"
mpiParams+=" --host ${hosts}" # filter the hostfile
mpiParams+=" --map-by node"
mpiParams+=" --mca plm_rsh_no_tree_spawn 1"
[ ! -z "${rankfile}" ] && mpiParams+=" --rankfile ${rankfile}"

executable="/nfs/repos/benchmarks/intelmpi/IMB-MPI1"
benchArgs=

[ ! -z "${nodeClassifier}" ] && nodeClasses=`${utilDir}/classifyNodes.sh ${hosts} ${nodeClassifier}`
timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/impi.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"

echo Running Intel-MPI benchmark.
command="mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}"

if [ -z "$dryrun" ]; then
    eval ${command}

    # throw away?
    [ -z "$trash" ] || rm -f ${outFile}
else
    echo ${command}
fi

echo ""
