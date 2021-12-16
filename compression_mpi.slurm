#!/bin/bash
#SBATCH --job-name=compressability
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=18
#SBATCH --mail-user runderwood@anl.gov
#SBATCH --mail-type=ALL
#SBATCH --time=01:00:00

source /lcrc/project/ECP-EZ/public/compression/compressability/setup.sh
srun -n 36 python -m mpi4py ./process_script_mpi.py
