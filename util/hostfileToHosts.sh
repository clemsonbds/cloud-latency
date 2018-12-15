#!/bin/bash

hostfile=${1:-"/nfs/mpi.hosts"}
num=$2

#src=`sed -n 1p ${hostfile}`
#dst=`sed -n 2p ${hostfile}`

#for host in `cat ${hostfile}`; do
#    hosts+="${host},"
#done

#hosts=`echo ${hosts} | rev | cut -c 2- | rev` # trim trailing comma

hosts=`cat ${hostfile} | awk '{print $1}' | xargs | tr ' ' ','`

[ ! -z "${num}" ] && hosts=`echo ${hosts} | cut -d, -f1-${num}`

echo ${hosts}
