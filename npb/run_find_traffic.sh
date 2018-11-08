#!/bin/bash

if [ -z $2 ]; then
	echo "usage: $0 <outfile prefix> <iterations>"
	exit
fi

BIN_DIR=/nfs/npb_bin
DIR="$(dirname "${BASH_SOURCE[0]}")"
outpath=$1
iters=$2

hostfile="/nfs/files/scripts/env/mpi_hosts"
rankfile="/nfs/files/scripts/env/mpi_ranks_bynode" # fill each node in order, change rankfile to distribute
mpi_params="--mca btl ^tcp --rankfile ${rankfile}"
out_params="2>/dev/null"

execs=`ls ${BIN_DIR}`

echo ",tx_packet,tx_data,rx_packet,rx_data"

for exec in $execs; do
 test=`echo $exec|tr '.' ' '|awk '{print $1}'`
 size=`echo $exec|tr '.' ' '|awk '{print $2}'`
 procs=`echo $exec|tr '.' ' '|awk '{print $3}'`

 echo $test $size $procs

 outfile=${outpath}.${exec}.raw
# rm -f ${outfile}
 touch ${outfile} # avoid 'file not found'

 tx_pckt1=`ssh slave-0 "sudo perfquery |grep PortXmitPkts" |tr '.' ' '|awk '{print $2}'`
 tx_data1=`ssh slave-0 "sudo perfquery |grep PortXmitData" |tr '.' ' '|awk '{print $2}'`
 rx_pckt1=`ssh slave-0 "sudo perfquery |grep PortRcvPkts" |tr '.' ' '|awk '{print $2}'`
 rx_data1=`ssh slave-0 "sudo perfquery |grep PortRcvData" |tr '.' ' '|awk '{print $2}'`

# while [ `grep "Time in seconds" ${outfile} | wc -l` -lt ${iters} ]; do
 for iter in `seq 1 ${iters}`; do
# echo $tx_pckt1, $tx_data1, $rx_pckt1, $rx_data1
  timeout 60 mpiexec.openmpi --np ${procs} ${mpi_params} ${BIN_DIR}/${exec} ${out_params} >> ${outfile}
 done

 tx_pckt2=`ssh slave-0 "sudo perfquery |grep PortXmitPkts" |tr '.' ' '|awk '{print $2}'`
 tx_data2=`ssh slave-0 "sudo perfquery |grep PortXmitData" |tr '.' ' '|awk '{print $2}'`
 rx_pckt2=`ssh slave-0 "sudo perfquery |grep PortRcvPkts" |tr '.' ' '|awk '{print $2}'`
 rx_data2=`ssh slave-0 "sudo perfquery |grep PortRcvData" |tr '.' ' '|awk '{print $2}'`

 printf "%s,%d,%d,%d,%d\n" $test $((tx_pckt2-tx_pckt1)) $((tx_data2-tx_data1)) $((rx_pckt2-rx_pckt1)) $((rx_data2-rx_data1))
done
