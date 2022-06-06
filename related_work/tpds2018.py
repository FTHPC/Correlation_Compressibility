#!/usr/bin/env python
import random
import numpy as np
import libpressio
import statistics
import argparse
import csv
import os
import time


parser = argparse.ArgumentParser()
parser.add_argument("--dtype", type=np.dtype, default=np.dtype("float32"))
parser.add_argument("--output_file", "-o", type=str, default="klasky_CLOUDf48.csv")
parser.add_argument("--dims", "-d", type=int, action="append", default=[])
parser.add_argument("--filename", type=str, default="/home/runderwood/git/datasets/hurricane/100x500x500/CLOUDf48.bin.f32")
args = parser.parse_args()


# d = np.linspace(0.0, 1.0, num=384 * 384 * 256).reshape(384, 384, 256)

d = np.fromfile(args.filename,dtype=args.dtype).reshape(args.dims)

block_size = 8


def from_start_to_slice(b, block_size=8):
    return tuple([slice(i, i + block_size) for i in b])


random_start = [(0, i - (block_size + 1)) for i in d.shape[1:]]

counts = 10
samples = []
starts = [[random.randint(i, j) for (i, j) in random_start] for count in range(counts)]


if os.path.exists(args.output_file):
    mode = 'a'
else:
    mode = 'w'

csvfile = open(args.output_file, mode)

csv_columns = [ 'size:error_bound',
                'info:slice',
                'info:is_sample',
                'size:bit_rate', 
                'size:compressed_size',
                'size:compression_ratio',
                'size:decompressed_size', 
                'size:uncompressed_size', 
                'sz:block_size', 
                'sz:constant_flag', 
                'sz:huffman_coding_size', 
                'sz:huffman_compression_ratio', 
                'sz:huffman_node_count', 
                'sz:huffman_tree_size', 
                'sz:lorenzo_blocks', 
                'sz:lorenzo_percent', 
                'sz:quantization_intervals', 
                'sz:regression_blocks', 
                'sz:regression_percent', 
                'sz:total_blocks', 
                'sz:unpredict_count', 
                'sz:use_mean']

writer = csv.DictWriter(csvfile, fieldnames=csv_columns)
writer.writeheader()

for slice_dim in range(0, args.dims[0]-1, 5):
    new = d[slice_dim, :, :]
    samples = []
    for start in starts:
        samples.append(new[from_start_to_slice(start, block_size=block_size)])
    for bound in [1e-6, 1e-5, 1e-4, 1e-3, 1e-2]:
        c = libpressio.PressioCompressor.from_config(
            {
                "compressor_id": "sz",
                "compressor_config": {"pressio:abs": bound, "pressio:metric": "size"},
            }
        )

        crs = []
        
        o = new.copy()
        s = new.copy()
        b = c.encode(s)
        c.decode(b, o)
        m = c.get_metrics()
        m.update({"size:error_bound" : bound, "info:slice" : slice_dim, "info:is_sample" : False})
        cr = m["size:compression_ratio"]
 
        writer.writerow(m)
        begin = time.perf_counter()
        for s in samples:
            o = s.copy()
            s = s.copy()
            b = c.encode(s)
            c.decode(b, o)
            m = c.get_metrics()
            m.update({"size:error_bound" : bound, "info:slice" : slice_dim, "info:is_sample" : True})
            crs.append(m["size:compression_ratio"])
            # print(m)
            writer.writerow(m)

        n = time.perf_counter()
        print("slice : ", slice_dim, bound)
        print("sample_time ", str(n - begin))
        print("mean of crs", statistics.mean(crs))
        print("actual cr", cr)
        print()
