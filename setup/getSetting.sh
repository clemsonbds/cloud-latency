#!/bin/bash

if [ -z "$1" ]; then
	echo "usage: $0 <key>"
	exit
fi

key=$1

grep ${key} settings.txt | cut -d'=' -f2
