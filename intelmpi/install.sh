#!/bin/bash

git clone https://github.com/intel/mpi-benchmarks.git IMB

# replace with custom Makefile for non-Intel compiler, super fragile
cp Makefile.mpicc IMB/src_cpp/Makefile
