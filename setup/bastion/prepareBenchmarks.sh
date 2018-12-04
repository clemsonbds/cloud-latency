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
benchDir="/nfs/repos/project/intelmpi"
installDir="${baseDir}/intelmpi"
${benchDir}/install.sh ${installDir}
${benchDir}/build.sh ${installDir}

# LAMMPS
benchDir="/nfs/repos/project/lammps"
cd ${benchDir}
./install.sh
./build.sh

# NPB
benchDir="/nfs/repos/project/npb"
cd ${benchDir}
./install.sh
./build.sh
