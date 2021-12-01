'''
data_plot.py
Visualization file of the data. This will graph different relationships found in the
computed metrics. Some of the questions answered:
    How compression ratios relate to the overall correlation range?
    How compression ratios relate to local correlation ranges?

functions (public):
    original_data(data_class)
    sdrbench_comparison(sample_data_classes, fit='log')
    gaussian_comparison(sample_data_classes, K_points, multi_gaussian = True, fit = 'log')
functions (private):
    _set_variable(gaussian)
    _update_variable_storage(gaussian, bounds, bound_title, loc, legend_slices, independent_names, dependent_names)

'''
from compress_package.convert import slice_data
import matplotlib.pyplot as plt
import numpy as np
import itertools

#CHANGE HERE TO CHANGE VARIABLES
















'''
@type private function

setups all the variables to be graphed
inputs: gaussian                    : bool determine if gaussian 

'''
def _set_variable(gaussian):
    independent_names = ["info:a_range"] if gaussian else []
    independent_names.extend([
        "stat:global_variogram",
        "stat:n99",
        "stat:H16_std_singular_mode",
        "stat:H16_mean_singular_mode",
        "stat:H16_std_local_variogram",
        "stat:H16_avg_local_variogram",
        "stat:H32_std_singular_mode",
        "stat:H32_mean_singular_mode",
        "stat:H32_std_local_variogram",
        "stat:H32_avg_local_variogram",
    ])
    #must be in the same order
    independent_labels = ["Smoothness Correlation Range"] if gaussian else []
    independent_labels.extend([
        "Estimated global variogram range",
        "SVD truncation level for 99% of variance",
        "Std of truncation level of local SVD (H=16)",
        "Mean truncation level of local SVD (H=16)",
        "Std of estimated of local variogram range (H=16)",
        "Mean of estimated of local variogram range (H=16)",
        "Std of truncation level of local SVD (H=32)",
        "Mean truncation level of local SVD (H=32)",
        "Std of estimated of local variogram range (H=32)",
        "Mean of estimated of local variogram range (H=32)",
    ])
    dependent_names = [
        "error_stat:ssim",
        "error_stat:psnr",
        "size:compression_ratio",
        "error_stat:mse",
        "error_stat:value_range"
    ]
    dependent_labels = [
        "SSIM",
        "PSNR",
        "Compression Ratio",
        "Mean Square Error",
        "Value Range"
    ]
    return independent_names, independent_labels, dependent_names, dependent_labels

def _update_variable_storage(
    gaussian, bounds, bound_title, loc, legend_slices, independent_names, dependent_names):
    for bound in bounds:
        if not bound in legend_slices:
            names = {'info:k_points':[]} if gaussian else {}
            names_list = independent_names + dependent_names
            for each in names_list:
                names.update({each:[]})
            legend_slices.update({bound:names})   
        loc_comp = loc.compression_measurements.get(bound)
        bound_title.append(str(loc_comp.get('info:compressor'))+'_'+str(loc_comp.get('info:bound')))
        legend_slices[bound]['size:compression_ratio'].append(loc_comp.get('size:compression_ratio')) 
        legend_slices[bound]['error_stat:psnr'].append(loc_comp.get('error_stat:psnr'))
        legend_slices[bound]['error_stat:ssim'].append(loc_comp.get('error_stat:ssim'))
        legend_slices[bound]['error_stat:mse'].append(loc_comp.get('error_stat:mse'))
        legend_slices[bound]['error_stat:value_range'].append(loc_comp.get('error_stat:value_range'))
        if gaussian:
            legend_slices[bound]['info:k_points'].append(loc.gaussian_attributes.get('info:k_points'))
            if 'info:a_range_secondary' in loc.gaussian_attributes: 
                if loc.gaussian_attributes.get('info:a_range') > loc.gaussian_attributes.get('info:a_range_secondary'):
                    a_value = loc.gaussian_attributes.get('info:a_range')
                else:
                    a_value = loc.gaussian_attributes.get('info:a_range_secondary')
                legend_slices[bound]['info:a_range'].append(a_value)
            else:   
                legend_slices[bound]['info:a_range'].append(loc.gaussian_attributes.get('info:a_range'))

        variogram_append = loc.global_variogram_fitting if hasattr(loc, 'stat:global_variogram_fitting') else 'NA'
        legend_slices[bound]['stat:global_variogram'].append(variogram_append)   
        legend_slices[bound]['stat:n99'].append(loc.global_svd_measurements.get('stat:n99'))

        for mode in ['stat:H16_std_singular_mode', 'stat:H16_mean_singular_mode', 'stat:H32_std_singular_mode', 'stat:H32_mean_singular_mode']:
            legend_slices[bound][mode].append(loc.tiled_svd_measurements.get(mode))
        for mode in ['stat:H16_std_local_variogram', 'stat:H16_avg_local_variogram', 'stat:H32_std_local_variogram', 'stat:H32_avg_local_variogram']:
            legend_slices[bound][mode].append(loc.local_variogram_measurements.get(mode)) 



