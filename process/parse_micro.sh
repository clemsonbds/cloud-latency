#!/bin/bash

DIR="$(dirname "${BASH_SOURCE[0]}")"

resultDir=${1:-"."}
rawDir=${resultDir}/micro/raw
outDir=${resultDir}/micro/parsed

mkdir -p ${outDir}

# get configuration names from files
configNames=`echo ${rawDir}/pingpong-*-cross-*.raw | tr " " "\n" | cut -d- -f2,3,4,5 | sort | uniq`

# parse raw pingpong output to individual CSV files
for rawfile in ${rawDir}/pingpong*.raw; do
	filename=$(basename -- "$rawfile")
	filename="${filename%.*}"

	echo Parsing ${filename}.raw
	${DIR}/parse_pingpong.py -o ${outDir}/${filename}.csv ${rawfile}
done

# parse raw iperf output to individual CSV files
for rawfile in ${rawDir}/iperf*.json; do
	filename=$(basename -- "$rawfile")
	filename="${filename%.*}"

	echo Parsing ${filename}.json
	${DIR}/parse_iperf.py -o ${outDir}/${filename}.csv ${rawfile}
done

# create a CSV of measurements, one sample per column
for benchmark in pingpong iperf; do
for configName in ${configNames}; do

	# Take the 'latency' column of each CSV file, create a new CSV file with those columns.
	# Just to make it complicated, use the timestamp of each file as the column header.
	for f in ${outDir}/${benchmark}-${configName}-cross-*.csv; do
		temp=${f}.temp

		# The third column is the latency, take that and strip the header
		cut -d, -f3 ${f} | awk 'NR>1' > ${temp}

		# Extract the timestamp from the filename (format is ###.timestamp.csv)
		ts=`echo $(basename -- "$f") | sed -e 's/[^.]*.\([^.]*\).csv/\1/g'`

		# Insert the timestamp as the first line.  Because of BSD sed on MacOS vs GNU sed
		# on *nix systems, there is no portable way to do this without an intermediate backup
		# file.  Also weird newline insertion syntax because Mac.
		sed -i.bak '1s/^/'"${ts}"'\'$'\n/' ${temp}
		rm ${temp}.bak
	done

	paste -d, ${outDir}/*.temp > ${outDir}/${benchmark}-samples-${configName}.csv
	rm ${outDir}/*.temp
done
done
