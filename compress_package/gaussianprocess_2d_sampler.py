'''
gaussianprocess_2d_sampler.py
creates 2d guassian samples based on certain smoothness paramters

functions:
    create_samples(global_class, a_range=[.5], n_samples=2, K_points=128, plot = False)
'''
import numpy as np
import matplotlib.pyplot as plt
from compress_package import data_setup as setup, svd_coarsen
from compress_package.convert import slice_data
from scipy.special import gamma, kv

## Definition of the covariance functions (squared-exponential, powered-exponential and Matern)    
def get_r(x, y):
    return np.sqrt(np.subtract.outer(x, x)**2 +  np.subtract.outer(y, y)**2)

def sqexp_kernel(r, a = 1):             # a is the range
    r = np.exp(-(r/a)**2)
    r[r == 0] = 1e-8
    return r

def pwdexp_kernel(r, a = 1, v = 1):     # a is the range and v the smoothness  
    r = np.exp(-(r/a)**v)
    r[r == 0] = 1e-8
    return r

def matern_kernel(r, a = 1, v = 1):     # a is the range and v the smoothness 
    r = np.abs(r)
    #r += 1e-8
    r[r == 0] = 1e-8
    part1 = 2 ** (1 - v) / gamma(v)
    part2 = (np.sqrt(2 * v) * r / a) ** v
    part3 = kv(v, np.sqrt(2 * v) * r / a)
    return part1 * part2 * part3

## Define a sample generator
def sample(x, y, cov_func, cov_args = {}, n_samples = 2):
    prng = np.random.RandomState(1234)
    x_mean = np.zeros((len(x)))    # the mean is set to 0 here 
    x_cov = cov_func(get_r(x, y), **cov_args) 
    out = prng.multivariate_normal(x_mean, x_cov, n_samples)
    return out

'''
Simulation of 2 samples from a 2D-GP with squared exponential covariance with range parameter a
inputs:
    global_class            : the class that contains information relevant to every dataset 
    a_range                 : a list of range parameters, default [.5]
    n_samples               : number of samples to be run, default 2
    K_points                : number of points on each axis, default 128
    plot                    : indictations to plot the created data, default False
returns: the output paths of the newly created samples in a list
'''
def create_samples(global_class, a_range=[.5], n_samples=2, K_points=128, plot = False):
    x = np.linspace(0, 10, K_points)     # grid covers [0,10] * [0, 10] 
    y = np.linspace(0, 10, K_points)
    xg = np.tile(x, K_points)            # generates x-coordinates for the entire grid K*K 
    yg = np.repeat(y, K_points, axis=0)  # generates y-coordinates for the entire grid K*K
    
    ax = []
    reshaped_z = []
    sample_classes = []
    position = 0

    new_folder = f'Gaussian_2D_Sampler_K{K_points}'
    new_folder_path = global_class.dataset_directory+'/'+new_folder
    setup.create_folder(new_folder_path)
 
    for i, a in enumerate(a_range):
        #z changes with each new a in a_range
        z = sample(xg, yg, sqexp_kernel, {"a": a}, n_samples = n_samples) # a = 0.5, 1, 2, 4, 8
        for j in range(0, n_samples): 
            reshaped_z.append(np.reshape(z[j,:], (K_points, K_points)))
            #writes a new class for new sample0
            sample_classes.append(setup.data(global_class))
            #write z as temporary file
            binary_filename = 'sample_gp_K'+str(K_points)+'_a'+str(a)+'_sample'+str(j+1)
            sample_dataset_name = binary_filename+'.dat'
            sample_filename = sample_dataset_name+".h5"

            sample_full_path = slice_data.custom_slice(reshaped_z[position], binary_filename, sample_dataset_name, global_class.dataset_directory, new_folder_path, 'float64')

            sample_data_attributes = {"info:a_range":a, "info:k_points":K_points, "info:sample": j+1}

            #sets attributes of new class
            #for each coarsened resolution, a new class will be created.
            sample_classes[position].setup_slice(sample_filename, sample_dataset_name, new_folder, sample_full_path, reshaped_z[position].shape, 'float64')
            sample_classes[position].set_gaussian_attributes(sample_data_attributes)
            sample_classes[position].set_data(reshaped_z[position])

            position = position + 1
        
        if plot:
            X = plt.matshow(np.reshape(z[j,:], (K_points, K_points)))
            slice_data.create_folder('image_results')
            slice_data.create_folder('image_results/guassian_visuals')
            plt.imsave('image_Results/guassian_visuals/'+sample_filename+'.png', X)

    return sample_classes