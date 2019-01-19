#!/usr/bin/env bash

install_dir=$1
target=${2:-"IMB-MPI1"}

build_dir=${install_dir}
bin_dir=/nfs/bin/intelmpi
exec_file={target}
new_exec_file=IMB # standardized for the run script

make --directory ${build_dir} ${target}

mkdir -p ${bin_dir}
cp ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}
