#!/bin/bash

#
# take a hostfile and classify the hosts into two groups around a mean bandwith threshold
#

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && git rev-parse --show-toplevel)
UTIL=${REPO}/util
RUN=${REPO}/run

hostfile=$1

if [ -z "${hostfile}" ]; then
	echo "usage: $0 <hostfile> [classifier args]"
	exit
fi

shift

echo "Classifying hosts based on bandwidth."

# get set of cross-sectional bandwidth measurements
resultDir=/nfs/bwthresh/samples
resultName=bwclassify
nodeClassifier=${UTIL}/hostnameNodeClassifier.sh
seconds=2

mkdir -p ${resultDir}
rm -f ${resultDir}/*

measureArgs+=" --hostfile ${hostfile}"
measureArgs+=" --resultName ${resultName}"
measureArgs+=" --resultDir ${resultDir}"
measureArgs+=" --seconds ${seconds}"
measureArgs+=" --nodeClassifier ${nodeClassifier}"

nhosts=`wc -l ${hostfile}`
echo "Running cross-sectional bandwidth study of ${nhosts} hosts."
#echo "${measureArgs}"

${RUN}/iperf/run_cross.sh ${measureArgs} > /dev/null

# break into two hostfiles
# put them in same dir as hostfile
outDir=`dirname ${hostfile}`

sample_files=`echo ${resultDir}/*${resultName}*` # weirdness with brace expansion and wildcards requires echo

classifierArgs+=" --sample_files ${sample_files}"
#classifierArgs+=" --output_dir ${outDir}"
classifierArgs+=" $@"

#echo "Classifying bandwidth results with parameters:"
#echo "${classifierArgs}"

${UTIL}/iperfCrossClassifier.py ${classifierArgs}

#echo "Done."
