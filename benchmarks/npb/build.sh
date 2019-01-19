#!/usr/bin/env bash

install_dir=$1
target=${2:-"suite"}

build_dir=${install_dir}
bin_dir=/nfs/bin/npb

make --directory ${build_dir} ${target}

mkdir -p ${bin_dir}
rm -f ${bin_dir}/*
rm -f ${build_dir}/bin/*

cp ${build_dir}/bin/* ${bin_dir}/
