#!/usr/bin/env bash

install_dir=${1:-"$HOME/pingpong"}
target=${2:-"all"}

build_dir=${install_dir}
bin_dir=/nfs/bin/pingpong
exec_file=pingpong
new_exec_file=pingpong # standardized for the run script

make --directory ${build_dir} ${target}

mkdir -p ${bin_dir}
cp ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}
