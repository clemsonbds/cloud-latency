#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}/../../util

hostfile="/nfs/mpi.hosts"
groupClass=none
nodeClasses=none
resultDir=.
resultName=none
iters=20
skip=1000
msgBytes=1

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
--resultName)
    resultName="$2"
    shift # past argument
    shift # past value
    ;;
--iters)
    iters="$2"
    shift
    shift
    ;;
--seconds)
    seconds="$2"
    shift
    shift
    ;;
--msgBytes)
    msgBytes="$2"
    shift
    shift
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


[ -z "${hosts}" ] && hosts=`${utilDir}/hostfileToHosts.sh ${hostfile} 2`

# MPI run parameters
mpiParams+=" -np 2"
mpiParams+=" --hostfile ${hostfile}"
mpiParams+=" --host ${hosts}" # filter the hostfile
mpiParams+=" --map-by node"
[ ! -z "${rankfile}" ] && mpiParams+=" --rankfile ${rankfile}"

executable="/nfs/repos/benchmarks/pingpong/pingpong"

# executable parameters
ppArgs="-t -s ${skip} -b ${msgBytes}"

if [ -z "${seconds}" ]; then
    ppArgs+=" -i ${iters}"
else
    ppArgs+=" -d ${seconds}"
fi

# name the output file
[ ! -z "${nodeClassifier}" ] && nodeClasses=`${utilDir}/classifyNodes.sh ${hosts} ${nodeClassifier}`
timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/pingpong.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"

echo Running pingpong between ${hosts}
command="mpirun ${mpiParams} ${executable} ${ppArgs} 1> ${outFile}"

if [ -z "$dryrun" ]; then
    eval ${command}

    # throw away?
    [ -z "$trash" ] || rm -f ${outFile}
else
    echo ${command}
fi
