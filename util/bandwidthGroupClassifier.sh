#!/bin/bash

#
# take a hostfile and classify the hosts into two groups around a mean bandwith threshold
#

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}
runDir=${DIR}/../run

hostfile=$1

if [ -z "${hostfile}" ]; then
	echo "usage: $0 <hostfile> [classifier args]"
	exit
fi

shift

# get set of cross-sectional bandwidth measurements
resultDir=/nfs/bwthresh/samples
resultName=bwclassify
nodeClassifier=${utilDir}/hostnameNodeClassifier.sh
seconds=2

mkdir -p ${resultDir}
rm -f ${resultDir}/*

measureArgs+=" --hostfile ${hostfile}"
measureArgs+=" --resultName ${resultName}"
measureArgs+=" --resultDir ${resultDir}"
measureArgs+=" --seconds ${seconds}"
measureArgs+=" --nodeClassifier ${nodeClassifier}"

nhosts=`wc -l ${hostfile}`
echo "Running cross-sectional bandwidth study of ${nhosts} hosts, with parameters:"
echo "${measureArgs}"

${runDir}/iperf/run_cross.sh ${measureArgs} > /dev/null

# break into two hostfiles
# put them in same dir as hostfile
outDir=`dirname ${hostfile}`

#sample_files=${resultDir}/*bwclassify*

classifierArgs+=" --sample_dir ${resultDir}"
classifierArgs+=" --filter_by ${resultName}"
#classifierArgs+=" --sample_files ${sample_files}"
classifierArgs+=" --output_dir ${outDir}"
classifierArgs+=" $@"

echo "Classifying bandwidth results with parameters:"
echo "${classifierArgs}"

${utilDir}/iperfCrossClassifier.py "${classifierArgs}"

echo "Done."

#dominant=
#max_n=0

#for cls in `echo ${classes} | tr ',' ' '`; do
#	n=`cat ${outDir}/${cls}.hosts | wc -l`
#	if [ "${n}" -gt "${max_n}" ]; then
#		max_n=${n}
#		dominant=${cls}
#	fi
#done

#echo ${dominant}
