#!/bin/bash

resultName=none
hostfile="/nfs/mpi.hosts"

DIR="$(dirname "${BASH_SOURCE[0]}")"

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
*)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

[ -z "${hosts}" ] && hosts=`${utilDir}/hostfileToHosts.sh ${hostfile}`

echo Running iperf cross measurement between hosts ${hosts}

srcIndex=0
for src in `echo ${hosts} | tr ',' ' '`; do

    dstIndex=0
    for dst in `echo ${hosts} | tr ',' ' '`; do
        if [ "${dstIndex}" -gt "${srcIndex}" ]; then
            ${DIR}/run.sh --resultName "cross.${resultName}" --hosts "${src},${dst}" $@
        fi

        dstIndex=$((dstIndex+1))
    done

    srcIndex=$((srcIndex+1))
done

echo ""
