#!/bin/bash
echo "Spack location: $SPACK_ROOT"

echo "Package location: $COMPRESS_HOME"

cd $COMPRESS_HOME/replicate_figures


echo "Performing Figure Replication"
Rscript graphs_paper_container.R > figure_replication.log
