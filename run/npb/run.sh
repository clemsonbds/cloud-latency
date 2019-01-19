#!/bin/bash

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

resultDir=.
resultName=none
hostfile="/nfs/mpi.hosts"
groupClass=none
nodeClasses=none

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
--rankfile)
    rankfile="$2"
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
--ep_only)
    ep_only="T"
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

# MPI run parameters
mpiParams+=" --hostfile ${hostfile}"
mpiParams+=" --host ${hostfilter}" # filter the hostfile
mpiParams+=" --map-by node"
mpiParams+=" --mca plm_rsh_no_tree_spawn 1"
[ ! -z "${rankfile}" ] && mpiParams+=" --rankfile ${rankfile}"

# output file name pieces
[ ! -z "${nodeClassifier}" ] && nodeClasses=`${UTIL}/classifyNodes.sh ${hostfilter} ${nodeClassifier}`
timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"

echo Running NPB benchmark.
#mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}

#hostfile="/nfs/files/scripts/env/mpi_hosts"
#rankfile="/nfs/files/scripts/env/mpi_ranks_bynode" # fill each node in order, change rankfile to distribute
#mpi_params="--mca btl ^tcp --rankfile ${rankfile}"
outParams="2>/dev/null"

BIN_DIR=/nfs/bin/npb

for exec in ${BIN_DIR}/*; do
    exec=`basename $exec`
    test=`echo $exec|tr '.' ' '|awk '{print $1}'`
    size=`echo $exec|tr '.' ' '|awk '{print $2}'`
    procs=`echo $exec|tr '.' ' '|awk '{print $3}'`

    if [ "$test" != "ep" ] && [ ! -z "${ep_only}" ]; then
        continue
    fi

    # special case for DT
    if [ "$test" == "dt" ]; then
        procs=128
        benchParams="BH"
    fi

    echo Running test $test, size = $size, NP = $procs

    outFile="${resultDir}/npb-${test}-${size}.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"
#    touch ${outFile} # avoid 'file not found'

#    while [ `grep "Time in seconds" ${outfile} | wc -l` -lt ${iters} ]; do
    # for iter in `seq 1 ${iters}`; do
#        echo "mpirun --np ${procs} ${mpiParams} ${BIN_DIR}/${exec} ${benchParams} > ${outFile}"
    command="timeout 300 mpirun --np ${procs} ${mpiParams} ${BIN_DIR}/${exec} ${benchParams} > ${outFile}"

    if [ -z "$dryrun" ]; then
        eval ${command}

        # throw away?
        [ -z "$trash" ] || rm -f ${outFile}
    else
        echo ${command}
    fi
done

echo ""
