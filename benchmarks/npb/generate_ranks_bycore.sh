#!/bin/bash

ranks=64
nodes=8

for rank in `seq 0 $((ranks - 1))`; do
 node=$((rank % nodes))
 slot=$((rank / nodes))
 core=$((slot + 2))
 echo rank ${rank}=slave-${node} slot=0:${core}
done
