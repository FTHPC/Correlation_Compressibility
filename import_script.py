'''
import_script.py
reads in csv file and graphs data
'''
import compress_package as cp
import json

sample_data_miranda = cp.setup.import_class('output_miranda_nov22.csv')
sample_data_gaussian = cp.setup.import_class('output_gaussian_nov22.csv')
sample_data_gaussian_multi = cp.setup.import_class('output_multiscale_nov22.csv')

sample_data_classes = sample_data_miranda + sample_data_gaussian + sample_data_gaussian_multi


for data_class in sample_data_classes:
    print(data_class.filename)

    if hasattr(data_class, 'gaussian_attributes'):
        print(json.dumps(data_class.gaussian_attributes, indent=4))

    print("Global SVD Statistics: ")
    print(json.dumps(data_class.global_svd_measurements, indent=4))

    print("2D Tiled Statistics of Singular Modes: ")
    print(json.dumps(data_class.tiled_svd_measurements, indent=4))

    print("Coarsen Statistics: ")
    print(json.dumps(data_class.coarsened_attributes, indent=4))
    print(json.dumps(data_class.coarsened_variogram_measurements, indent=4))

    print("Compression Statistics: ")
    print(json.dumps(data_class.compression_measurements, indent=4))

    print("Variogram Study Statistics: ")
    if hasattr(data_class, 'global_variogram_fitting'):
        print('Global Variogram Fitting:'+str(data_class.global_variogram_fitting))
    print(json.dumps(data_class.local_variogram_measurements, indent=4))

# cp.plot.sdrbench_comparison(sample_data_classes, fit='log', separate_by_file=True)
# cp.plot.sdrbench_comparison(sample_data_classes, fit='linear', separate_by_file=True)

cp.plot.gaussian_comparison(sample_data_classes, K_points=1028, multi_gaussian=False, fit='log')
cp.plot.gaussian_comparison(sample_data_classes, K_points=1028, multi_gaussian=False, fit='linear')

cp.plot.gaussian_comparison(sample_data_classes, K_points=1028, multi_gaussian=True, fit='log')
cp.plot.gaussian_comparison(sample_data_classes, K_points=1028, multi_gaussian=True, fit='linear')


