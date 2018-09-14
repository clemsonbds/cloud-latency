#!/bin/bash

rawDir=~/data/cloud-latency/results/raw/micro
outDir=~/data/cloud-latency/results/parsed/micro

mkdir -p ${outDir}

# parse raw pingpong output to individual CSV files
for rawfile in ${rawDir}/pingpong*.raw; do
	filename=$(basename -- "$rawfile")
	filename="${filename%.*}"

	echo Parsing ${filename}.raw
	./parse_pingpong.py -o ${outDir}/${filename}.csv ${rawfile}
done

# create a CSV of pingpong latencies, one sample per column
for grouping in cluster spread multi-az; do
	for virt in vm metal; do
		for f in ${outDir}/pingpong-${grouping}-${virt}-cross-*.csv; do
			cut -d, -f3 ${f} > ${f}.temp
		done

		paste -d, ${outDir}/*.temp | awk 'NR>1' > ${outDir}/pingpong-${grouping}-${virt}-samples.csv
		rm ${outDir}/*.temp
	done
done

# parse raw iperf output to individual CSV files
for rawfile in ${rawDir}/iperf*.json; do
	filename=$(basename -- "$rawfile")
	filename="${filename%.*}"

	echo Parsing ${filename}.json
	./parse_iperf.py -o ${outDir}/${filename}.csv ${rawfile}
done
