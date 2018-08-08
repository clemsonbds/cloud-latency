#!/bin/bash

resultPrefix=none
maxBytes=1024

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

while [ "${currentBytes}" -le "${maxBytes}" ]; do
	${DIR}/run.sh --resultPrefix "${resultPrefix}-${currentBytes}b" --msgBytes "${currentBytes}" $@
	currentBytes=$((currentBytes * 2))
done
