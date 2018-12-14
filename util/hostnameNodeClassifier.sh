#!/bin/bash

hosts=$1

if [ -z "${hosts}" ]; then
	echo "none"
	exit
fi

# format as 0-0-0-0,1-1-1-1,etc
echo ${hosts} | tr '.' '-'
