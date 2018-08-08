#!/bin/bash

resultPrefix=none
hostfile="/nfs/instances"

DIR="$(dirname "${BASH_SOURCE[0]}")"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
--resultPrefix)
    resultPrefix="$2"
    shift # past argument
    shift # past value
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

letters="abcdefghijklmnopqrstuvwxyz"

srcIndex=0
for src in `cat ${hostfile}`; do

    dstIndex=0
    for dst in `cat ${hostfile}`; do
        if [ "${dstIndex}" -gt "${srcIndex}" ]; then
            srcLetter=${letters:srcIndex:1}
            dstLetter=${letters:dstIndex:1}
            ${DIR}/run.sh --resultPrefix "${resultPrefix}-${srcLetter}-${dstLetter}" --hosts "${src},${dst}" $@
        fi

        dstIndex=$((dstIndex+1))
    done

    srcIndex=$((srcIndex+1))
done
