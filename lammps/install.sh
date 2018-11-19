#!/usr/bin/env bash

DIR=`pwd`
BUILD_DIR=/tmp/build
LAMMPS_VER=22Aug2018
LAMMPS_PREFIX=lammps-stable_
LAMMPS_TAR=${LAMMPS_PREFIX}${LAMMPS_VER}.tar.gz
LAMMPS_DIR=LAMMPS_DIR

mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
rm -rf ${LAMMPS_DIR} # old build dir

wget https://s3.us-east-2.amazonaws.com/latencyproject/${LAMMPS_TAR}
tar -xzf ${LAMMPS_TAR}

rm -f ${LAMMPS_TAR}
mv ${LAMMPS_PREFIX}${LAMMPS_VER} ${LAMMPS_DIR}
cd ${LAMMPS_DIR}