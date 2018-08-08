#!/bin/bash

resultDir=.
resultPrefix=none
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
--resultPrefix)
    resultPrefix="$2"
    shift # past argument
    shift # past value
    ;;
--iters)
    iters="$2"
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
mpiParams="-np 2"
skip=1000

if [ ! -z "${hosts}" ]; then
    mpiParams+=" --hosts ${hosts}"
else
    mpiParams+=" --hostfile ${hostfile}"
fi

if [ ! -z "${rankfile}"]; then
    mpiParams+=" --rankfile ${rankfile}"
fi

outFile="${resultDir}/${resultPrefix}-pingpong.raw"

echo ${outFile}
#mpirun ${mpiParams} ${executable} -i ${iters} -s ${skip} -b ${msgBytes} > ${outFile}
