'''
data_plot.py
Visualization file of the data. This will graph different relationships found in the
computed metrics. Some of the questions answered:
    How compression ratios relate to the overall correlation range?
    How compression ratios relate to local correlation ranges?

'''
from compress_package.convert import slice_data
import matplotlib.pyplot as plt
import numpy as np
import itertools


'''
@type function
original_data
plots the original data slice as a 2-D image using plt.imsave
saves file within image_results/original_data/
'''
def original_data(data_class):
    #displays the original data set
    Image = np.transpose(data_class.data )
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/original_data')
    plt.imshow(Image, origin='lower')
    plt.title('Original Data '+data_class.filename)
    plt.imsave('image_results/original_data/'+data_class.filename+'_original.png', Image)
    plt.close()
