#!/usr/bin/env python

from pprint import pprint
import libpressio
import numpy as np
import argparse
import random
import subprocess
import re
import math

parser = argparse.ArgumentParser()
parser.add_argument("--sampling_ratio", type=float, default=.01)
parser.add_argument("--dtype", type=np.dtype, default=np.dtype("float32"))
parser.add_argument("--bound", type=float, default=1e-6)
parser.add_argument("--dims", "-d", type=int, action="append", default=[100,500*500])
parser.add_argument("--filename", type=str, default="/home/runderwood/git/datasets/hurricane/100x500x500/CLOUDf48.bin.f32")
parser.add_argument("--gauss_file", type=str, default="gauss_repo.txt")
parser.add_argument("--debug", action="store_true")
args = parser.parse_args()

# example args for testing
# class args:
#     sampling_ratio=.01
#     dtype=np.dtype("float32")
#     bound=1e-8
#     dims=[100,500*500]
#     filename = "/home/runderwood/git/datasets/hurricane/100x500x500/CLOUDf48.bin.f32"
#     gauss_file = "gauss.txt"

compressor = libpressio.PressioCompressor.from_config({
    "compressor_id": "sz",
    "early_config": {
        "pressio:metric": "composite",
        "composite:plugins": ["size", "diff_pdf", "time", "error_stat"]
    },
    "compressor_config": {
        "pressio:abs": args.bound
    }
})

if args.debug:
    pprint(compressor.get_config())

input_data = np.fromfile(args.filename, dtype=args.dtype).reshape(args.dims)
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
        "pressio:abs": args.bound,
        "diff_pdf:intervals": quantization_intervals
    }
})
if args.debug:
    pprint(compressor.get_config())

input_shape = np.array(input_data.shape)
blocksize = full_metrics['sz:block_size']
block_counts = input_shape//full_metrics['sz:block_size']
samples = []
total_size = input_shape.prod()
block_size = full_metrics['sz:block_size'] ** input_shape.size
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


with open(args.gauss_file, "w") as gauss_file:
    for hist_bin, count in enumerate(histogram):
        for i in range(count):
            gauss_file.write(f"{hist_bin}\n")

proc = subprocess.run(["./gauss.py", args.gauss_file, str(full_metrics['error_stat:n'])], stdout=subprocess.PIPE)
node_count = int(re.search(rb"NodeCnt\s+(\d+)", proc.stdout).group(1))



# I don't think this is used anymore
# print("sample_hit_ratio", sample_metrics['sz:regression_percent'] + sample_metrics['sz:lorenzo_percent'])
# print("full_totalsize", full_metrics['error_stat:n'] * args.dtype.itemsize)
# print("sample_totalsize", sample_metrics['error_stat:n'] * args.dtype.itemsize)

print("sample_point_count", sample_metrics['error_stat:n'])
print("total_point_count", full_metrics['error_stat:n'])
print("quantization_intervals", quantization_intervals)
print("sample_node_count", sample_metrics['sz:huffman_node_count'])
print("sample_tree_size", sample_metrics['sz:huffman_tree_size'])
print("sample_encode_size", sample_metrics['sz:huffman_coding_size'])
print("sample_outlier_count", sample_metrics['sz:unpredict_count'])
print("sample_outlier_size", sample_metrics['sz:unpredict_count'] * args.dtype.itemsize)
print("full_outlier_count", full_metrics['sz:unpredict_count'])


outlier = sample_metrics['sz:unpredict_count']/  (sample_metrics['sz:unpredict_count'] * args.dtype.itemsize) * full_metrics['sz:unpredict_count']
encoding = sample_metrics['sz:huffman_coding_size'] / math.log2(sample_metrics['sz:huffman_node_count']) * math.log2(node_count)
tree = sample_metrics['sz:huffman_tree_size']/sample_metrics['sz:huffman_node_count']*node_count
estimate = outlier + tree + encoding

print("estimate", estimate)
print("estimate cr", input_shape.prod()/estimate)
print("actual cr", full_metrics['size:compression_ratio'])
print("sample cr", sample_metrics['size:compression_ratio'])
