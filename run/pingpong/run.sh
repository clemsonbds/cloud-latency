#!/bin/bash

resultDir=.
resultName=none
iters=20
hostfile="/nfs/instances"
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
*)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters


executable="/nfs/repos/benchmarks/pingpong/pingpong"
mpiParams="-np 2 --map-by node"
skip=1000

if [ ! -z "${hosts}" ]; then
    mpiParams+=" --host ${hosts}"
    src=`echo ${hosts} | awk -F "," '{print $1}'`
    dst=`echo ${hosts} | awk -F "," '{print $2}'`
else
    mpiParams+=" --hostfile ${hostfile}"
    src=`head -n1 ${hostfile}`
    dst=`head -n2 ${hostfile} | tail -n1`
fi

if [ ! -z "${rankfile}"]; then
    mpiParams+=" --rankfile ${rankfile}"
fi

timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/pingpong-${resultName}.${timestamp}.raw"

ppArgs="-t -s ${skip} -b ${msgBytes}"

if [ -z "${seconds}" ]; then
    ppArgs+=" -i ${iters}"
else
    ppArgs+=" -d ${seconds}"
fi

echo Running pingpong between ${src} and ${dst}.
mpirun ${mpiParams} ${executable} ${ppArgs} 1> ${outFile}
