'''
process_script.py
reads in datasets and peforms statistical analysis on them.
'''
import compress_package as cp
import json
#must setup a global data class
global_data = cp.setup.global_data()

# cp.sampler.create_samples will return a list of classes.
# sample_data_classes = cp.sampler.create_samples(global_data, a_range=[.5,1,2,4,8], n_samples=2, K_points=64)

dimensions = [256,384,384]
data_folder = 'SDRBENCH-Miranda-256x384x384'
sample_data_classes = cp.setup.read_slice_folder(global_data, data_folder, dimensions, slices_needed=[0, 50])


#does global_svd, coarsening, and compression measurements on the list of sample data class
for data_class in sample_data_classes:
    print(data_class.filename)

    if hasattr(data_class, 'gaussian_attributes'):
        print(json.dumps(data_class.gaussian_attributes, indent=4))

    #stores the ouptut in coarsen_class.global_svd_measurements
    cp.svd_coarsen.global_svd(data_class, plot=True)
    print("Global SVD Statistics: ")
    print(json.dumps(data_class.global_svd_measurements, indent=4))

    #stores the output in coarsen_class.tiled_svd_measurments
    cp.svd_coarsen.tiled_multiple(data_class, plot=True)
    print("2D Tiled Statistics of Singular Modes: ")
    print(json.dumps(data_class.tiled_svd_measurements, indent=4))

    #data_import.coarsened_attributes will store the different resolution stats 
    cp.svd_coarsen.coarsen_multiple_resolution(data_class, plot=True, variogram_study=True)
    print("Coarsen Statistics: ")
    print(json.dumps(data_class.coarsened_attributes, indent=4))
    print(json.dumps(data_class.coarsened_variogram_measurements, indent=4))

    print("Compression Statistics: ")
    cp.compress.run_compressors(data_class,["sz", "zfp", "mgard", "tthresh"], start=-5, stop=-2)
    print(json.dumps(data_class.compression_measurements, indent=4))
    
    print("Variogram Study Statistics: ")
    cp.variogram.global_variogram_study(data_class, plot=True)
    print('Global Variogram Fitting:'+str(data_class.global_variogram_fitting))
    cp.variogram.local_variogram_study(data_class, plot=True)
    print(json.dumps(data_class.local_variogram_measurements, indent=4))
    
    #plot original 
    cp.plot.original_data(data_class)

    #exports to excel .csv file
    cp.setup.export_class(data_class, 'testtest.csv')

# should be last line
cp.setup.remove_folder(global_data.dataset_temp_folder)