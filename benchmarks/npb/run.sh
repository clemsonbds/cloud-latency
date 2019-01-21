#!/bin/bash

if [ -z $2 ]; then
	echo "usage: $0 <outfile prefix> <iterations>"
	exit
fi

BIN_DIR=/nfs/npb_bin
DIR="$(dirname "${BASH_SOURCE[0]}")"
outpath=$1
iters=$2

hostfile="/nfs/instances"
#rankfile="/nfs/files/scripts/env/mpi_ranks_bynode" # fill each node in order, change rankfile to distribute
#mpi_params="--mca btl ^tcp --rankfile ${rankfile}"
mpi_params="--hostfile ${hostfile} --rank-by node --mca plm_rsh_no_tree_spawn 1"
#out_params="2>/dev/null"

#execs=`ls ${BIN_DIR}`

for exec in ${BIN_DIR}/*; do
 exn=`basename $exec`
 test=`echo $exn|tr '.' ' '|awk '{print $1}'`
 size=`echo $exn|tr '.' ' '|awk '{print $2}'`
 procs=`echo $exn|tr '.' ' '|awk '{print $3}'`

 echo $test $size $procs

 outfile=${outpath}/${exn}.raw
# rm -f ${outfile}
 touch ${outfile} # avoid 'file not found'

 while [ `grep "Time in seconds" ${outfile} | wc -l` -lt ${iters} ]; do
# for iter in `seq 1 ${iters}`; do
  mpirun --np ${procs} ${mpi_params} ${exec} ${out_params} >> ${outfile}
 done
done