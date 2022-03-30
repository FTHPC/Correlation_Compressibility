#!/bin/bash
#Spack install location
SPACK=$HOME/spack/share/spack/setup-env.sh
#Compress statistic package location
PACKAGE=$HOME/compression

while getopts d:h flag
do
	case "$flag" in
		d) dataset=$OPTARG ;;
		h)  echo ""
			echo "-d [DATASET]	: dataset wanting to simulate: [NYX] OR [SCALE]"
			echo "-h 		: help"
			exit 1 ;;
	esac
done
if [[ "$dataset" != "NYX" && "$dataset" != "SCALE" ]]; then
	echo "ERROR: Must configure a dataset properly" 
	echo "Use -h for help"
	exit 1
fi


# activate spack and spack packages
echo "Spack location: $SPACK"
source $SPACK

cd $PACKAGE
echo "Package location: $PACKAGE"
#load env
spack env activate .

cd $PACKAGE/runtime_analysis

# runs script based on dataset specified 
if [[ "$dataset" == "NYX" ]]; then
	echo "Performing NYX runtime analysis"
	Rscript runtime_analysis_nyx.R
	python timing_test_runtime.py NYX > statistic_benchmark_runtime_nyx.txt

elif [[ "$dataset" == "SCALE" ]]; then
	echo "Performing SCALE runtime analysis"
	Rscript runtime_analysis_scale.R
	python timing_test_runtime.py SCALE > statistic_benchmark_runtime_scale.txt
fi
