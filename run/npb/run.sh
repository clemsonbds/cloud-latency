#!/bin/bash

resultDir=.
resultName=none
hostfile="/nfs/instances"

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
--rankfile)
    rankfile="$2"
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


mpiParams="--map-by node"

if [ ! -z "${hosts}" ]; then
    mpiParams+=" --host ${hosts}"
    src=`echo ${hosts} | awk -F "," '{print $1}'`
    dst=`echo ${hosts} | awk -F "," '{print $2}'`
else
    mpiParams+=" --hostfile ${hostfile}"
    src=`head -n1 ${hostfile}`
    dst=`head -n2 ${hostfile} | tail -n1`
fi

if [ ! -z "${rankfile}"]; then
    mpiParams+=" --rankfile ${rankfile}"
fi

timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"

echo Running NPB benchmark.
mpirun ${mpiParams} ${executable} ${benchArgs} 1> ${outFile}

#hostfile="/nfs/files/scripts/env/mpi_hosts"
#rankfile="/nfs/files/scripts/env/mpi_ranks_bynode" # fill each node in order, change rankfile to distribute
#mpi_params="--mca btl ^tcp --rankfile ${rankfile}"
out_params="2>/dev/null"

BIN_DIR=/nfs/npb_bin

for exec in ${BIN_DIR}/*; do
    test=`echo $exec|tr '.' ' '|awk '{print $1}'`
    size=`echo $exec|tr '.' ' '|awk '{print $2}'`
    procs=`echo $exec|tr '.' ' '|awk '{print $3}'`

    echo $test $size $procs

#    outfile=${outpath}.${exec}.raw
    outFile="${resultDir}/npb.${test}.${resultName}.${timestamp}.raw"
    touch ${outfile} # avoid 'file not found'

#    while [ `grep "Time in seconds" ${outfile} | wc -l` -lt ${iters} ]; do
    # for iter in `seq 1 ${iters}`; do
        timeout 60 mpirun --np ${procs} ${mpi_params} ${BIN_DIR}/${exec} ${out_params} >> ${outfile}
#    done
done
