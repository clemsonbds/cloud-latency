#!/bin/bash

installDir=${1:-.}

git clone https://github.com/intel/mpi-benchmarks.git ${installDir}

# replace with custom Makefile for non-Intel compiler, super fragile
cp Makefile.mpicc ${installDir}/src_cpp/Makefile
