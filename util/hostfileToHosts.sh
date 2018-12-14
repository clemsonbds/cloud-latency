#!/bin/bash

hostfile=${1:-"/nfs/instances"}
num=$2

#src=`sed -n 1p ${hostfile}`
#dst=`sed -n 2p ${hostfile}`

for host in `cat ${hostfile}`; do
    hosts+="${host},"
done

hosts=`echo ${hosts} | rev | cut -c 2- | rev` # trim trailing comma

if [ ! -z "${num}" ]; then
	hosts=`echo ${hosts} | cut -d, -f1-${num}`
fi

echo ${hosts}
