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

    timestamp="`date '+%Y-%m-%d_%H:%M:%S'`"

    for exec_file in ${bin_dir}/*; do
      exec=`basename ${exec_file}`
      test=`echo ${exec}|tr '.' ' '|awk '{print $1}'`
      size=`echo ${exec}|tr '.' ' '|awk '{print $2}'`
      procs=`echo ${exec}|tr '.' ' '|awk '{print $3}'`

      # special case for DT
      bench_params=
      if [ "$test" = "dt" ]; then
        procs=128
        bench_params="BH"
      fi

      out_file="${out_dir}/npb.${test}-${size}.palmetto.metal.ib.${timestamp}.raw"

      mpirun -n ${procs} ${mpi_params} ${exec_file} ${bench_params} > ${out_file}
    done
  done
#done
