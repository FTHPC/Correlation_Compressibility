#!/bin/bash
#Spack install location

#Compress statistic package location
PACKAGE=$SPACK_ENV/correlation_compressibility

# activate spack and spack packages
echo "Spack location: $SPACK_ROOT"
source $SPACK_ROOT

echo "Package location: $COMPRESS_HOME"

cd $COMPRESS_HOME/replicate_figures


echo "Performing Figure Replication"
Rscript graphs_paper_container.R > figure_replication.log
