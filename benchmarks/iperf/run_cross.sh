#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util
RUN=${REPO}/run

resultName=none
hostfile="/nfs/mpi.hosts"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
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
*)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

[ -z "${hostfilter}" ] && hostfilter=`${UTIL}/hostfileToHosts.sh ${hostfile}`

echo Running iperf cross measurement between hosts ${hostfilter}

srcIndex=0
for src in `echo ${hostfilter} | tr ',' ' '`; do

    dstIndex=0
    for dst in `echo ${hostfilter} | tr ',' ' '`; do
        if [ "${dstIndex}" -gt "${srcIndex}" ]; then
            ${RUN}/iperf/run.sh --resultName "cross.${resultName}" --hostfilter "${src},${dst}" "$@"
        fi

        dstIndex=$((dstIndex+1))
    done

    srcIndex=$((srcIndex+1))
done

echo ""
