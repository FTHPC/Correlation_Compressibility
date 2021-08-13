'''
process_script_mpi.py
reads in datasets and peforms statistical analysis on them.
results are outputted in a 'outputs' folder.
process_script.py with mpi
'''
import compress_package as cp
import json
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

#must setup a global data class
global_data = cp.setup.global_data()

# This shows how to setup a single slice for import to be used by other functions
dimensions = [3072,3072]
data_folder = 'Density-3072x3072-slices'
sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions, dtype='float32', parse = 'slice')


'''
# the 3 statistical analysis on the Gaussian samples (global SVD, tiled-SVD and compute the standard deviation of the coarsened data)
# cp.sampler.create_samples will return a list of classes.
# sample_data_classes = cp.sampler.create_samples(global_data, a_range=[.5,1,2,4,8], n_samples=2, K_points=64)
dimensions = [1028,1028]
data_folder = 'Gaussian_2D_Samples_K1028'
#returns a list of classes read from the data_folder
sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions, dataset_name = 'Z', parse = 'gaussian')
'''
'''
dimensions = [1028,1028]
data_folder = 'Gaussian_2D_Samples_K1028_multiscale'
#returns a list of classes read from the data_folder
sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions, dataset_name = 'Z', parse = 'gaussian_multi')
'''

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

    # print("Compression Statistics: ")
    cp.compress.run_compressors(data_class,["sz", "zfp", "mgard", "tthresh"], start=-5, stop=-2)

    cp.variogram.global_variogram_study(data_class, plot=True)
    cp.variogram.local_variogram_study(data_class, plot=True)

    #plot original 
    cp.plot.original_data(data_class)

    #exports to excel .csv file
    cp.setup.slice_data.create_folder('outputs')
    cp.setup.export_class(data_class, 'outputs/output'+str(rank)+'.csv')
    i += size

MPI.Finalize()
