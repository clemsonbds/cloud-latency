#!/bin/bash

baseDir=/nfs/repos/project
utilDir=${baseDir}/util

resultDir=.
resultName=none
seconds=10
hostfile="/nfs/mpi.hosts"
groupClass=none
nodeClasses=none
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
--seconds)
    seconds="$2"
    shift
    shift
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


[ -z "${hostfilter}" ] && hostfilter=`${utilDir}/hostfileToHosts.sh ${hostfile} 2`

executable="iperf3"

[ ! -z "${nodeClassifier}" ] && nodeClasses=`${utilDir}/classifyNodes.sh ${hostfilter} ${nodeClassifier}`
timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/iperf.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.json"

server=`echo ${hostfilter} | cut -d, -f1`
serverParams="-s -1"

client=`echo ${hostfilter} | cut -d, -f2`
clientParams="-c ${server} -t ${seconds} -J"

echo Running iperf between ${server} and ${client}.

if [ -z "$dryrun" ]; then
    ssh -q -f ${server} "sh -c 'nohup ${executable} ${serverParams} > /dev/null 2>&1 &'" # start in background and move on
    ssh -q ${client} "${executable} ${clientParams}" > ${outFile}

    # throw away?
    [ -z "$trash" ] || rm -f ${outFile}
else
    echo "fix this someday"
fi