#STOP CHANGES
'''
@type function 
sdrbench_comparison

inputs:
    sample_data_classes             : The list of classes that contains information about each slice
    fit                             : Fit of the linear trend within the graphs generated. Either 'log' or 'linear'
    separate_by_file                : boolean varaible 
returns: nothing
'''
def sdrbench_comparison(sample_data_classes, fit='log', separate_by_file=True):
    independent_names, independent_labels, dependent_names, dependent_labels = _set_variable(gaussian=False)
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/sdrbench_comparisons')

    sorted_classes = {}
    reduced_filename_store = []
    #puts all the slices together
    for data_class in sample_data_classes:
        #only obtain classes with a slice
        if not hasattr(data_class, 'slice'):  
            continue
        #get filename without the slice addition
        # reduced_filename = data_class.filename.split('_slice')[0]
        reduced_filename = data_class.filename.split('_slice')[0] + data_class.filename.split('_slice')[1].split('_')[2].split('.dat')[0]
        #set dataset folder name
        # folder_name = data_class.data_folder
        folder_name = 'SDRBENCH-Miranda-256x384x384'
        #check slice, will skip slice if the std of the slice is lower than the threshold.
        if data_class.stat_methods.get('stat:res4_coarsen_std') > 1e-02:
            if not separate_by_file:
                reduced_filename = folder_name
        
            if reduced_filename in sorted_classes:
                sorted_classes[reduced_filename].append(data_class)
                
            else:
                sorted_classes.update({reduced_filename : []})
                sorted_classes[reduced_filename].append(data_class)
                reduced_filename_store.append(reduced_filename)
    

    #for each dataset 
    for i, keys in enumerate(sorted_classes):
        legend_slices = {}

        bounds = []
        #update bounds for the sorted class
        for key in sorted_classes.get(keys)[0].compression_measurements:
            bounds.append(key)
        #update independent and dependent variables for the given bound
        for sliced in range(len(sorted_classes.get(keys))):
            bound_title = []
            loc = sorted_classes.get(keys)[sliced]
            _update_variable_storage(False, bounds, bound_title, loc, legend_slices, independent_names, dependent_names)

        _plot_private(False, False, fit, legend_slices, bounds, independent_names, independent_labels, 
                    dependent_names, dependent_labels, i, reduced_filename_store)

