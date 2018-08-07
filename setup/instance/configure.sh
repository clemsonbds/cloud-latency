#!/bin/bash

# install needed stuff
sudo yum update -y -q
sudo yum install -y -q openmpi
echo 'export PATH=$PATH:/usr/lib64/openmpi/bin' >> ~/.bashrc
