#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util
RUN=${REPO}/benchmarks

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
[ -z "${nhosts}" ] && nhosts=`echo ${hostfilter} | awk -F, '{ print NF; exit }'`

# MPI run parameters
mpiParams+=" -np ${nhosts}"
mpiParams+=" --hostfile ${hostfile}"
mpiParams+=" --host ${hostfilter}" # filter the hostfile
mpiParams+=" --map-by node" # distribute one process to each node
mpiParams+=" --mca plm_rsh_no_tree_spawn 1"
[ ! -z "${rankfile}" ] && mpiParams+=" --rankfile ${rankfile}"

executable="/nfs/bin/intelmpi/IMB"
benchArgs="$@"

if [ ! -z "${resultDir}" ]; then
    [ ! -z "${nodeClassifier}" ] && nodeClasses=`${UTIL}/classifyNodes.sh ${hostfilter} ${nodeClassifier}`
    timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
    outFile="${resultDir}/impi.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"
    output="1> ${outFile}"
fi

echo Running Intel-MPI benchmark.
command="mpirun ${mpiParams} ${executable} ${benchArgs} ${output}"

if [ -z "$dryrun" ]; then
    eval ${command}

    # throw away?
    [ -z "$trash" ] || rm -f ${outFile}
else
    echo ${command}
fi

echo ""