'''
@type function 
gaussian_comparison

inputs:
    sample_data_classes             : The list of classes that contains information about each slice
    K_points                        : 1D size of the generated Gaussian dataset 'K'
    multi_gaussian                  : boolean that determines if the datasets presented had multi correlation ranges
    fit                             : Fit of the linear trend within the graphs generated. Either 'log' or 'linear'
returns: nothing
'''
def gaussian_comparison(sample_data_classes, K_points, multi_gaussian=True, fit = 'log'):
    independent_names, independent_labels, dependent_names, dependent_labels = _set_variable(gaussian=True)
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/gaussian_comparisons')
    sorted_classes = {}
    reduced_filename_store = []
    #puts all the slices together
    for data_class in sample_data_classes:
        #only obtain gaussian classes
        if not hasattr(data_class, 'gaussian_attributes'):  
            continue
        if multi_gaussian and not 'info:a_range_secondary' in data_class.gaussian_attributes:
            continue
        elif not multi_gaussian and 'info:a_range_secondary' in data_class.gaussian_attributes:
            continue
        #get filename without the slice addition
        reduced_filename = data_class.filename.split('_Sample')[0] 
        if data_class.gaussian_attributes.get('info:k_points') != K_points:
            continue
        if data_class.stat_methods.get('stat:res4_coarsen_std') > 1e-02:
            if reduced_filename in sorted_classes:
                sorted_classes[reduced_filename].append(data_class)
            else:
                sorted_classes.update({reduced_filename : []})
                sorted_classes[reduced_filename].append(data_class)
                reduced_filename_store.append(reduced_filename)
          
    legend_slices   = {}
    # stats_sample  = {'H8_svd_H8_avg':[],'H16_svd_H16_avg':[],'H32_svd_H32_avg':[],'H64_svd_H64_avg':[],
    #                  'n100':[],'n9999':[],'n999':[],'n99':[],'K_points':[], 'a_range':[]}
    for i, keys in enumerate(sorted_classes):
        bounds = []
        #The a is the same for all the samples
        for key in sorted_classes.get(keys)[0].compression_measurements:
            bounds.append(key)
        sample_length = len(sorted_classes.get(keys))
        for sample in range(sample_length):
            bound_title = []
            loc = sorted_classes.get(keys)[sample] 
            #these are affected by different bounds and compressors
            _update_variable_storage(True, bounds, bound_title, loc, legend_slices, independent_names, dependent_names)


    #plot function
    _plot_private(True, multi_gaussian, fit, legend_slices, bounds, independent_names, 
                independent_labels, dependent_names, dependent_labels, 0, reduced_filename_store)


'''
@type function
Elimates empty data for independent and dependent variables.
This removes any values that are infinity, negative, empty, or nan
'''
def _clean_data(legend_slices, bounds, independent_names, each_ind, each_dep):
    for bound in bounds:
        index_ind = 0
        index_dep = 0
        
        #check independents
        data_ind = legend_slices[bound][each_ind]
        data_dep = legend_slices[bound][each_dep]
        for number in range(len(data_dep)):
            if (data_ind[index_ind] == 'NA' or data_ind[index_ind] == '' or
                data_ind[index_ind] <= 0 or np.isnan(data_ind[index_ind]) or  
                np.isinf(data_ind[index_ind])):
                data_dep.pop(index_ind)
                for each in independent_names:
                    legend_slices[bound][each].pop(index_ind)

                # legend_slices[bound]['slice'].pop(index_ind)
                index_ind -=1
            index_ind +=1
            if index_ind >= len(data_ind):
                break
        #check dependents
        for number in range(len(data_dep)):
            if (data_dep[index_dep] == 'NA' or data_dep[index_dep] == '' or 
                data_dep[index_dep] <= 0 or np.isinf(data_dep[index_dep]) or 
                np.isnan(data_dep[index_dep])):
                data_dep.pop(index_dep)
                for each in independent_names:
                    legend_slices[bound][each].pop(index_dep)
                # legend_slices[bound]['slice'].pop(index_dep)
                index_dep -=1
            index_dep +=1
            if index_dep >= len(data_dep):
                break
            
