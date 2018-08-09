#!/bin/bash

# install needed stuff
sudo yum update -y -q
sudo yum install -y -q openmpi
sudo yum install -y -q iperf3
echo 'export PATH=$PATH:/usr/lib64/openmpi/bin' >> ~/.bashrc
