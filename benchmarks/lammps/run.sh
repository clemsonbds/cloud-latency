#!/bin/bash

REPO=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util

resultName=none
hostfile="/nfs/mpi.hosts"
groupClass=none
nodeClasses=none

bin_dir=/nfs/bin/lammps
input_dir=/nfs/bin/lammps/data

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
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


[ -z "${hostfilter}" ] && hostfilter=`${UTIL}/hostfileToHosts.sh ${hostfile} ${nhosts}`
[ -z "${nhosts}" ] && nhosts=`echo ${hostfilter} | awk -F, '{ print NF; exit }'`

# get the smallest host in the first n hosts
nprocs_per_host=`grep "slots=" ${hostfile} | head -n ${nhosts} | sed 's/.*slots[\s]*=[\s]*\([0-9]\+\).*/\1/' | sort -n | head -n 1`
nprocs=$((nprocs_per_host * nhosts))

# MPI run parameters
mpiParams+=" -np ${nprocs}"
mpiParams+=" --hostfile ${hostfile}"
mpiParams+=" --host ${hostfilter}" # filter the hostfile
mpiParams+=" --mca plm_rsh_no_tree_spawn 1"
[ ! -z "${rankfile}" ] && mpiParams+=" --rankfile ${rankfile}"

executable="/nfs/bin/lammps/lmp_mpi"
benchArgs="-in /nfs/repos/benchmarks/lammps/micelle/in.micelle $@"

if [ ! -z "${resultDir}" ]; then
    [ ! -z "${nodeClassifier}" ] && nodeClasses=`${UTIL}/classifyNodes.sh ${hostfilter} ${nodeClassifier}`
    timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"
fi

for input in ${input_dir}/in.*; do
    infile=`basename $input`
    bench=`echo $infile|cut -d. -f2-|tr '.' '-'` # strips the 'in.'
    exec="lmp."`echo $bench|cut -d- -f1` # strips the '-scaled' if it exists, append to 'lmp.'
    triplet=`${UTIL}/minTriplet.py ${nprocs}`
    dim_x="-var x "`echo ${triplet}|cut -d, -f1`
    dim_y="-var y "`echo ${triplet}|cut -d, -f2`
    dim_z="-var z "`echo ${triplet}|cut -d, -f3`
#    dim_x="-var x 8" #${nprocs_per_host}"
#    dim_y="-var y 4" #${nhosts}"
#    dim_z="-var z 4"

    bench_params="-in ${infile} ${dim_x} ${dim_y} ${dim_z}"

    echo Running LAMMPS benchmark ${bench} using executable ${exec} and parameters ${bench_params}

    if [ ! -z "${resultDir}" ]; then
        outFile="${resultDir}/lammps-${bench}.${resultName}.${nodeClasses}.${groupClass}.${timestamp}.raw"
        output="2> /dev/null 1> ${outFile}"
    fi

    command="mpirun ${mpiParams} ${bin_dir}/${exec} ${bench_params} ${output}"

    if [ -z "$dryrun" ]; then
        (cd ${input_dir} && eval ${command})

        # throw away?
        [ -z "$trash" ] || rm -f ${outFile}
    else
        echo ${command}
    fi
done

echo ""
