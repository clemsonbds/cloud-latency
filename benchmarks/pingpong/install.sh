#!/usr/bin/env bash

install_dir=$1

git clone https://github.com/Rakurai/mpi-pingpong.git ${install_dir}

sed -i 's|/opt/local/include|/opt/local/include -std=gnu99|' ${benchDir}/Makefile
