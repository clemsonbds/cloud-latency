#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
settingsFile=${DIR}/../settings.ini

if [ -z "$1" ]; then
	echo "usage: $0 <key>"
	exit
fi

key=$1

grep ${key} ${settingsFile} | cut -d'=' -f2
