#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
settingsFile=${DIR}/../assets/settings.ini

if [ -z "$1" ]; then
	echo "usage: $0 <key> [platform]"
	exit
fi

key=$1
platform=$2
comment=";"

# find platform-specific key first, might override general setting
if [ ! -z "${platform}" ]; then
	pair=`grep -i ${platform}-${key} ${settingsFile} | grep -v "^[[:space:]]*${comment}"`
fi

# if not found, try the general key
if [ -z "${pair}" ]; then
	pair=`grep -i ${key} ${settingsFile} | grep -v "^[[:space:]]*${comment}"`
fi

# if we found more than one, return the first
echo "${pair}" | head -n1 | cut -d'=' -f2
