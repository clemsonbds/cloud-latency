#!/bin/bash

hosts=$1
classifier=$2

if [ -z "${hosts}" ]; then
	echo "usage: $0 <hosts> [classifier]"
	exit
fi

# name the output file
nodeClasses="none"

if [ ! -z "${nodeClassifier}" ]; then
    for host in `echo ${hosts} | tr ',' ' '`; do
        nodeClasses+=','`ssh -q ${host} ${nodeClassifier} | tail -1`
    done

    nodeClasses=`echo ${nodeClasses} | cut -c 2-` # trim leading comma
fi

echo ${nodeClasses}
