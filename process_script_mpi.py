'''
process_script_mpi.py
reads in datasets and peforms statistical analysis on them.
results are outputted in a 'outputs' folder. The files are then combined to
a specified output file.
'''
#indicated output file
import compress_package as cp
import pandas as pd
import numpy as np
import itertools
import argparse
import sys
import os
import glob
import json
from mpi4py import MPI


def printsyntax():
    print("process_script_mpi.py [config_file] [dataset] [quantize_bound] [bound_type] ")
    print("[config_file]        : name of json config file")
    print("[dataset]            : dataset name. must be setup within config file.")
    print("[quantize_bound]     : quantization bound. data is quantized first than analysis is ran.")
    print("[bound_type]         : quantization bound type. can either be 'rel' or 'abs'")
    print("\n\n")

#must setup a global data class
global_data = cp.setup.global_data()
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

sample_data_classes = []
sample_size = 0
output_file = ''
data_folder = ''
quantize_bound = 0
quantize_mode = False

if not rank:
    # Parent rank sets up slices to be ready for reading
    if not len(sys.argv) >= 5:
        raise RuntimeError(printsyntax())
    
    #opens the config file
    f = open(f'scripts/{sys.argv[1]}')
    data = json.load(f)
    #reads the rest of the CLI
    dataset = sys.argv[2]
    quantize_bound = float(sys.argv[3])
    if quantize_bound > 0:
        quantize_mode = sys.argv[4]
    
    #dataset is the specific dataset being ran within the config file
    info = data["datasets"][dataset]
    #gaining inputs from config file
    output_file     = info['output']
    data_folder     = info['folder']
    parse           = info['parse_info']
    dtype           = info['dtype']
    dataset_name    = info['dataset_name']

    dimensions_str  = info['data_dimensions'].split(', ')
    dimensions      = [int(i) for i in dimensions_str]
    if not info['slice_dimensions'] == "None":
        slice_dims_str  = info['slice_dimensions'].split(', ')
        slice_dims      = [str(i) for i in slice_dims_str]
    else: 
        slice_dims = None
    
    if len(dimensions) == 2:
        slice_dims = None
        if not isinstance(parse, str):
            raise RuntimeError(print(data["datasets"]["_comment"]))
    elif len(dimensions) == 3:
        dataset_name = None
        if len(slice_dims) <= 0:
            raise RuntimeError(print(data["datasets"]["_comment"]))
        
    
    #create the sample_data_classes list of classes
    if len(dimensions) == 3:
        for i, dim in enumerate(slice_dims):
            #reduces slices if too many
            iterations = 5 if dimensions[i] > 64 else 1
            sample_data_classes = sample_data_classes.copy() + cp.setup.read_slice_folder(global_data, data_folder, dimensions,
                            slices_needed=list(range(0, dimensions[i]-1, iterations)), slice_dimensions = dim, dtype = dtype)
         
    else:
        sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions,
            dataset_name = dataset_name, parse = parse, dtype = dtype)
    # size is needed for MPI        
    sample_size = len(sample_data_classes)

comm.Barrier()
# parent rank shares with all other proccesses 
# split up in order to bcast more at once (fails without doing)
sample_size = comm.bcast(sample_size, root=0)
if rank:
    #matching list size of parent node
    sample_data_classes = list(range(sample_size))

for i, classx in enumerate(sample_data_classes):
    sample_data_classes[i] = comm.bcast(sample_data_classes[i], root=0)

output_file = comm.bcast(output_file, root=0)
data_folder = comm.bcast(data_folder, root=0)
quantize_bound = comm.bcast(quantize_bound, root=0)
quantize_mode = comm.bcast(quantize_mode, root=0)

comm.Barrier()

i = rank
while i<len(sample_data_classes):
    data_class = sample_data_classes[i]
    if quantize_bound > 0: 
        cp.compress.quantize(data_class, quantize_bound, quantize_mode)
    #stores the ouptut in coarsen_class.global_svd_measurements

    cp.svd_coarsen.global_svd(data_class, plot=False)
    #stores the output in coarsen_class.tiled_svd_measurments

    cp.svd_coarsen.tiled_multiple(data_class, plot=False)

    # #data_import.coarsened_attributes will store the different resolution stats 
    cp.svd_coarsen.coarsen_multiple_resolution(data_class, plot=False, variogram_study=False)
    compressors = [
        "sz",
        #"sz:high",
        #"sz:interpolation",
        #"sz:lorenzo",
        #"sz:regression",
        "zfp",
        "mgard",
        "fpzip", 
        "bit_grooming", 
        "digit_rounding",
        "tthresh"
    ]

    cp.compress.run_compressors(data_class, compressors, start=-5, stop=-2)

    # cp.variogram.global_variogram_study(data_class, plot=True)

    # cp.variogram.local_variogram_study(data_class, plot=False)

    
    #plot original 
    #cp.plot.original_data(data_class)

    #exports to excel .csv file
    cp.setup.slice_data.create_folder(data_folder+'_outputs')
    cp.setup.export_class(data_class, data_folder+'_outputs/output'+str(rank)+'.csv')
    i += size

comm.Barrier()
'''
combines multiple output files into one
https://www.freecodecamp.org/news/how-to-combine-multiple-csv-files-with-8-lines-of-code-265183e0854/
'''
if not rank:
    os.chdir(data_folder+'_outputs')
    output_filename = '../'+output_file
    extension = 'csv'
    all_filenames = [i for i in glob.glob('*.{}'.format(extension))]
    #combine all files in the list
    combined_csv = pd.concat([pd.read_csv(f) for f in all_filenames])
    #export to csv
    if os.path.exists(output_filename):
        combined_csv.to_csv( output_filename, mode='a', header=False, index=False, encoding='utf-8-sig')
    else:
        combined_csv.to_csv( output_filename, mode='a', index=False, encoding='utf-8-sig')

    os.chdir("..")
    cp.setup.remove_folder(data_folder+'_outputs')

comm.Barrier()
MPI.Finalize()
