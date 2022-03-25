'''
variogram_study.py
computes a local and global variogram study on the data within 
the inputted data_class. 

specifics of the class are found in data_setup.py

functions:
    global_variogram_study(data_class, plot=False)
    local_variogram_study(data_class, plot=False)
    coarsen_variogram_study(data_class)
    coarsen_multiple_resolution_variogram_study_addition(X)
'''

import rpy2
import numpy as np
import rpy2.robjects as robjects
from rpy2.robjects import numpy2ri
from compress_package.convert import slice_data
from compress_package import svd_coarsen

# X is the 2D array you want to analyse
# you will need to install the package `gstat` with command 
#install.packages('gstat') 

'''
@type function
global variogram study on the inputted data class
inputs:
    data_class          : class storing the dataset and all metadata about it
    plot                : bool variable stating whether or not to plot
no return
'''
def global_variogram_study(data_class, plot=False):
    X = data_class.data
    var_name = data_class.filename
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/global_variogram')
    plot_r = 1 if plot == True else 0

    robjects.r(''' 
            global_variogram_study <- function(X, var_name, plot_res=1, slice=0){
                library('gstat')
                graphics.off()
                ## global variogram fitting
                n1 <- dim(X)[1]
                n2 <- dim(X)[2]
                xc <- rep(1:n1,each=n2)/n1
                yc <- rep(1:n2,n1)/n2
                df <- data.frame(v=c(X),x=xc,y=yc)
                vgm_emp <- variogram(v~x+y, locations = ~x + y, data = df)
                fit.vgm_gauss <- fit.variogram(vgm_emp, vgm(tail(vgm_emp$gamma,1), "Gau", 1/4))
  
                if(plot_res == 1){
                    fitted <- variogramLine(fit.vgm_gauss, maxdist=max(vgm_emp$dist), dist_vector=vgm_emp$dist)
                    filename1 <- paste('image_results/global_variogram/',var_name,'_fitted_global_variogram.png',sep='')
                    png(file = filename1, width = 500, height = 500)
                    plot(vgm_emp$dist, vgm_emp$gamma, pch=20, main=paste('Vx[,,',slice,'] - range:',round(fit.vgm_gauss$range[1],3)), ylab='Semi-variogram', xlab='Distance')
                    lines(fitted$dist,  fitted$gamma)
                    dev.off()
                }
                fit.vgm_gauss$range[1]
            }
            ''')
    #if the program doesn't need a slice, this means the data is already in 2-d
    #this is needed to make the titles on graphs correct
    if hasattr(data_class, 'slice'):  
        slice_needed = data_class.slice
    else:
        slice_needed = ' '
    
    global_variogram_study_call = robjects.r['global_variogram_study']
    numpy2ri.activate() 
    #program will fail on datasets that have no variance
    try:
        global_variogram = np.asarray(global_variogram_study_call(X, var_name, plot_res=plot_r, slice=slice_needed))[0]
       
    except:
        global_variogram = np.asarray(global_variogram_study_call(X, var_name, plot_res=False, slice=slice_needed))[0]
        print('ERROR: Could not plot local variogram study graphs\n')
    numpy2ri.deactivate()
    if global_variogram < 0:
        global_variogram = 'NA'
    data_class.set_global_variogram_fitting(global_variogram)
'''
@type function
local variogram study on the inputted data class
inputs:
    data_class          : class storing the dataset and all metadata about it
    plot                : bool variable stating whether or not to plot
no return
'''
def local_variogram_study(data_class, plot=False):
    X = data_class.data
    var_name = data_class.filename
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/local_variogram')
    plot_r = 1 if plot == True else 0

    dims = X.shape
    if dims[0] >= 2048:
        X = svd_coarsen.coarsen(X, int(dims[0]/1024))

    robjects.r(''' 
            local_variogram_study <- function(X, var_name, plot_res=1){ 
                library('gstat')
                graphics.off()
                ## local variogram fitting through tiling 
                H <- c(8,16,32)
                K1 <- dim(X)[1]
                K2 <- dim(X)[2]
                map_vgm_range <- NULL
                for (h in 1:length(H)){
                    xc <- rep(1:H[h],each=H[h])/H[h]
                    yc <- rep(1:H[h],H[h])/H[h]
                    map_vgm_int <- matrix(0,floor(K1/H[h]),floor(K2/H[h]))
                    for (i in 1:(K1/H[h])){
                        for (j in 1:(K2/H[h])){
                            v <- c(X[(1+(i-1)*H[h]):(i*H[h]),(1+(j-1)*H[h]):(j*H[h])])
                            df <- data.frame(v=v,x=xc,y=yc)
                            vg <- variogram(v~x+y, locations = ~x + y, data = df)
                            fit.sph <- fit.variogram(vg, vgm(tail(vg$gamma,1), "Gau", 1/4))
                            map_vgm_int[i,j] <- fit.sph$range[1]    
                        }
                    }
                    map_vgm_range[[h]] <- map_vgm_int  
                } 
                
                if (plot_res==1){  
                    graphics.off()
                    filename2 <- paste('image_results/local_variogram/',var_name,'_histogram_tiled_variogram.png',sep='')
                    png(file = filename2, width = 1000, height = 400)
                    layout(matrix(1:3,1,3))
                    xbrks <- seq(min(unlist(map_vgm_range)), max(unlist(map_vgm_range)), length.out=20)
                    for (h in 1:length(H)){
                        hist(map_vgm_range[[h]], main=paste('Tiled-variograms ranges - H=', H[h], sep=''), breaks = xbrks, xlab='Variogram range')
                    }
                    dev.off()
                }
            return <- list(H, map_vgm_range[])
            }
            ''')
    numpy2ri.activate()
    local_variogram_study_call = robjects.r['local_variogram_study']
    #program will fail on data slices that have no variance 
    measurements = {}
    try:
        output = np.asarray(local_variogram_study_call(X, var_name, plot_res=plot_r), dtype=object)
        H_values = output[0]
        for i, value in enumerate(H_values):
            measurements.update({'stat:H'+str(int(value))+'_avg_local_variogram':np.mean(np.asarray(output[1][i])),
                                 'stat:H'+str(int(value))+'_std_local_variogram':np.std(np.asarray(output[1][i]))    
                                })
    except:
        try:
            output = np.asarray(local_variogram_study_call(X, var_name, plot_res=False), dtype=object)
            print('ERROR: Could not plot local variogram study graphs\n')        
            H_values = output[0]
            for i, value in enumerate(H_values):
                measurements.update({'stat:H'+str(int(value))+'_avg_local_variogram':np.mean(np.asarray(output[1][i])),
                                     'stat:H'+str(int(value))+'_std_local_variogram':np.std(np.asarray(output[1][i]))    
                                    })
        except:
            print('ERROR: Could not compute local variogram study\n')
    data_class.set_local_variogram_measurements(measurements)
    numpy2ri.deactivate()



