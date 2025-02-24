#!/usr/bin/env python
from mpi4py import MPI
import libpressio as lp
import numpy as np
import pandas as pd
import sys
from tqdm import tqdm
from mpi4py.futures import MPICommExecutor
from concurrent.futures import as_completed

def evaluate(bound):
    compressor_id = "sz3"
    global data
    output = data.copy()
    c = lp.PressioCompressor(compressor_id, {f"{compressor_id}:metric": "composite", "composite:plugins": ["size", "error_stat"]}, {"pressio:abs": bound})
    compressed = c.encode(data)
    c.decode(compressed, output)
    return c.get_metrics() | {"config:compressor_id": compressor_id, "config:bound": bound}

data = np.fromfile("/home/runderwood/git/datasets/hurricane/100x500x500/CLOUDf48.bin.f32", dtype=np.float32).reshape(100, 500, 500)

with MPICommExecutor() as pool:
    if pool is not None:
        print("master")
        futs = []
        results = []
        N = 10_000
        for expon in tqdm(np.logspace(1e-5, 1e-3, num=N)):
            bound = np.log10(expon)
            futs.append(pool.submit(evaluate, bound))
        print("tasksdone")
        for idx, fut in enumerate(futs):
            results.append(fut.result())
            print(idx, '/', N)
        df = pd.DataFrame(results)
        df.to_csv("results.csv")
    else:
        print("worker")
        



