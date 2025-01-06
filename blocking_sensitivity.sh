#!usr/bin/env bash
function echo_do(){
  echo $@
  "$@"
}

COMPRESS_HOME=/project/jonccal/fthpc/alpoulo/repositories/Correlation_Compressibility

cd $COMPRESS_HOME/build

declare -A dset_size
dset_size[SDRBENCH-Miranda-256x384x384]="-d 256 -d 384 -d 384"
dset_size[qmcpack]="-d 69 -d 69 -d 115" 
dset_size[hurricane]="-d 100 -d 500 -d 500"
dset_size[hurricane_V]="-d 100 -d 500 -d 500"
dset_size[CESM3D]="-d 26 -d 1800 -d 3600"
dset_size[NYX_z]="-d 512 -d 512 -d 512"
dset_size[SDRBENCH-SCALE-98x1200x1200]="-d 98 -d 1200 -d 1200"

declare -A dset_dtype
dset_dtype[SDRBENCH-Miranda-256x384x384]=float64
dset_dtype[qmcpack]=float32
dset_dtype[hurricane]=float32
dset_dtype[hurricane_V]=float32
dset_dtype[CESM3D]=float32
dset_dtype[NYX_z]=float32
dset_dtype[SDRBENCH-SCALE-98x1200x1200]=float32

declare -A dset_loc
dset_loc[SDRBENCH-Miranda-256x384x384]=$COMPRESS_HOME/datasets
dset_loc[qmcpack]=$COMPRESS_HOME/datasets
dset_loc[hurricane]=$COMPRESS_HOME/datasets
dset_loc[hurricane_V]=$COMPRESS_HOME/datasets
dset_loc[CESM3D]=/zfs/fthpc/alpoulo/datasets
dset_loc[NYX_z]=$COMPRESS_HOME/datasets
dset_loc[SDRBENCH-SCALE-98x1200x1200]=$COMPRESS_HOME/datasets

walltime="12:00:00"

#app="SDRBENCH-SCALE-98x1200x1200"
#app="SDRBENCH-Miranda-256x384x384"
#app="hurricane"
#app="hurricane_V"
app="NYX_z"
#app="CESM3D"
#app="qmcpack"

ncores=64

max_block_count="1"

slurmdir="./slurm"
mkdir -p $slurmdir
#for compressor in "sz" "sz3" "zfp" "mgard" "tthresh" "digit_rounding" "fpzip" "bit_grooming"
for compressor in "sz" "sz3" "zfp" "sperr" "tthresh"
#for compressor in "bit_grooming"
do
  #for block_size in 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
  #for block_size in 16 20 24 28 32
  for block_size in 4 6 8 10 12 14 
  do
    blocks=${max_block_count}

    slurmout="${slurmdir}/${app}_${compressor}_${blocks}_${block_size}.sh"
    echo "#!/bin/bash" > $slurmout
    echo "#SBATCH --job-name compression_estimation_${app}_${compressor}_${block_size}" >> $slurmout
    echo "#SBATCH --nodes 1" >> $slurmout
    echo "#SBATCH --ntasks-per-node ${ncores}" >> $slurmout
    echo "#SBATCH --cpus-per-task 1" >> $slurmout
    echo "#SBATCH --mem 250gb" >> $slurmout
    echo "#SBATCH --time ${walltime}" >> $slurmout
    #echo "#SBATCH --partition fluxcapacitor" >> $slurmout

    printf "\nsource ~/.bashrc\n" >> $slurmout
    
    echo "function echo_do(){" >> $slurmout
    printf "\techo \$@\n" >> $slurmout
    printf "\t\"\$@\"\n" >> $slurmout
    printf "}\n\n" >> $slurmout
    
    #load spack
    echo "compress" >> $slurmout
    echo "cd $COMPRESS_HOME/build" >> $slurmout
    printf "\n" >> $slurmout

    echo "declare -A dset_size" >> $slurmout
    echo "dset_size[${app}]=\"${dset_size[${app}]}\"" >> $slurmout
    echo "declare -A dset_dtype" >> $slurmout >> $slurmout
    echo "dset_dtype[${app}]=\"${dset_dtype[${app}]}\"" >> $slurmout
    echo "declare -A dset_loc" >> $slurmout >> $slurmout
    echo "dset_loc[${app}]=\"${dset_loc[${app}]}\"" >> $slurmout
    printf "\n" >> $slurmout


    echo "for dataset in ${app}" >> $slurmout
    echo "do" >> $slurmout

    printf "\techo_do which mpiexec\n" >> $slurmout
    printf "\techo_do mpiexec -np ${ncores} ./compress_analysis -t \${dset_dtype[\${dataset}]} \\
      -i \${dataset} -r \${dset_loc[\${dataset}]} \${dset_size[\${dataset}]} \\
      -o \"\${dataset}_${compressor}_blocks128_block_size${block_size}.csv\" \\
      --blocks ${blocks} --block_size ${block_size} --method \"UNIFORM\" \\
      --compressor \"${compressor}\"" >> $slurmout 

    printf "\n" >> $slurmout

    echo "done" >> $slurmout

    #echo "cp -r \$TMPDIR ${app}_${fname}_blocks_${block_size}" >> $slurmout

    sbatch $slurmout
  #done
  done
done
