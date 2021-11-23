'''
svd_coarsen.py
global and local svd statistics are produced and plotted, if specified
coarsened resolution statistics are also produced

functions:
    global_svd(data_class, plot = False)
    map_svd_rank(X, H=16, lvar=0.99)
    tiled_singular(data_class, H = 16, plot = False)
    tiled_multiple(data_class, plot = False)
    plot_tiled(data_class, map_res, H, K1, K2)
    coarsen(X, N)
    coarsen_multiple_resolution(data_class, new_data_classes = False, plot = False)
    plot_resolution(data_class, N)
'''
import pathlib
import numpy as np
import matplotlib.pyplot as plt
from os.path import splitext
#custom packages
import compress_package.data_setup as setup
import compress_package.variogram_study as variogram
from compress_package.convert import slice_data

'''
@type function
global svd threshold statistics based on the data stored within the data_class
SVD composition as shown in Figure 5
inputs:
    data_class          : class storing the dataset and all metadata about it
    plot                : bool variable stating whether or not to plot
no return, global_svd_measurements are updated
'''
def global_svd(data_class, plot = False):
    #if want u, s, and v - use the line below:
    #svd_res_u, svd_res_s, svd_res_v = np.linalg.svd(Vx)
    #saves memory just storing 1 array
    X = data_class.data
    svd0_s = np.linalg.svd(X, compute_uv = False)

    #look at the cumulative sum of the squared singular values, they give a proxy for the variance of the field X
    ev0 = np.double(np.cumsum((svd0_s**2))/np.sum((svd0_s**2)))

    #pick a threshold to recover amount of the original variance (here 99%) and find the number of singular modes required to reach that threshold 
    ev_threshold = np.min(np.where(ev0 >= .99)) + 1

    n = X[0].shape[0]
 
    try:
        n100 = 100*((np.min(np.where(ev0 >= 1))+1)/n).squeeze()
    except:
        n100 = 100
    n9999 = 100*((np.min(np.where(ev0 >= .9999))+1)/n).squeeze()
    n999 = 100*((np.min(np.where(ev0 >= .999))+1)/n).squeeze()
    n99 = 100*((np.min(np.where(ev0 >= .99))+1)/n).squeeze()

    thresholds = {'stat:n100':n100, 'stat:n9999':n9999, 'stat:n999': n999, 'stat:n99': n99}
    data_class.set_global_svd_measurements(thresholds)
    
    if plot:
        plot_slice = data_class.slice if hasattr(data_class, 'slice') == True else ' '
        #plot the sum of the squared singular values
        fig, ax = plt.subplots()
        ax.plot(ev0)
        ax.set(xlabel='Index', ylabel='Squared singular values cumsum',
            title='Vx[,,'+str(plot_slice)+'] - Cumulative sum of squared singular values')
        #legend = ax.legend(loc='lower right', shadow=True, fontsize='large')
        slice_data.create_folder('image_results')
        slice_data.create_folder('image_results/cumulative_sum_squared_singular')
        plt.savefig('image_results/cumulative_sum_squared_singular/'+data_class.filename+'_singular.png',facecolor='w', edgecolor='w')
        plt.close()

'''
@type function
tiled-SVD - the 2D image is tiled into sub-windows of size H*H in which an SVD is performed (local understanding)
Figure 10 in overleaf
inputs:
    X                   : 2D matrix of data
    H                   : size of the tile - typically we have used (H=8, 16, 32, 64), default=16
    lvar                : variance of data, default=.99
returns : the calculated mapped svd rank
'''
def map_svd_rank(X, H=16, lvar=0.99):
    K1 = X.shape[0]
    K2 = X.shape[1]
    # matrix with entries corresponding to the percentage of required singular modes to reach 99% of the variance in each tile
    map_svdrk =  np.empty((int(K1/H),int(K2/H)))

    for i in range(1, int(K1/H)+1):
        for j in range(1, int(K2/H)+1):
            svdi_s= np.linalg.svd(X[((i-1)*H):(i*H),((j-1)*H):(j*H)], compute_uv = False)
            evi = np.cumsum((svdi_s**2))/np.sum((svdi_s**2))
            map_svdrk[i-1,j-1] = 100*((np.min(np.where(evi>=lvar))+1)/H).squeeze()  # percentage  of singular modes to keep
    return map_svdrk
