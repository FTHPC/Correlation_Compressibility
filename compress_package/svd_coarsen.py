'''
svd_coarsen.py
global and local svd statistics are produced and plotted, if specified
coarsened resolution statistics are also produced
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
    X = data_class.data
    #look at the cumulative sum of the squared singular values, they give a proxy for the variance of the field X
    try:
        svd0_s = np.linalg.svd(X, compute_uv = False)
        ev0 = np.double(np.nancumsum((svd0_s**2))/np.nansum((svd0_s**2)))
        #pick a threshold to recover amount of the original variance (here 99%) and find the number of singular modes required to reach that threshold 
        # ev_threshold = np.nanmin(np.where(ev0 >= .99)) + 1
    except:
        svd0_s = None
        ev0 = None
        # ev_threshold = None
        plot = False

    n = X[0].shape[0]
 
    try:
        n100 = 100*((np.nanmin(np.where(ev0 >= 1))+1)/n).squeeze()
    except:
        n100 = 100
    try:
        n9999 = 100*((np.nanmin(np.where(ev0 >= .9999))+1)/n).squeeze()
        n999 = 100*((np.nanmin(np.where(ev0 >= .999))+1)/n).squeeze()
        n99 = 100*((np.nanmin(np.where(ev0 >= .99))+1)/n).squeeze()
    except:
        n9999 = None
        n999 = None
        n99 = None
        
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
            try:
                svdi_s= np.linalg.svd(X[((i-1)*H):(i*H),((j-1)*H):(j*H)], compute_uv = False)
                if np.nansum(np.abs(svdi_s)) > 0: 
                    evi = np.nancumsum((svdi_s**2))/np.nansum((svdi_s**2))
                    map_svdrk[i-1,j-1] = 100*((np.nanmin(np.where(evi>=lvar))+1)/H).squeeze()  # percentage  of singular modes to keep
                else:
                    map_svdrk[i-1,j-1] = None
            except:
                map_svdrk[i-1,j-1] = None
                print("WARNING: map_svdrk is NULL")
                
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
    measurements = {'stat:H'+str(H)+'_mean_singular_mode':np.nanmean(map_res), 
                    'stat:H'+str(H)+'_median_singular_mode':np.nanmedian(map_res), 
                    'stat:H'+str(H)+'_std_singular_mode':np.nanstd(map_res)}
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
    X = data_class.data
    for i, item in enumerate(H):
        map_res.append(map_svd_rank(X, H = item))
        measurements = {'stat:H'+str(item)+'_mean_singular_mode':np.nanmean(map_res[i]),
                        'stat:H'+str(item)+'_median_singular_mode':np.nanmedian(map_res[i]),
                        'stat:H'+str(item)+'_std_singular_mode':np.nanstd(map_res[i])}
        data_class.set_tiled_svd_measurements(measurements)
        if plot:
            K1 = X.shape[0]
            K2 = X.shape[1]
            try:
                plot_tiled(data_class, map_res[i], item, K1, K2)
            except:
                print('ERROR: could not plot tiled graphs. map_svd_rank is NULL')
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
    N = []
    res_list = [4, 8, 12, 16, 24, 32, 48, 64]
    dims = data_class.data.shape
    #dim1*dim2/resolution_tocheck^2 >= 16
    for res in res_list:
        #checks res list with to see if it fits the model
        if (dims[0]*dims[1])/res**2 >= 16:
            N.append(res)

    #this will store a list of coarsened data classes. The length = len(N)
    coarsened_data_classes = []
    #list of 2-d different sized matrices that store the coarsened data
    Xc = []

    X = data_class.data 
    # slice_data.create_folder(f"{data_class.dataset_temp_folder}")

    
    for i, item in enumerate(N):
        Xc.append(coarsen(X, N[i]))
        coarsen_data_measurements = {"stat:res"+str(N[i])+"_coarsen_std":np.std(Xc[i])}
        #occurs if variogram_study is set to True
        if variogram_study:
            try:
                vgm_coarsen=variogram.coarsen_multiple_resolution_variogram_study_addition(Xc[i])
            except:
                vgm_coarsen=None
            coarsen_variogram_measurements = {"stat:res"+str(N[i])+"_coarsen_variogram":vgm_coarsen} 

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