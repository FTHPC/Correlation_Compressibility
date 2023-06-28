#!usr/bin/env bash
function echo_do(){
  echo $@
  "$@"
}


COMPRESS_HOME=/home/alpoulo/repositories/Correlation_Compressibility

cd $COMPRESS_HOME/build

    
declare -A dset_size
dset_size[SDRBENCH-Miranda-256x384x384]="-d 256 -d 384 -d 384"
dset_size[qmcpack]="-d 69 -d 69 -d 115" 
dset_size[hurricane]="-d 500 -d 500 -d 100"
dset_size[CESM3D]="-d 3600 -d 1800 -d 26"
dset_size[NYX]="-d 512 -d 512 -d 512"

declare -A dset_dtype
dset_dtype[SDRBENCH-Miranda-256x384x384]=float64
dset_dtype[qmcpack]=float32
dset_dtype[hurricane]=float32
dset_dtype[CESM3D]=float32
dset_dtype[NYX]=float32

declare -A dset_loc
dset_loc[SDRBENCH-Miranda-256x384x384]=$COMPRESS_HOME/datasets
dset_loc[qmcpack]=$COMPRESS_HOME/datasets
#dset_loc[hurricane]=/zfs/fthpc/common/sdrbench
dset_loc[hurricane]=$COMPRESS_HOME/datasets
dset_loc[CESM3D]=/zfs/fthpc/alpoulo/datasets
dset_loc[NYX]=/zfs/fthpc/alpoulo/datasets

app="hurricane"
walltime="16:00:00"
#compressors=("sz" "sz3" "zfp" "mgard" "tthresh" "digit_rounding" "fpzip" "bit_grooming")
compressors=("sz" "sz3" "zfp" "fpzip" "bit_grooming")

fname="CLOUDall"

pbsdir="./pbs"
mkdir -p $pbsdir
for compressor in "sz" "sz3" "zfp" "mgard" "tthresh" "digit_rounding" "fpzip" "bit_grooming"
do
  #choosing zfp, sz3d, 2x zfp, lcm(zfp,sz)/sz x2, zfp x 4, sz x 4, large
  for blocks in 128
  do
    #for block_size in 4 6 8 12 16 24 32
    for block_size in 9 10 11 13 14 15
    do
      pbsout="${pbsdir}/${app}_${compressor}_${blocks}_${block_size}.pbs"
      echo "#!/bin/bash" > $pbsout
      echo "#PBS -l select=1:ncpus=40:mem=372gb" >> $pbsout
      echo "#PBS -l walltime=${walltime}" >> $pbsout
      echo "#PBS -N data_compression_estimation_${app}_${compressor}_${blocks}_${block_size}" >> $pbsout
      echo "#PBS -m a" >> $pbsout
      echo "#PBS -j oe" >> $pbsout
      
      printf "\nsource ~/.bashrc\n" >> $pbsout
      
      echo "function echo_do(){" >> $pbsout
      printf "\techo \$@\n" >> $pbsout
      printf "\t\"\$@\"\n" >> $pbsout
      printf "}\n\n" >> $pbsout
      
      
      #load spack
      echo "compress" >> $pbsout
      echo "cd $COMPRESS_HOME/build" >> $pbsout
      printf "\n" >> $pbsout

      echo "declare -A dset_size" >> $pbsout
      echo "dset_size[${app}]=\"${dset_size[${app}]}\"" >> $pbsout
      echo "declare -A dset_dtype" >> $pbsout >> $pbsout
      echo "dset_dtype[${app}]=\"${dset_dtype[${app}]}\"" >> $pbsout
      echo "declare -A dset_loc" >> $pbsout >> $pbsout
      echo "dset_loc[${app}]=\"${dset_loc[${app}]}\"" >> $pbsout
      printf "\n" >> $pbsout


      echo "for dataset in ${app}" >> $pbsout
      echo "do" >> $pbsout

      printf "\techo_do which mpiexec\n" >> $pbsout
      printf "\techo_do mpiexec -np 40 ./compress_analysis -t \${dset_dtype[\${dataset}]} \\
        -i \${dataset} -r \${dset_loc[\${dataset}]} \${dset_size[\${dataset}]} \\
        -o \"\${dataset}_${fname}_${compressor}_blocks${blocks}_block_size${block_size}.csv\" \\
        --blocks ${blocks} --block_size ${block_size} --method \"UNIFORM\" \\
        --compressor \"${compressor}\"" >> $pbsout 

      printf "\n" >> $pbsout

      echo "done" >> $pbsout

      qsub $pbsout
    done
  done
done
