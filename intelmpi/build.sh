#!/bin/bash

installDir=${1:-.}

make --directory=${installDir} IMB-MPI1
