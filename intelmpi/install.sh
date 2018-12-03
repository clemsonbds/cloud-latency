#!/bin/bash

benchDir=impi
git clone https://github.com/intel/mpi-benchmarks.git ${benchDir}

# replace with custom Makefile for non-Intel compiler, super fragile
cp Makefile.mpicc ${benchDir}/src_cpp
