#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util
RUN=${REPO}/benchmarks

resultName=none
maxBytes=1024

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

echo Running pingpong message sizes measurement from bytes ${currentBytes} to ${maxBytes}.

while [ "${currentBytes}" -le "${maxBytes}" ]; do
	${RUN}/pingpong/run.sh --resultName "byte-${currentBytes}.${resultName}" --msgBytes "${currentBytes}" "$@"
	currentBytes=$((currentBytes * 2))
done

echo ""
