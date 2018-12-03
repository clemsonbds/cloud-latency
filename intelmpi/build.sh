#!/bin/bash

installDir=${1:-"./intelmpi"}

make --directory=${installDir} IMB-MPI1
