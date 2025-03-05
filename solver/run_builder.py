#!/usr/bin/env python

import sys
from pathlib import Path
import os
import re
import glob

datapath = '/project/jonccal/fthpc/common/sdrbench/'

datasets = {
    'miranda': {'name':'SDRBENCH-Miranda-256x384x384', 'dims': [256,384,384]},
    'qmcpack': {'name':'qmcpack', 'dims': [69,69,115]},
    'hurricane': {'name':'hurricane', 'dims': [100,500,500]},
    'cesm3d': {'name':'CESM3D', 'dims': [26,1800,3600]},
    'scale': {'name':'scale', 'dims': [98,1200,1200]},
    'nyx': {'name':'NYX', 'dims': [512,512,512]}
}

def get_timestep(fpath,timestep):
    files = glob.glob(os.path.join(fpath, f"*{timestep}.bin"))

    return files

#compressors = ['sz','sz3','zfp','sperr','tthresh','mgard']
#compressors = ['sz']

assert len(sys.argv) > 2, "must provide compressor to use and error bounding mode (abs | rel)"

comp = sys.argv[1]
errmode = sys.argv[2]

app = 'hurricane'
dim1 = 100
dim2 = 500
dim3 = 500
appdir = '/project/jonccal/fthpc/alpoulo/datasets/hurricane'
compresshome = '/project/jonccal/fthpc/alpoulo/repositories/Correlation_Compressibility'
solvedir = compresshome + '/solver'
jobdir = solvedir + '/slurm'

if not os.path.exists(jobdir):
    os.mkdir(jobdir)

#files = glob.glob(os.path.join(appdir, '*.bin'))

ntasks = 16
mem = '2gb'
walltime = '8:00:00'

#for comp in compressors:
for t in range(1,49):

    timestep = f"{t:02d}"
    job = app + '_t' + timestep + '_' + comp + '_' + errmode 
    
    preamble = [
            f'#!/bin/bash\n',
            f'#SBATCH --job-name {job}\n',
            f'#SBATCH --ntasks {ntasks}\n',
            f'#SBATCH --cpus-per-task 1\n',
            f'#SBATCH --mem-per-cpu {mem}\n',
            f'#SBATCH --time {walltime}\n',
            f'#SBATCH --constraint extension_avx2\n',
            f'\n\n',
            f'function echo_do(){{\n',
            f'\techo $@\n',
            f'\t$@\n',
            f'}}\n\n',
            f'echo_do source ~/.bashrc\n'
            f'cd {solvedir}\n',
            f'echo_do source .solver/bin/activate\n',
            f'echo_do spack env activate {compresshome}\n\n'
    ]
    slurmout = os.path.join(jobdir,'%s.job' % job)
    with open(slurmout,'w') as so:
        so.writelines(preamble)

    files = get_timestep(appdir,timestep)
    for f in files:
        with open(slurmout,'a') as so:
            so.write(f'echo_do mpiexec --use-hwthread-cpus -np {ntasks} python build_dataset.py {comp} {f} {dim1} {dim2} {dim3} {errmode}\n\n')

    os.system("sbatch %s" %slurmout)


