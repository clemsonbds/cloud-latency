#!/usr/bin/env bash
INSTALL_DIR=/nfs/repos/benchmarks/lammps
BUILD_DIR=/tmp/build
LAMMPS_DIR=LAMMPS_DIR

cd ${BUILD_DIR}/${LAMMPS_DIR}/src
make yes-molecule
make mpi

mkdir -p ${INSTALL_DIR}
rm -f ${INSTALL_DIR}/*

cp lmp_mpi ../examples/micelle
cp -R ../examples/micelle ${INSTALL_DIR}