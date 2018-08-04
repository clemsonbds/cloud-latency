#!/bin/bash

bastionIP=$1

# mount NFS
sudo mkdir -p /nfs
sudo chmod 777 /nfs

mount -t nfs ${bastionIP}:/nfs /nfs
