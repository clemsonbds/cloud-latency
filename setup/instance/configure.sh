#!/bin/bash

sudo yum install -y openmpi
echo "export PATH=$PATH:/usr/lib64/openmpi/bin" >> ~/.bashrc
