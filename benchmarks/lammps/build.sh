#!/usr/bin/env bash

install_dir=${1:-"$HOME/lammps"}
target=${2:-"mpi"}

build_dir=${install_dir}/src
bin_dir=/nfs/bin/lammps
exec_file=lmp_${target} # probably lmp_mpi, but could could be compiler or MPI specific
new_exec_file=lmp # standardized for the run script

mkdir -p ${bin_dir}

make_args="--directory ${build_dir}"

ncores=`grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}'` # number of physical cores
[ "${ncores}" -gt 1 ] && make_args+=" -j ${ncores}"

make ${make_args} no-all
#make --directory ${build_dir} clean-all

# lj
# none
make ${make_args} mpi
mv ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}.lj

# eam
make ${make_args} yes-manybody
make ${make_args} mpi
mv ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}.eam
make ${make_args} no-manybody

# chute
make ${make_args} yes-granular
make ${make_args} mpi
mv ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}.chute
make ${make_args} no-granular

# chain
make ${make_args} yes-molecule
make ${make_args} mpi
mv ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}.chain
make ${make_args} no-molecule

# rhodo
make ${make_args} yes-molecule yes-kspace yes-rigid
make ${make_args} mpi
mv ${build_dir}/${exec_file} ${bin_dir}/${new_exec_file}.rhodo
make ${make_args} no-molecule no-kspace no-rigid

# link the data/input directory on the shared filesystem
#ln -sf ${install_dir}/bench ${bin_dir}/bench # NOPE
mkdir -p ${bin_dir}/data
cp ${install_dir}/bench/* ${bin_dir}/data
