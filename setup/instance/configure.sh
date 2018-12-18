#!/bin/bash

# install needed stuff -- now built into Image
#sudo yum install -y -q openmpi
#sudo yum install -y -q iperf3
#sudo yum install -y -q gcc-c++ wget
#

#echo 'export PATH=$PATH:/usr/lib64/openmpi/bin' >> ~/.bashrc
echo "source /nfs/resources/bashrc.instance" >> ~/.bashrc
