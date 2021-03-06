#!/bin/bash

hosts=$1
classifier=$2

if [ ! -z "${hosts}" ] && [ ! -z "${classifier}" ]; then
    for host in `echo ${hosts} | tr ',' ' '`; do
        nodeClasses+=','`ssh -q ${host} ${classifier} | tail -1`
    done

    nodeClasses=`echo ${nodeClasses} | cut -c 2-` # trim leading comma
else
	nodeClasses="none"
fi

echo ${nodeClasses}
