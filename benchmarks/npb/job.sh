#!/bin/bash
#PBS -N mpi-lat
#PBS -l select=4:chip_type=6148g:ncpus=32:mem=256gb:mpiprocs=128,walltime=03:00:00

GCC_VER=8.2.0
OMP_VER=2.1.1

bin_dir=$HOME/npb_bin
out_dir=$HOME/npb_out
iterations=30

mkdir -p $out_dir

module load gcc/${GCC_VER} openmpi/${OMP_VER}

$HOME/cloud-latency/benchmarks/npb/build.sh

for network in eth mlx; do
  module rm openmpi/${OMP_VER}-eth
  module rm openmpi/${OMP_VER}-mlx
  module load openmpi/${OMP_VER}-${network}

  #NPB
  for x in `seq 1 ${iterations}`; do
    $HOME/cloud-latency/benchmarks/npb/run.sh --resultName palmetto-${network} --binDir ${bin_dir} --resultDir ${out_dir}
  done
done
