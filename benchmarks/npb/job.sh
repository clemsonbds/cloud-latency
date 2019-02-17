#!/bin/bash
#PBS -N mpi-lat
#PBS -l select=4:chip_type=6148g:ncpus=32:mem=256gb:mpiprocs=128,walltime=03:00:00


bin_dir=$HOME/npb_bin
out_dir=$HOME/npb_out
iterations=30

mpi_params="--map-by node --mca btl openib,self,sm"

mkdir -p $out_dir

module load gcc/8.2.0 openmpi/2.1.1

$HOME/cloud-latency/npb/build.sh

#for interface in ib eth; do
  for x in `seq 1 ${iterations}`; do

    $HOME/cloud-latency/benchmarks/npb/run.sh --resultName palmetto --infiniband --binDir ${bin_dir} --resultDir ${out_dir}
  done
#done
