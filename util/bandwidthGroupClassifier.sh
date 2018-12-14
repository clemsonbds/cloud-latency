#!/bin/bash

#
# take a hostfile and classify the hosts into two groups around a mean bandwith threshold
#

DIR="$(dirname "${BASH_SOURCE[0]}")"
utilDir=${DIR}
runDir=${DIR}/../run

hostfile=$1
classes=$2

if [ -z "${classes}" ]; then
	echo "usage: $0 <hostfile> <classes>"
	exit
fi

# get set of cross-sectional bandwidth measurements
resultDir=/nfs/bwthresh/samples
resultName=bwclassify
nodeClassifier=${utilDir}/hostnameNodeClassifier.sh
seconds=2

mkdir -p ${resultDir}

measureArgs+=" --hostfile ${hostfile}"
measureArgs+=" --resultName ${resultName}"
measureArgs+=" --resultDir ${resultDir}"
measureArgs+=" --seconds ${seconds}"
measureArgs+=" --nodeClassifier ${nodeClassifier}"

${runDir}/iperf/run_cross.sh ${measureArgs}

# break into two hostfiles
# put them in same dir as hostfile
outDir=`dirname ${hostfile}`

classifierArgs+=" --sample_dir ${resultDir}"
classifierArgs+=" --output_dir ${outDir}"
classifierArgs+=" --filter_by ${resultName}"
classifierArgs+=" --classes ${classes}"

${utilDir}/iperfCrossClassifier.py ${classifierArgs}

dominant=
max_n=0

for cls in `echo ${classes} | tr ',' ' '`; do
	n=`cat ${outDir}/${cls}.hosts | wc -l`
	if [ "${n}" > "${max_n}" ]; then
		max_n=${n}
		dominant=${cls}
	fi
done

echo ${dominant}
