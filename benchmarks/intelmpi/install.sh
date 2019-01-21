#!/usr/bin/env bash

install_dir=${1:-"$HOME/intelmpi"}

rm -rf ${install_dir}
git clone https://github.com/intel/mpi-benchmarks.git ${install_dir}

# replace with custom Makefile for non-Intel compiler, super fragile
cp /nfs/resources/Makefile.intelmpi ${install_dir}/src_cpp/Makefile
