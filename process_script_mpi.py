'''
process_script_mpi.py
reads in datasets and peforms statistical analysis on them.
results are outputted in a 'outputs' folder. The files are then combined to
a specified output file.
process_script.py with mpi
'''
output_file = 'testoutputs.csv'

import compress_package as cp
import pandas as pd
import os
import glob
import json
from mpi4py import MPI

#must setup a global data class
global_data = cp.setup.global_data()
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

if not rank:
    '''
    This is the section where one will setup the slices to import.
    A list of classes using cp.setup.read_slice_folder is needed. 
    
    '''
    '''
    # This shows how to setup a single slice for import to be used by other functions
    dimensions = [3072,3072]
    data_folder = 'Density-3072x3072-slices'
    sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions, 
            dtype='float32', parse = 'slice')
    
    '''
    dimensions = [256,384,384]
    data_folder = 'SDRBENCH-Miranda-256x384x384'
    sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions,
            slices_needed=range(0, 255, 50), slice_dimensions=['X', 'Y', 'Z'])
    '''
    # the 3 statistical analysis on the Gaussian samples (global SVD, tiled-SVD and 
    compute the standard deviation of the coarsened data)
    # cp.sampler.create_samples will return a list of classes.
    # sample_data_classes = cp.sampler.create_samples(global_data, a_range=[.5,1,2,4,8], n_samples=2, K_points=64)
    '''
    '''
    dimensions = [1028,1028]
    data_folder = 'Gaussian_2D_Samples_K1028'
    #returns a list of classes read from the data_folder
    sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions,
            dataset_name = 'Z', parse = 'gaussian')
    '''
    '''
    dimensions = [1028,1028]
    data_folder = 'Gaussian_2D_Samples_K1028_multiscale'
    #returns a list of classes read from the data_folder
    sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions, 
            dataset_name = 'Z', parse = 'gaussian_multi')
    '''
else:
    sample_data_classes = []

sample_data_classes = comm.bcast(sample_data_classes, root=0)
comm.Barrier()
    
#does global_svd, coarsening, and compression measurements on the list of sample data class
i = rank
while i<len(sample_data_classes):
    data_class = sample_data_classes[i]
    #stores the ouptut in coarsen_class.global_svd_measurements
    cp.svd_coarsen.global_svd(data_class, plot=True)

    #stores the output in coarsen_class.tiled_svd_measurments
    cp.svd_coarsen.tiled_multiple(data_class, plot=True)

    #data_import.coarsened_attributes will store the different resolution stats 
    cp.svd_coarsen.coarsen_multiple_resolution(data_class, plot=True, variogram_study=True)

    print("Compression Statistics: ")
    cp.compress.run_compressors(data_class,["sz", "zfp", "mgard", "tthresh"], start=-5, stop=-2)
    
    cp.variogram.global_variogram_study(data_class, plot=True)
    cp.variogram.local_variogram_study(data_class, plot=True)

    #plot original 
    cp.plot.original_data(data_class)

    #exports to excel .csv file
    cp.setup.slice_data.create_folder('outputs')
    cp.setup.export_class(data_class, 'outputs/output'+str(rank)+'.csv')
    i += size


comm.Barrier()
'''
combines multiple output files into one
https://www.freecodecamp.org/news/how-to-combine-multiple-csv-files-with-8-lines-of-code-265183e0854/
'''
if not rank:
    os.chdir("outputs")
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
    cp.setup.remove_folder('outputs')

comm.Barrier()
MPI.Finalize()
