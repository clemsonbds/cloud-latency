#!/bin/bash

resultDir=.
resultName=none
seconds=10
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
--seconds)
    seconds="$2"
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


if [ ! -z "${hosts}" ]; then
	server=`echo ${hosts} | tr ',' ' ' | awk '{print $1}'`
	client=`echo ${hosts} | tr ',' ' ' | awk '{print $2}'`
else
	server=`head -n 1 ${hostfile}`
	client=`head -n 2 ${hostfile} | tail -n 1`
fi

timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
outFile="${resultDir}/iperf.${resultName}.${timestamp}.json"

echo Running iperf between ${server} and ${client}.
ssh -q -f ${server} "sh -c 'nohup iperf3 -s -1 > /dev/null 2>&1 &'" # start in background and move on
ssh -q ${client} "iperf3 -c ${server} -t ${seconds} -J" > ${outFile}

# throw away?
[ -z "$trash" ] || rm -f ${outFile}
