#!/bin/bash

rawDir=~/data/cloud-latency/results/raw/micro
outDir=~/data/cloud-latency/results/parsed/micro

mkdir -p ${outDir}

for rawfile in ${rawDir}/pingpong*.raw; do
	filename=$(basename -- "$rawfile")
	filename="${filename%.*}"

	./parse_pingpong.py -o ${outDir}/${filename}.csv ${rawfile}
done

for rawfile in ${rawDir}/iperf*.json; do
	filename=$(basename -- "$rawfile")
	filename="${filename%.*}"

	./parse_iperf.py -o ${outDir}/${filename}.csv ${rawfile}
done
