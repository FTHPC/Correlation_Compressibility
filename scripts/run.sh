#!/bin/sh
#MPIPROCS
PROCS=32
#Spack install location
SPACK=$HOME/spack/share/spack/setup-env.sh
#Compress statistic package location
PACKAGE=$HOME/compression
#Quantize bounds for analysis
QBOUNDS=(0 1e-2 1e-4 1e-5)
#Quantize bound types for analysis
QTYPE=(abs rel)


while getopts d:c:sph flag
do
    case "$flag" in
        d) dataset=$OPTARG ;;
        c) configf=$OPTARG ;;
        s) serial=1 ;;
        p) parallel=1 ;;
        h)  echo "-d [DATASET]      : dataset wanting to run"
            echo "-c [CONFIG]       : config file in .json format"
            echo "-s                : serial mode (only 1 job). PBS scheduler MUST be configured"
            echo "-p                : parallel mode (multiple job(s)). PBS scheduler MUST be configured"
            echo "-h                : help"
            echo "if -s AND -p are not set, the program enters local hardware mode"
            exit 1 ;;
    esac
done

if [[ -z "$dataset" || -z "$configf" ]]; then
    echo "ERROR: Must configure a dataset and config file" 
    echo "Use -h for help"
    exit 1
fi

if [[ -z "$serial" && -z "$parallel" ]]; then
    #using local hardware
    echo "Running locally without a scheduler"

    #must have the spack installed
    echo "Spack location: $SPACK"
    source $SPACK

    cd $PACKAGE
    echo "Package location: $PACKAGE"
    #load env
    spack env activate .

    for bound in ${QBOUNDS[@]}
        do
            for type in ${QTYPE[@]}
            do
                mpiexec -n $PROCS python -m mpi4py process_script_mpi.py $configf $dataset $bound $type
            done
        done


else
    #using pbs scheduler
    if [[ "$parallel" ]]; then
        #multiple jobs // parallel mode
        for bound in ${QBOUNDS[@]}
            do
                for type in ${QTYPE[@]}
                do
                    qsub -v "configf=$configf,dataset=$dataset,bound=$bound,type=$type,job=parallel,PROCS=$PROCS,SPACK=$SPACK,PACKAGE=$PACKAGE" scripts/schedule.pbs
                done 
            done 
    else
        #single job // serial mode
        qsub -v "configf=$configf,dataset=$dataset,job=serial,PROCS=$PROCS,SPACK=$SPACK,PACKAGE=$PACKAGE,QBOUNDS=$QBOUNDS,QTYPE=$QTYPE" scripts/schedule.pbs
    fi
fi