'''
@type function
Uses map_svd_rank to tile a dataset with a singular size 
inputs:
    data_class          : class storing the dataset and all metadata about it
    H                   : size of the tile - typically we have used (H=8, 16, 32, 64), default=16
    plot                : bool variable stating whether or not to plot
no return, sets tiled_svd_measurments
'''
def tiled_singular(data_class, H = 16, plot = False):
    X = data_class.data
    map_res = map_svd_rank(X)
    #plot tiled sub-windows
    measurements = {'stat:H'+str(H)+'_mean_singular_mode':np.mean(map_res), 
                    'stat:H'+str(H)+'_median_singular_mode':np.median(map_res), 
                    'stat:H'+str(H)+'_std_singular_mode':np.std(map_res)}
    data_class.set_tiled_svd_measurements(measurements)


    if plot:
        K1 = X.shape[0]
        K2 = X.shape[1]
        plot_tiled(map_res, H, K1, K2)
'''
@type function
Uses map_svd_rank to tile a dataset with multiple sizes
inputs:
    data_class          : class storing the dataset and all metadata about it
    plot                : bool variable stating whether or not to plot
no return, sets tiled_svd_measurments
'''
def tiled_multiple(data_class, plot = False):
    #A list of multiple 2-d arrays based on the size of the tiles
    H = [8,16,32,64]
    map_res=[]
    tiled_data=[]
    X = data_class.data
    for i, item in enumerate(H):
        map_res.append(map_svd_rank(X, H = item))
        measurements = {'stat:H'+str(item)+'_mean_singular_mode':np.mean(map_res[i]),
                        'stat:H'+str(item)+'_median_singular_mode':np.median(map_res[i]),
                        'stat:H'+str(item)+'_std_singular_mode':np.std(map_res[i])}
        data_class.set_tiled_svd_measurements(measurements)
        if plot:
            K1 = X.shape[0]
            K2 = X.shape[1]
            plot_tiled(data_class, map_res[i], item, K1, K2)
'''
@type function
plots the 2D local tiled SVD graphs calculated by the map_svd_rank
inputs:
    data_class          : class storing the dataset and all metadata about it
    map_res             : the return value from map_svd_rank
    H                   : size of the tile - typically we have used (H=8, 16, 32, 64), default=16
    K1                  : data.shape[0] (1st dimension shape of data)
    K2                  : data.shape[1] (2nd dimension shape of data)
no return, plots tiled svd plots
'''
def plot_tiled(data_class, map_res, H, K1, K2):
    plt.hist(map_res)
    plt.title('% of needed singular modes with H='+str(H))
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/percentage_singular_modes')
    plt.savefig('image_results/percentage_singular_modes/'+data_class.filename+'_percent_singular_H_'+str(H)+'.png',facecolor='w', edgecolor='w')
    plt.close()
    #this is the tiled plots that currently don't work at all

    #plot tiled sub-windows
    #plt.imshow(np.transpose(X), origin='lower')
    #plt.title('Vx[,,100] - H='+str(H))
    #plt.text(x=rep(seq((H/2),K1,by=H),(K1/H)),y=rep(seq((H/2),K2,by=H),each=(K2/H)), labels=c(round(map_res)),cex=.4)
    #plt.imsave('image_results/Tiled_SVD_Data.png', np.transpose(X))

'''
@type function
data coarsening and its statistics - here we coarsen the data to look at different scales of 
them and compute statistics of its coarsened version. 
inputs:
    X                   : 2D matrix of data
    N                   : the resolution to be coarsened to
returns : the coarsened matrix 
'''
def coarsen(X, N):
    d = X.shape
    dx = int(d[0]/N)
    dy = int(d[1]/N)
    x = np.empty((dx,dy))
    for i in range(1,dx+1):
        for j in range(1,dy+1):
            x[i-1,j-1] = np.mean(X[((i-1)*N):(i*N),((j-1)*N):(j*N)])
    return x

