#!/bin/bash

if [ -z $2 ]; then
	echo "usage: $0 <outfile> <iterations>"
	exit
fi

DIR="$(dirname "${BASH_SOURCE[0]}")"
outfile=$1
iters=$2

trim=1000

hostfile="~/hostfile"
#rankfile="/nfs/files/scripts/env/mpi_ranks_bycore"
executable="/nfs/repos/benchmarks/pingpong"
mpi_params="-np 2 --hostfile ${hostfile}" #--rankfile ${rankfile}"

mpirun ${mpi_params} ${executable} -i ${iters} -s ${trim} > ${outfile}
