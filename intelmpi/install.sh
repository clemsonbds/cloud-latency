#!/bin/bash

installDir=${1:-"./intelmpi"}

git clone https://github.com/intel/mpi-benchmarks.git ${installDir}

# replace with custom Makefile for non-Intel compiler, super fragile
cp /nfs/resources/Makefile.intelmpi ${installDir}/src_cpp/Makefile
