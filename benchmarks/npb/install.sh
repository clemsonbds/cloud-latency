#!/usr/bin/env bash

install_dir=${1:-"$HOME/npb"}

package=NPB3.3.1
tarfile=${package}.tar.gz
extract_dir=${package}
config_dir=$(dirname "$(realpath "${BASH_SOURCE[0]}")") # use this script's directory for the make.def and suite.def files

wget https://www.nas.nasa.gov/assets/npb/${tarfile}
[ ! -f "${tarfile}" ] && exit

tar -xzf ${tarfile} # extracts to the basename of the tar file, ${lammps}
[ ! -d "${extract_dir}" ] && exit

rm -rf ${install_dir}
mv ${extract_dir}/NPB3.3-MPI ${install_dir}

# symlink the make and suite definitions in this repo into the build directory
ln -s ${config_dir}/make.def ${install_dir}/config/make.def # compile environment
ln -s ${config_dir}/suite.def ${install_dir}/config/suite.def # which tests to build

# clean up
rm -rf ${extract_dir}
rm -f ${tarfile}
