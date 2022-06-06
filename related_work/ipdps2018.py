#!/usr/bin/env python

from pprint import pprint
import libpressio
import numpy as np
import argparse
import random
import subprocess
import re
import math
import csv
import os
import time
import sys


parser = argparse.ArgumentParser()
parser.add_argument("--sampling_ratio", type=float, default=.01)
parser.add_argument("--dtype", type=np.dtype, default=np.dtype("float32"))
parser.add_argument("--output_file", "-o", type=str, default="klasky_CLOUDf48.csv")
parser.add_argument("--dims", "-d", type=int, action="append", default=[])
parser.add_argument("--filename", type=str, default="/home/runderwood/git/datasets/hurricane/100x500x500/CLOUDf48.bin.f32")
parser.add_argument("--gauss_file", type=str, default="gauss_repo.txt")
parser.add_argument("--debug", action="store_true")
args = parser.parse_args()


if os.path.exists(args.output_file):
    mode = 'a'
else:
    mode = 'w'

csvfile = open(args.output_file, mode)

csv_columns = [   
    "size:error_bound",
    "info:slice",
    "sample_point_count",
    "total_point_count",
    "quantization_intervals",
    "sample_node_count",
    "sample_tree_size",
    "sample_encode_size",
    "sample_outlier_count",
    "sample_outlier_size",
    "full_outlier_count",
    "estimate",
    "estimate cr",
    "actual cr",
    "sample cr"
]

writer = csv.DictWriter(csvfile, fieldnames=csv_columns)
writer.writeheader()


# example args for testing
# class args:
#     sampling_ratio=.01
#     dtype=np.dtype("float32")
#     bound=1e-8
#     dims=[100,500*500]
#     filename = "/home/runderwood/git/datasets/hurricane/100x500x500/CLOUDf48.bin.f32"
#     gauss_file = "gauss.txt"

filed = np.fromfile(args.filename, dtype=args.dtype).reshape(args.dims)

for slice_dim in range(0, args.dims[0]-1, 5):
    for bound in [1e-6, 1e-5, 1e-4, 1e-3, 1e-2]:
        print()
        compressor = libpressio.PressioCompressor.from_config({
                "compressor_id": "sz",
                "early_config": {
                    "pressio:metric": "composite",
                    "composite:plugins": ["size", "diff_pdf", "time", "error_stat"]
                },
                "compressor_config": {
                    "pressio:abs": bound
                }
            })

        input_data = filed[slice_dim, :, :]
        output_data = input_data.copy()

        full_compressed = compressor.encode(input_data)
        output_data = compressor.decode(full_compressed, output_data)
        full_metrics = compressor.get_metrics()
        quantization_intervals = full_metrics['sz:quantization_intervals']

        compressor = libpressio.PressioCompressor.from_config({
                "compressor_id": "sz",
                "early_config": {
                    "pressio:metric": "composite",
                    "composite:plugins": ["size", "diff_pdf", "time", "error_stat"]
                },
                "compressor_config": {
                    "pressio:abs": bound,
                    "diff_pdf:intervals": quantization_intervals
                }
        })
        if args.debug:
            pprint(compressor.get_config())
   
        if full_metrics['sz:constant_flag']:
            print("ERROR: SZ constant flag set; Method is invalid")
            continue

        input_shape = np.array(input_data.shape)
        blocksize = full_metrics['sz:block_size'] 
        block_counts = input_shape//blocksize
        samples = []
        total_size = input_shape.prod()
        block_size = blocksize ** input_shape.size
        sampled_size = 0
        while sampled_size/total_size < args.sampling_ratio:
            block = [
                blocksize*random.randint(0, block_idx-1)
                for block_idx in block_counts
            ]
            sample_block_id = tuple([
                slice(b, b+blocksize)
                for b in block
            ])
            samples.append(input_data[sample_block_id])
            sampled_size += block_size

        sample_input_data = np.block(samples).copy()
        sample_output_data = sample_input_data.copy()

        sample_compressed = compressor.encode(sample_input_data)
        sample_output_data = compressor.decode(sample_compressed, sample_output_data)
        sample_metrics = compressor.get_metrics()
        histogram = sample_metrics['diff_pdf:histogram']
    

        if  (not len(histogram) or all(i == 0 for i in histogram) or
            not sample_metrics['error_stat:max_error']):
            print("ERROR: invalid histogram")
            print(histogram)
            #print(sample_metrics)
            #print(full_metrics)
            continue
        if (not sample_metrics['sz:unpredict_count']):
            print("ERROR: SZ unpredict count is zero; Method is invalid")
            continue

        with open(args.gauss_file, "w") as gauss_file:
            for hist_bin, count in enumerate(histogram):
                for i in range(count):
                    gauss_file.write(f"{hist_bin}\n")
            os.sync()

        proc = subprocess.run(["./gauss.py", args.gauss_file, str(full_metrics['error_stat:n'])], stdout=subprocess.PIPE)
        node_count = int(re.search(rb"NodeCnt\s+(\d+)", proc.stdout).group(1))

        # I don't think this is used anymore
        # print("sample_hit_ratio", sample_metrics['sz:regression_percent'] + sample_metrics['sz:lorenzo_percent'])
        # print("full_totalsize", full_metrics['error_stat:n'] * args.dtype.itemsize)
        # print("sample_totalsize", sample_metrics['error_stat:n'] * args.dtype.itemsize)

        metrics = {}
        outlier = sample_metrics['sz:unpredict_count']/  (sample_metrics['sz:unpredict_count'] * args.dtype.itemsize) * full_metrics['sz:unpredict_count']
        encoding = sample_metrics['sz:huffman_coding_size'] / math.log2(sample_metrics['sz:huffman_node_count']) * math.log2(node_count)
        tree = sample_metrics['sz:huffman_tree_size']/sample_metrics['sz:huffman_node_count']*node_count
        estimate = outlier + tree + encoding

        metrics.update({"size:error_bound" : bound, "info:slice" : slice_dim})
        metrics.update({
            "sample_point_count": sample_metrics['error_stat:n'],
            "total_point_count": full_metrics['error_stat:n'],
            "quantization_intervals": quantization_intervals,
            "sample_node_count": sample_metrics['sz:huffman_node_count'],
            "sample_tree_size": sample_metrics['sz:huffman_tree_size'],
            "sample_encode_size": sample_metrics['sz:huffman_coding_size'],
            "sample_outlier_count": sample_metrics['sz:unpredict_count'],
            "sample_outlier_size": sample_metrics['sz:unpredict_count'] * args.dtype.itemsize,
            "full_outlier_count": full_metrics['sz:unpredict_count'],
            "estimate": estimate,
            "estimate cr": input_shape.prod()/estimate,
            "actual cr": full_metrics['size:compression_ratio'],
            "sample cr": sample_metrics['size:compression_ratio']
        })

        writer.writerow(metrics)
    
        # print("ERROR: slice", slice_dim, " failed\nHistorgram length:", len(sample_metrics['diff_pdf:histogram']))
        # print(sample_metrics['diff_pdf:histogram'])
