#!/bin/bash

resultName=none
hostfile="/nfs/instances"
cpuIdFile="/nfs/getCpuIdentity.sh"
maxBytes=1024

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
--maxBytes)
	maxBytes="$2"
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

currentBytes=1

src=`sed -n 1p ${hostfile}`
dst=`sed -n 2p ${hostfile}`
srcNodeClass=`ssh -q ${src} ${cpuIdFile} | tail -1`
dstNodeClass=`ssh -q ${dst} ${cpuIdFile} | tail -1`

while [ "${currentBytes}" -le "${maxBytes}" ]; do
	${DIR}/run.sh --resultName "byte-${currentBytes}.{resultName}.${srcNodeClass}.${dstNodeClass}" --msgBytes "${currentBytes}" $@
	currentBytes=$((currentBytes * 2))
done
