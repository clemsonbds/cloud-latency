#!/usr/bin/env bash

install_dir=$1

package=NPB3.3.1
tarfile=${package}.tar.gz
extract_dir=${package}/NPB3.3-MPI
config_dir="$(dirname "${BASH_SOURCE[0]}")" # use this script's directory for the make.def and suite.def files

wget https://www.nas.nasa.gov/assets/npb/${tarfile}
[ ! -f "${tarfile}" ] && exit

tar -xzf ${tarfile} # extracts to the basename of the tar file, ${lammps}
[ ! -d "${extract_dir}" ] && exit

# copy over the old installation, but don't wipe out a link to the directory with mv
rm -rf ${install_dir}/*
cp -R ${extract_dir}/* ${install_dir}/

# symlink the make and suite definitions in this repo into the build directory
ln -s ${config_dir}/make.def ${install_dir}/config/make.def # compile environment
ln -s ${config_dir}/suite.def ${install_dir}/config/suite.def # which tests to build
