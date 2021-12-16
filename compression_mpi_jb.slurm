#!/bin/bash
#SBATCH --job-name=compressability
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=18
#SBATCH --output=stat_analysis_jb.out
#SBATCH --error=stat_analysis_jb.error
#SBATCH --mail-user jbessac@anl.gov
#SBATCH --mail-type=ALL
#SBATCH --time=02:00:00

source /lcrc/project/ECP-EZ/public/compression/compressability/setup.sh
srun -n 36 python -m mpi4py ./process_script_mpi.py
