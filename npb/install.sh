#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
BUILD_DIR=/tmp/build
NPB_VER=3.3.1
NPB_PKG=NPB${NPB_VER}
NPB_TAR=${NPB_PKG}.tar.gz
NPB_DIR=NPB

mkdir -p $BUILD_DIR
cd $BUILD_DIR
rm -rf ${NPB_DIR} # old build dir
wget https://www.nas.nasa.gov/assets/npb/${NPB_TAR}
tar -xzf ${NPB_TAR}
rm -f ${NPB_TAR}
mv ${NPB_PKG}/NPB3.3-MPI ${NPB_DIR}
rm -rf ${NPB_PKG}
cd ${NPB_DIR}

ln -s /nfs/files/scripts/npb/make.def config/make.def # compile environment
ln -s /nfs/files/scripts/npb/suite.def config/suite.def # which tests to build

# now run build.sh to build and install MPI tests
