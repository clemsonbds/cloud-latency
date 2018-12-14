#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

platform=$1
hostfile=$2
classifier=$3
classes=$4

if [ -z "${hostfile}" ]; then
	echo "usage: $0 <aws|gcp> <hostfile> [classifier] [classes]"
	exit
fi

# name the output file
groupClass="none"

if [ ! -z "${classifier}" ]; then
	groupClass=`${DIR}/sshBastion.sh ${platform} "${classifier} ${hostfile} ${classes}"`
fi

echo ${groupClass}
