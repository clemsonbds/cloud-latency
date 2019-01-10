#!/bin/bash

baseDir=/nfs/repos/project
utilDir=${baseDir}/util
benchDir=${baseDir}/run

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
	${benchDir}/pingpong/run.sh --resultName "byte-${currentBytes}.${resultName}.${nodeClass}.${groupClass}" --msgBytes "${currentBytes}" $@
	currentBytes=$((currentBytes * 2))
done

echo ""
