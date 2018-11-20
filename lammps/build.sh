#!/usr/bin/env bash
INSTALL_DIR=/nfs/repos/benchmarks/lammps
BUILD_DIR=/tmp/build
LAMMPS_DIR=LAMMPS_DIR

cd ${BUILD_DIR}/${LAMMPS_DIR}/src
make yes-molecule
make mpi

mkdir -p ${INSTALL_DIR}
rm -rf ${INSTALL_DIR}/*

cp lmp_mpi ../examples/micelle
sed -i 's|60000|200000|' ../examples/micelle/in.micelle
cp -R ../examples/micelle ${INSTALL_DIR}