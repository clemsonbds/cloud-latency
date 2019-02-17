#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

resultName=none
#hostfile="/nfs/mpi.hosts"
groupClass=none
nodeClasses=none
binDir=/nfs/bin/npb

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
--binDir)
    binDir="$2"
    shift
    shift
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
--nhosts)
    nhosts="$2"
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
--infiniband)
    infiniband="T"
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

if [ ! -z "${hostfile}" ]; then
    mpiParams+=" --hostfile ${hostfile}"

    if [ -z "${hostfilter}" ]; then
        hostfilter=`${UTIL}/hostfileToHosts.sh ${hostfile} ${nhosts}`
        mpiParams+=" --host ${hostfilter}" # filter the hostfile
    fi
fi

# MPI run parameters
mpiParams+=" --map-by node" # variable number of processes, ensure even spread
[ ! -z "${infiniband}" ] && mpiParams+=" --mca btl openib,self,sm"
mpiParams+=" --mca plm_rsh_no_tree_spawn 1" # don't have slave nodes spawn more, requires more sshing
mpiParams+=" --mca mpi_cuda_support 0" # don't try to use CUDA
[ ! -z "${rankfile}" ] && mpiParams+=" --rankfile ${rankfile}"

# output file name pieces
if [ ! -z "${resultDir}" ]; then
    nodeClasses=`${UTIL}/classifyNodes.sh ${hostfilter} ${nodeClassifier}`
    timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
fi

echo Running NPB benchmark.
#mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}

#hostfile="/nfs/files/scripts/env/mpi_hosts"
#rankfile="/nfs/files/scripts/env/mpi_ranks_bynode" # fill each node in order, change rankfile to distribute
#mpi_params="--mca btl ^tcp --rankfile ${rankfile}"

for exec in ${binDir}/*; do
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

    if [ ! -z "${resultDir}" ]; then
        outFile="${resultDir}/npb-${test}-${size}.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"
        output="2> /dev/null 1> ${outFile}"
    fi

#   touch ${outFile} # avoid 'file not found'
#   while [ `grep "Time in seconds" ${outfile} | wc -l` -lt ${iters} ]; do
    command="timeout 300 mpirun --np ${procs} ${mpiParams} ${binDir}/${exec} ${benchParams} ${output}"

    if [ -z "$dryrun" ]; then
        eval ${command}

        # throw away?
        [ -z "$trash" ] || rm -f ${outFile}
    else
        echo ${command}
    fi
done

echo ""
