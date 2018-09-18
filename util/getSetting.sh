#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"
settingsFile=${DIR}/../assets/settings.ini

if [ -z "$1" ]; then
	echo "usage: $0 <key> [platform]"
	exit
fi

key=$1
platform=${2:-"aws"}

# find platform-specific key first
pair=`grep -i ${platform}-${key} ${settingsFile}`

# if not found, try the general key
if [ -z "${pair}" ]; then
	pair=`grep -i ${key} ${settingsFile}`
fi

# if we found more than one, return the first
echo "${pair}" | head -n1 | cut -d'=' -f2
