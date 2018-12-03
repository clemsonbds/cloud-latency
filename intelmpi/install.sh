#!/bin/bash

benchDir=impi
git clone https://github.com/intel/mpi-benchmarks.git ${benchDir}

# fix up for not using intel compiler



sed -i 's|MPI_HOME=|MPI_HOME=/usr/lib64/openmpi|' ${benchDir}/src/make_ompi
