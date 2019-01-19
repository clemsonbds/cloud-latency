#!/usr/bin/env bash

install_dir=$1

package=lammps-stable_22Aug2018
tarfile=${package}.tar.gz
extract_dir=${package}

wget https://s3.us-east-2.amazonaws.com/latencyproject/${tarfile}
[ ! -f "${tarfile}" ] && exit

tar -xzf ${tarfile} # extracts to the basename of the tar file, ${lammps}
[ ! -d "${extract_dir}" ] && exit

# copy over the old installation, but don't wipe out a link to the directory with mv
rm -rf ${install_dir}/*
cp -R ${extract_dir}/* ${install_dir}/
