#!/usr/bin/env bash

install_dir=${1:-"$HOME/lammps"}

package=lammps-stable_22Aug2018
tarfile=${package}.tar.gz
extract_dir=${package}

wget https://s3.us-east-2.amazonaws.com/latencyproject/${tarfile}
[ ! -f "${tarfile}" ] && exit

tar -xzf ${tarfile} # extracts to the basename of the tar file, ${lammps}
[ ! -d "${extract_dir}" ] && exit

rm -rf ${install_dir}
mv ${extract_dir} ${install_dir}

# clean up
rm -f ${tarfile}
