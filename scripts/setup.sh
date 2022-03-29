#!/bin/bash
#Spack install location
SPACK=$HOME/spack/share/spack/setup-env.sh
#Compress statistic package location
PACKAGE=$HOME/compression

# activate spack and spack packages
echo "Spack location: $SPACK"
source $SPACK

cd $PACKAGE
echo "Package location: $PACKAGE"
#load env
spack env activate .

cd $PACKAGE/scripts

#run package install script for R
Rscript setup.R
