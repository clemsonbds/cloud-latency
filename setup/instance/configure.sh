#!/bin/bash

sudo yum update -y
sudo yum install -y openmpi
echo 'export PATH=$PATH:/usr/lib64/openmpi/bin' >> ~/.bashrc
