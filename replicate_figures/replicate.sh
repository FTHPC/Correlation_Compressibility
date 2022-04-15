#!/bin/bash
#Spack install location

#Compress statistic package location
PACKAGE=$SPACK_ENV/compression

# activate spack and spack packages
echo "Spack location: $SPACK_ROOT"
source $SPACK_ROOT

echo "Package location: $PACKAGE"

cd $PACKAGE/replicate_figures


echo "Performing Figure Replication"
Rscript graphs_paper_container.R > figure_replicate.log
