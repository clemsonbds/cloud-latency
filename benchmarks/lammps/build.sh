#!/usr/bin/env bash

install_dir=$1
target=${2:-"mpi"}

build_dir=${install_dir}/src
bin_dir=/nfs/bin/lammps
exec_file=lmp_${target}
new_exec_file=lmp_mpi # standardized for the run script

make --directory ${build_dir} ${target}

mkdir -p ${bin_dir}
cp ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}