'''
@type function
private used to plot the slices 
'''
def _plot_private(
    gaussian:bool,          #  
    multi_gaussian:bool,    #
    fit:str,                #
    legend_slices,          #
    bounds,                 #
    independent_names,      #
    independent_labels,     #
    dependent_names,        #
    dependent_labels,       #
    filename_iteration,     #
    reduced_filename_store  #
    ):

    font = {'family' : 'normal',
            'weight' : 'bold',}

    plt.rc('font', **font)
    SMALL = 12
    MEDIUM = 14
    BIGGER = 16

    plt.rc('font', size=MEDIUM)
    plt.rc('axes', titlesize=BIGGER)    
    plt.rc('axes', labelsize=BIGGER)     
    plt.rc('xtick', labelsize=MEDIUM)  
    plt.rc('ytick', labelsize=MEDIUM) 
    plt.rc('legend', fontsize=SMALL, columnspacing = .5, handlelength = 1.0)
    plt.rc('figure', titlesize=BIGGER)
    #copies original data in order to reset stored variables
    og_dep = []
    og_ind = []
    for dep, bound in itertools.product(dependent_names, bounds):
        og_dep.append(legend_slices[bound][dep].copy())

    for ind, bound in itertools.product(independent_names, bounds):
        og_ind.append(legend_slices[bound][ind].copy())

    #plots the data
    #each loop is relatively small so the loopception shouldn't be an issue
    for count_ind, each_ind in enumerate(independent_names): 
        for count_dep, each_dep in enumerate(dependent_names):
            #resets independent and dependent data lists
            index = 0
            for dep, bound in itertools.product(dependent_names, bounds):
                legend_slices[bound][dep] = og_dep[index].copy() 
                index += 1     
            index = 0
            for ind, bound in itertools.product(independent_names, bounds):
                legend_slices[bound][ind] = og_ind[index].copy() 
                index += 1     

            _clean_data(legend_slices, bounds, independent_names, each_ind, each_dep)

            #each_dep compressor has own file
            plts = {}
            created = 0
            pre_compressor = None
            compressor_list, numerical_bound_list, x_values, y_values = ([] for k in range(4))
     
            for j, bound in enumerate(bounds):
                #points were removed due to being outliers. If there are less <=2 points - a graph will not be exported

                compressor = None
                if len(legend_slices[bound][each_ind]) > 2 and len(legend_slices[bound][each_dep]) > 2:
                    compressor = bound.split('_bound_')[0]
                    numerical_bound = bound.split('_bound_')[1]
                    if pre_compressor != compressor: 
                        plts.update({compressor:[]})
                        compressor_list.append(compressor)

                    #if plot needed and next compressor not equal current compressor
                    try:
                        next_compressor = bounds[j+1].split('_bound_')[0]
                    except:
                        next_compressor = 'NA'

                    plts[compressor].append(plt.scatter(legend_slices[bound][each_ind], legend_slices[bound][each_dep], s=32, marker='o'))
                    x_values.append(legend_slices[bound][each_ind])
                    y_values.append(legend_slices[bound][each_dep])
                    numerical_bound_list.append(numerical_bound)

                    if pre_compressor == compressor and next_compressor != compressor:
                        plt.title(f"{compressor_list[created]}")   
                        plt.xlabel(f'{independent_labels[count_ind]}')
                        plt.ylabel(f'{dependent_labels[count_dep]}')

                        linear_model = []
                        for pos, value in enumerate(x_values):
                            if fit=='log':
                                linear_model.append(np.polyfit(np.log10(value),y_values[pos],1))
                                linear_model_fn=np.poly1d(linear_model[pos])
                                x_s=np.arange(.9*np.min(value),np.max(value),(np.max(value)-np.min(value))/100)
                                plt.plot(x_s,linear_model_fn(np.log10(x_s)))
                            elif fit=='linear':
                                linear_model.append(np.polyfit(value,y_values[pos],1))
                                linear_model_fn=np.poly1d(linear_model[pos])
                                x_s=np.arange(.9*np.min(value),np.max(value),(np.max(value)-np.min(value))/100)
                                plt.plot(x_s,linear_model_fn(x_s))

                        plt.xlim(.5*np.min(min(x_values)), 1.1*np.max(max(x_values)))
                        plt.ylim(0.5*np.min(min(y_values)), 1.4*np.max(max(y_values)))
                        legend_list = []
                        for pos, num_bound in enumerate(numerical_bound_list):
                            legend_list.append(str(num_bound)+' '+str(np.round(linear_model[pos], decimals=2)))
                        plt.legend(plts[pre_compressor], legend_list, loc="upper center", ncol=2, labelspacing=0.05, frameon=False)
                        plt.tight_layout()
                        if gaussian:
                            multi = '_multi' if multi_gaussian else ''
                            plt.savefig('image_results/gaussian_comparisons/gaussian'+multi+'_'+str(legend_slices[bound]['info:k_points'][0])+'_'+
                            compressor_list[created]+'_'+each_ind+'_'+each_dep+'_correl_'+fit+'.png',facecolor='w', edgecolor='w')
                        else:
                            plt.savefig('image_results/sdrbench_comparisons/'+str(reduced_filename_store[filename_iteration])+'_'+compressor_list[created]+
                            '_'+each_ind+'_'+each_dep+'_correl_'+fit+'.png',facecolor='w', edgecolor='w')
                        plt.close()    
                        created += 1
                        #only resets after graphing
                        numerical_bound_list, x_values, y_values = ([] for listed in range(3))
                pre_compressor = compressor


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
