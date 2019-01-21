#!/usr/bin/env bash

install_dir=${1:-"$HOME/pingpong"}

rm -rf ${install_dir}
git clone https://github.com/Rakurai/mpi-pingpong.git ${install_dir}

sed -i 's|/opt/local/include|/opt/local/include -std=gnu99|' ${install_dir}/Makefile