'''
@type function
coarsened variogram study on the inputted data class
inputs:
    data_class          : class storing the dataset and all metadata about it
no return
'''
def coarsen_variogram_study(data_class):
    X = data_class.data
    # coarsen the data for various resolution grain N
    res_list = [4, 8, 12, 16, 24, 32, 48, 64]
    N = []

    dims = X.shape
    if dims[0] >= 2048:
        X = svd_coarsen.coarsen(X, int(dims[0]/1024))

    #dim1*dim2/resolution_tocheck^2 >= 16
    for res in res_list:
        #checks res list with to see if it fits the model
        if (dims[0]*dims[1])/res**2 >= 16:
            N.append(res)

    robjects.r(''' 
        coarsened_variogram_study <- function(X, N){ 
            library('gstat')
            graphics.off()
            coarsen <- function(X,nx){
                d <- dim(X)
                dx <- floor(d[1]/nx)
                dy <- floor(d[2]/nx)
                x <- array(0,c(dx,dy))
                for (i in 1:dx){
                    for (j in 1:dy){
                        x[i,j] <- mean(X[(1+(i-1)*nx):(i*nx),(1+(j-1)*nx):(j*nx)],na.rm=TRUE) 
                    }
                }
                x 
            }  
            vgm_coarsen <- c()
            for (j in 1:length(N)){
                xi <- coarsen(X,N[[j]][1])
                n1 <- dim(xi)[1]
                n2 <- dim(xi)[2]
                v <- c(xi[1:n1,1:n2])
                x <- rep(1:n1,each=n2)/n1
                y <- rep(1:n2,n1)/n2
                df <- data.frame(v=v,x=x,y=y)
                vg <- variogram(v~x+y, locations = ~x + y, data = df)
                fit.sph <- fit.variogram(vg, vgm(tail(vg$gamma,1), "Gau", 1/4)) 
                vgm_coarsen[j] <- fit.sph$range[1]
            }
        return <- vgm_coarsen
        }
            ''')

    coarsen_variogram_study_call = robjects.r['coarsened_variogram_study']
    numpy2ri.activate() 
    #program will fail on datasets that have no variance

    output = np.asarray(coarsen_variogram_study_call(X, N))
    measurements = {}
    for i, value in enumerate(N):
        measurements.update({'stat:res'+str(int(value))+'coarsen_variogram':output[i]})
    data_class.set_coarsened_variogram_measurements(measurements)
    numpy2ri.deactivate()

'''
@type function
coarsened variogram study on the inputted coarsened matrix
inputs:
    X          : matrix resulting from svd_coarsen.coarsen()
returns : the resulted variogram study for the inputted coarsened matrix
'''
def coarsen_multiple_resolution_variogram_study_addition(X):

    robjects.r(''' 
        coarsened_variogram_study <- function(X){ 
            library('gstat')
            graphics.off()
            n1 <- dim(X)[1]
            n2 <- dim(X)[2]
            v <- c(X[1:n1,1:n2])
            x <- rep(1:n1,each=n2)/n1
            y <- rep(1:n2,n1)/n2
            df <- data.frame(v=v,x=x,y=y)
            vg <- variogram(v~x+y, locations = ~x + y, data = df)
            fit.sph <- fit.variogram(vg, vgm(tail(vg$gamma,1), "Gau", 1/4)) 
            vgm_coarsen <- fit.sph$range[1]
        return <- vgm_coarsen  
        }
            ''')

    coarsen_variogram_study_call = robjects.r['coarsened_variogram_study']
    numpy2ri.activate() 
    #program will fail on datasets that have no variance
    vgm_coarsen = np.asarray(coarsen_variogram_study_call(X))[0]
    numpy2ri.deactivate()
    return vgm_coarsen
