import numpy as np
import timeit
import sys
#set path to directory above
sys.path.append('../')
import compress_package as cp

dataset = sys.argv[1]

quantize_bound = 1e-5
quantize_mode  = 'abs'
dtype = 'float32'

#required for compress package
global_data = cp.setup.global_data(dataset_directory='runtime_analysis', compress_metrics_needed=[])


if (dataset == 'NYX'):
    dimensions = [512, 512, 512]
    data_folder = 'nyx'
elif (dataset == 'SCALE'):
    dimensions = [98, 1200, 1200]
    data_folder = 'scale'
else:
    raise RuntimeError(print("invalid dataset option"))


sample = cp.setup.read_slice_folder(global_data, data_folder, dimensions, slices_needed=[0], slice_dimensions='X', dtype = dtype)

#reduce list to first element
sample = sample[0]

print(f'Quantizing {dataset} at a {quantize_mode} {quantize_bound} error bound')
print(timeit.timeit("cp.compress.quantize(sample, quantize_bound, quantize_mode)", number=100, globals=globals()))

print('Performing SVD analysis')
print(timeit.timeit("cp.svd_coarsen.global_svd(sample)", number=100, globals=globals()))

print('Performing tiled SVD analysis with a size of 32x32')
print(timeit.timeit("cp.svd_coarsen.tiled_singular(sample, 64)", number=100, globals=globals()))


print('Performing local variogram analysis with a size of 32x32')
print(timeit.timeit("cp.variogram.local_variogram_study(sample)", number=100, globals=globals()))


# compressing with just SZ at 1e-5
print('Compression using SZ lossy compressor at a abs 1e-5 error bound')
print(timeit.timeit("cp.compress.run_compressors(sample, ['sz'], start=-5, stop=-5, bound_type=['abs'])", number=100, globals=globals()))


