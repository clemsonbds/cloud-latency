#!/bin/bash

INSTALL_DIR=/nfs/npb_bin
BUILD_DIR=/tmp/build
NPB_DIR=NPB

cd ${BUILD_DIR}/${NPB_DIR}

rm -f bin/*
make suite

mkdir -p $INSTALL_DIR
rm -f $INSTALL_DIR/*
mv bin/* $INSTALL_DIR
