#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

#setupDir=${DIR}/../setup
setupDir=${DIR}/.
resultDir=/nfs/results/micro

pingpongIters=10000
iperfSeconds=60
allreduceIters=5

mkdir -p ${resultDir}

# cluster grouping, bare metal
expType=cluster-bare
${setupDir}/stopInstances.sh
${setupDir}/startInstances.sh ${expType}

pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
iperf/run.sh ${expType}
intel/run.sh ${expType} allreduce



# cluster grouping, hypervisor
expType=cluster-hv
${setupDir}/stopInstances.sh
${setupDir}/startInstances.sh ${expType}

pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
iperf/run.sh ${expType}
intel/run.sh ${expType} allreduce



# spread grouping, bare metal
expType=spread-bare
${setupDir}/stopInstances.sh
${setupDir}/startInstances.sh ${expType}

pingpong/run_sizes.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
iperf/run.sh ${expType}
intel/run.sh ${expType} allreduce



# spread grouping, hypervisor
expType=spread-hv
${setupDir}/stopInstances.sh
${setupDir}/startInstances.sh ${expType}

pingpong/run_sizes.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
iperf/run.sh ${expType}
intel/run.sh ${expType} allreduce



# multi-AZ grouping, bare metal
expType=multi-az-bare
${setupDir}/stopInstances.sh
${setupDir}/startInstances.sh ${expType}

pingpong/run_cross.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
iperf/run_cross.sh ${expType}
pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
iperf/run.sh ${expType}
intel/run.sh ${expType} allreduce



# multi-AZ grouping, hypervisor
expType=multi-az-hv
${setupDir}/stopInstances.sh
${setupDir}/startInstances.sh ${expType}

pingpong/run.sh --resultPrefix ${expType} --resultDir ${resultDir} --iters ${pingpongIters}
iperf/run.sh ${expType}
intel/run.sh ${expType} allreduce