'''
@type function
Handles multiple resultions. Will find the std of the newly created coarsened data block. 
Options to store each coarsened data set in a new data class. Otherwise, the coarsened measurments 
will append to the coarsened_attributes attribute of the class. 
inputs:
    data_class          : class storing the dataset and all metadata about it
    new_data_classes    : bool that determines to create new data classes for each coarsened resolution
    plot                : bool variable stating whether or not to plot
    variogram_study     : bool variable that determines whether or not to do a coarsened variogram study
returns : if new_data_classes is True, a list of coarsened data classes 
          
'''
def coarsen_multiple_resolution(data_class, new_data_classes = False, plot = False, variogram_study = False):
    # coarsen the data for various resolution grain N
    res_list = [4, 8, 12, 16, 24, 32, 48, 64]
    N = []
    dims = data_class.data.shape
    #dim1*dim2/resolution_tocheck^2 >= 16
    for res in res_list:
        #checks res list with to see if it fits the model
        if (dims[0]*dims[1])/res**2 >= 16:
            N.append(res)

    # a list of standard deviations of each resolution 
    sd1 = np.empty(len(N))

    #this will store a list of coarsened data classes. The length = len(N)
    coarsened_data_classes = []
    #list of 2-d different sized matrices that store the coarsened data
    Xc = []

    X = data_class.data 
    slice_data.create_folder(f"{data_class.dataset_temp_folder}")
    # decompressed_data_path = data_class.full_sliced_file_path
    
    for i, item in enumerate(N):
        Xc.append(coarsen(X, N[i]))
        coarsen_data_measurements = {"stat:res"+str(N[i])+"_coarsen_std":np.std(Xc[i])}
        #occurs if variogram_study is set to True
        if variogram_study:
            vgm_coarsen=variogram.coarsen_multiple_resolution_variogram_study_addition(Xc[i])
            coarsen_variogram_measurements = {"stat:res"+str(N[i])+"_coarsen_variogram":vgm_coarsen} 

        #this will create new classes with each coarsened resolution as a new data file. this will allow one entry within the data_class.coarsened_attributes 
        #per each class created. Creating the classes will allow the information to be manipulated later (ex: sz or other methods)
        if new_data_classes:
            coarsened_data_classes.append(setup.data(data_class.global_data))
            binary_filename = str(splitext(splitext(data_class.filename)[0])[0])+"_coarse_data_res_"+str(N[i])
            coarse_dataset_name = binary_filename+".dat"
            coarse_filename = coarse_dataset_name+".h5" 
            coarse_full_path = slice_data.custom_slice(Xc[i], binary_filename, coarse_dataset_name, data_class.dataset_directory, data_class.temp_folder, data_class.dtype)

            #sets attributes of new class
            #for each coarsened resolution, a new class will be created.
            coarsened_data_classes[i].setup_slice(coarse_filename, coarse_dataset_name, data_class.temp_folder, coarse_full_path, Xc[i].shape, data_class.dtype)
            coarsened_data_classes[i].set_data(Xc[i])
            #setup coarsened_attributes
            #coarsen_ratio = setup.slice_compression_ratio(coarsened_data_classes[i], decompressed_data_path)
            coarsened_data_classes[i].set_coarsened_attributes(coarsen_data_measurements)
            if variogram_study:
                coarsened_data_classes[i].set_coarsened_variogram_measurements(coarsen_variogram_measurements)
            if plot:
                plot_resolution(coarsened_data_classes[i], N[i])
        #if new_data_classes is False, the data will not be stored, only stats of the coarsened matrices will be calculated
        #results in multiple entries within the dictionary data_class.coarsened_attributes with each entry containing the 
        #standard deviation. Also data_class.coarsened_variogram_measurements will store the coarsened variogram study metrics
        else:
            data_class.set_coarsened_attributes(coarsen_data_measurements)
            coarsened_data_classes.append(data_class)
            #occurs if variogram_study is set to True
            if variogram_study:
                data_class.set_coarsened_variogram_measurements(coarsen_variogram_measurements)
            if plot:
                plot_resolution(data_class, N[i])

    return coarsened_data_classes

'''
@type function
plots the coarsened resolution files that were 
inputs:
    data_class          : class storing the dataset and all metadata about it
    N                   : the resolution to be coarsened to
no return, saves plot files
'''
def plot_resolution(data_class, N):
    # displays the coarsened data set
    X = np.transpose(data_class.data)
    plt.imshow(X, origin='lower')
    plt.title('Coarsen Resolution Grain ' + str(N))
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/coarsened_data_visuals')
    plt.imsave('image_results/coarsened_data_visuals/res_'+str(N)+'_'+data_class.filename+'.png', X)
    plt.close()