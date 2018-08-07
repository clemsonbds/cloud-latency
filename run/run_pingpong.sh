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
out_params="2>/dev/null | tail -n ${iters}"

mpirun ${mpi_params} ${executable} $((iters + trim)) ${out_params} > ${outfile}
