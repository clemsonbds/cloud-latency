#!/bin/bash

baseDir=/nfs/repos/benchmarks

rm -rf ${baseDir}

# fetch benchmark suites

# mpi pingpong
benchDir=${baseDir}/pingpong
git clone https://github.com/Rakurai/mpi-pingpong.git ${benchDir}
sed -i 's|/opt/local/include|/opt/local/include -std=gnu99|' ${benchDir}/Makefile
(cd ${benchDir} && make)

# intel MPI
benchDir=${baseDir}/intel-mpi
git clone https://github.com/intel/mpi-benchmarks.git ${benchDir}
cp ${benchDir}/src/make_mpich ${benchDir}/src/make_ompi
sed -i 's|MPI_HOME=|MPI_HOME=/usr/lib64/openmpi|' ${benchDir}/src/make_ompi
(cd ${benchDir}/src && make -f make_ompi)

# NPB
