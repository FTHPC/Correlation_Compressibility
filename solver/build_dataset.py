#!/usr/bin/env python
from mpi4py import MPI
import libpressio as lp
import numpy as np
import pandas as pd
import sys
#from tqdm import tqdm
from mpi4py.futures import MPICommExecutor
from concurrent.futures import as_completed
from pathlib import Path
import sys

compresshome = "/project/jonccal/fthpc/alpoulo/repositories/Correlation_Compressibility/"

def evaluate(bound, compressor_id):
    #compressor_id = "sz3"
    global data
    output = data.copy()
    c = lp.PressioCompressor(compressor_id, {f"{compressor_id}:metric": "composite", "composite:plugins": ["size", "error_stat"]}, {"pressio:abs": bound})
    compressed = c.encode(data)
    c.decode(compressed, output)
    return c.get_metrics() | {"config:compressor_id": compressor_id, "config:bound": bound}

assert len(sys.argv) == 6, "must provide compressor, file path, and dimensions"

compressor = sys.argv[1]
inpath = sys.argv[2]
dim1 = int(sys.argv[3])
dim2 = int(sys.argv[4])
dim3 = int(sys.argv[5])

app = Path(inpath.split("/")[-2]).stem
fname = Path(inpath.split("/")[-1]).stem
outfile = compresshome + "solver/output/" + app + '_' + compressor + "_" + fname + ".csv"

data = np.fromfile(inpath, dtype=np.float32).reshape(dim1, dim2, dim3)

with MPICommExecutor() as pool:
    if pool is not None:
        print("master")
        futs = []
        results = []
        N = 10_000
        #for expon in tqdm(np.logspace(1e-5, 1e-3, num=N)):
        for expon in np.logspace(1e-5, 1e-3, num=N):
            bound = np.log10(expon)
            futs.append(pool.submit(evaluate, bound, compressor))
        print("tasksdone")
        for idx, fut in enumerate(futs):
            results.append(fut.result())
            print(idx, '/', N)
        df = pd.DataFrame(results)
        df.to_csv(outfile)
    else:
        print("worker")
        



