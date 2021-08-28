'''
data_plot.py
Visualization file of the data. This will graph different relationships found in the
computed metrics. Some of the questions answered:
    How compression ratios relate to the overall correlation range?
    How compression ratios relate to local correlation ranges?

functions:
    original_data(data_class)
    sdrbench_comparison(sample_data_classes, fit='log')
    gaussian_comparison(sample_data_classes, K_points, multi_gaussian = True, fit = 'log')
'''
from compress_package.convert import slice_data
import matplotlib.pyplot as plt
import numpy as np
import itertools

def original_data(data_class):
    #displays the original data set
    Image = np.transpose(data_class.data )
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/original_data')
    plt.imshow(Image, origin='lower')
    plt.title('Original Data '+data_class.filename)
    plt.imsave('image_results/original_data/'+data_class.filename+'_original.png', Image)
    plt.close()

def set_variables(gaussian):
    independent_names = ["a_range"] if gaussian else []
    independent_names.extend(["global_variogram","n99","H16_std_singular_mode","H16_mean_singular_mode","H16_std_local_variogram",
                         "H16_avg_local_variogram","H32_std_singular_mode","H32_mean_singular_mode","H32_std_local_variogram","H32_avg_local_variogram",])
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
    dependent_names = ["ssim","psnr","compression_ratio"]
    dependent_labels = [
        "SSIM",
        "PSNR",
        "Compression Ratio"
    ]
    return independent_names, independent_labels, dependent_names, dependent_labels

def sdrbench_comparison(sample_data_classes, fit='log'):
    independent_names, independent_labels, dependent_names, dependent_labels = set_variables(gaussian=False)
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
        reduced_filename = data_class.filename.split('_slice')[0] 
        if reduced_filename in sorted_classes:
            #check slice, will skip slice if the std of the slice is lower than the threshold.
            if data_class.coarsened_attributes.get('resolution_4').get('standard_deviation') > 1e-02:
                sorted_classes[reduced_filename].append(data_class)
        elif data_class.coarsened_attributes.get('resolution_4').get('standard_deviation') > 1e-02:
            sorted_classes.update({reduced_filename : []})
            sorted_classes[reduced_filename].append(data_class)
            reduced_filename_store.append(reduced_filename)
    bound_title = []
    legend_slices = {}
    for i, keys in enumerate(sorted_classes):
        bounds = []
        for key in sorted_classes.get(keys)[0].compression_measurements:
            bounds.append(key)
        #The a is the same for all the samples
        for sliced in range(len(sorted_classes.get(keys))):
            bound_title = []
            for bound in bounds:
                if not bound in legend_slices:
                    names = {}
                    names_list = independent_names + dependent_names
                    for each in names_list:
                        names.update({each:[]})
                    legend_slices.update({bound : names})  

                loc = sorted_classes.get(keys)[sliced]
                loc_comp = loc.compression_measurements.get(bound)
                bound_title.append(str(loc_comp.get('compressor'))+'_'+str(loc_comp.get('bound')))
                legend_slices[bound]['psnr'].append(loc_comp.get('error_stat:psnr'))
                legend_slices[bound]['ssim'].append(loc_comp.get('error_stat:ssim'))
                legend_slices[bound]['compression_ratio'].append(loc_comp.get('size:compression_ratio'))

                legend_slices[bound]['global_variogram'].append(loc.global_variogram_fitting)
                legend_slices[bound]['n99'].append(loc.global_svd_measurements.get('n99'))
                
                for mode in ['H16_std_singular_mode', 'H16_mean_singular_mode', 'H32_std_singular_mode', 'H32_mean_singular_mode']:
                    legend_slices[bound][mode].append(loc.tiled_svd_measurements.get(mode))
                for mode in ['H16_std_local_variogram', 'H16_avg_local_variogram', 'H32_std_local_variogram', 'H32_avg_local_variogram']:
                    legend_slices[bound][mode].append(loc.local_variogram_measurements.get(mode))

        #plot function
        plot_private(False, False, fit, legend_slices, bounds, independent_names, independent_labels, 
                    dependent_names, dependent_labels, i, reduced_filename_store)


def gaussian_comparison(sample_data_classes, K_points, multi_gaussian=True, fit = 'log'):
    independent_names, independent_labels, dependent_names, dependent_labels = set_variables(gaussian=True)
    slice_data.create_folder('image_results')
    slice_data.create_folder('image_results/gaussian_comparisons')
    

    sorted_classes = {}
    reduced_filename_store = []
    #puts all the slices together
    for data_class in sample_data_classes:
        #only obtain gaussian classes
        if not hasattr(data_class, 'gaussian_attributes'):  
            continue
        if multi_gaussian and not 'a_range_secondary' in data_class.gaussian_attributes:
            continue
        elif not multi_gaussian and 'a_range_secondary' in data_class.gaussian_attributes:
            continue
        #get filename without the slice addition
        reduced_filename = data_class.filename.split('_Sample')[0] 
        if data_class.gaussian_attributes.get('K_points') != K_points:
            continue
        if reduced_filename in sorted_classes:
            if data_class.coarsened_attributes.get('resolution_4').get('standard_deviation') > 1e-02:
                sorted_classes[reduced_filename].append(data_class)
        elif data_class.coarsened_attributes.get('resolution_4').get('standard_deviation') > 1e-02:
            sorted_classes.update({reduced_filename : []})
            sorted_classes[reduced_filename].append(data_class)
            reduced_filename_store.append(reduced_filename)
          
    legend_slices   = {}
    stats_sample  = {'H8_svd_H8_avg':[],'H16_svd_H16_avg':[],'H32_svd_H32_avg':[],'H64_svd_H64_avg':[],
                     'n100':[],'n9999':[],'n999':[],'n99':[],'K_points':[], 'a_range':[]}

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
            for bound in bounds:
                loc_comp = loc.compression_measurements.get(bound)
                if not bound in legend_slices:
                    names = {'K_points':[]}
                    names_list = independent_names + dependent_names
                    for each in names_list:
                        names.update({each:[]})
                    legend_slices.update({bound:names})   
                
                bound_title.append(str(loc_comp.get('compressor'))+'_'+str(loc_comp.get('bound')))
                legend_slices[bound]['compression_ratio'].append(loc_comp.get('size:compression_ratio')) 
                legend_slices[bound]['psnr'].append(loc_comp.get('error_stat:psnr'))
                legend_slices[bound]['ssim'].append(loc_comp.get('error_stat:ssim'))
                legend_slices[bound]['K_points'].append(loc.gaussian_attributes.get('K_points'))
                if 'a_range_secondary' in loc.gaussian_attributes: 
                    if loc.gaussian_attributes.get('a_range') > loc.gaussian_attributes.get('a_range_secondary'):
                        a_value = loc.gaussian_attributes.get('a_range')
                    else:
                        a_value = loc.gaussian_attributes.get('a_range_secondary')
                    legend_slices[bound]['a_range'].append(a_value)
                else:   
                    legend_slices[bound]['a_range'].append(loc.gaussian_attributes.get('a_range'))
                
                variogram_append = loc.global_variogram_fitting if hasattr(loc, 'global_variogram_fitting') else 'NA'
                legend_slices[bound]['global_variogram'].append(variogram_append)    
                legend_slices[bound]['n99'].append(loc.global_svd_measurements.get('n99'))
         
                for mode in ['H16_std_singular_mode', 'H16_mean_singular_mode', 'H32_std_singular_mode', 'H32_mean_singular_mode']:
                    legend_slices[bound][mode].append(loc.tiled_svd_measurements.get(mode))
                for mode in ['H16_std_local_variogram', 'H16_avg_local_variogram', 'H32_std_local_variogram', 'H32_avg_local_variogram']:
                    legend_slices[bound][mode].append(loc.local_variogram_measurements.get(mode))

            #these are not affected by different bounds and compressors
            stats_sample['n100'].append(loc.global_svd_measurements.get('n100'))
            stats_sample['n9999'].append(loc.global_svd_measurements.get('n9999'))
            stats_sample['n999'].append(loc.global_svd_measurements.get('n999'))
            stats_sample['n99'].append(loc.global_svd_measurements.get('n99'))
            stats_sample['H8_svd_H8_avg'].append(loc.tiled_svd_measurements.get('H8_std_singular_mode') /
                                                            loc.tiled_svd_measurements.get('H8_mean_singular_mode'))
            stats_sample['H16_svd_H16_avg'].append(loc.tiled_svd_measurements.get('H16_std_singular_mode') /
                                                            loc.tiled_svd_measurements.get('H16_mean_singular_mode'))
            stats_sample['H32_svd_H32_avg'].append(loc.tiled_svd_measurements.get('H32_std_singular_mode') /
                                                            loc.tiled_svd_measurements.get('H32_mean_singular_mode'))
            stats_sample['H64_svd_H64_avg'].append(loc.tiled_svd_measurements.get('H64_std_singular_mode') /
                                                            loc.tiled_svd_measurements.get('H64_mean_singular_mode'))
            stats_sample['K_points'].append(loc.gaussian_attributes.get('K_points'))
            stats_sample['a_range'].append(loc.gaussian_attributes.get('a_range'))

    #plot function
    plot_private(True, multi_gaussian, fit, legend_slices, bounds, independent_names, 
                independent_labels, dependent_names, dependent_labels, i, reduced_filename_store)


    #other depnedents that don't rely on compressors or bounds
    #correlation range vs dependents
    dependent_names = ["H8_svd_H8_avg","H16_svd_H16_avg","H32_svd_H32_avg","H64_svd_H64_avg","n100","n9999","n999","n99"]
    dependent_labels = [
        "Std/avg of truncation level of local SVD (H=8)",
        "Std/avg of truncation level of local SVD (H=16)",
        "Std/avg of truncation level of local SVD (H=32)",
        "Std/avg of truncation level of local SVD (H=64)",
        "SVD truncation level for 100% of variance",
        "SVD truncation level for 99.99% of variance",
        "SVD truncation level for 99.9% of variance",
        "SVD truncation level for 99% of variance",
    ]
    for j, each in enumerate(dependent_names):
        plt.scatter(stats_sample['a_range'], stats_sample[each], s=32, marker='.')
        linear_model = np.polyfit(np.log10(stats_sample['a_range']),stats_sample[each],1)
        linear_model_fn=np.poly1d(linear_model)
        x_s=np.arange(0.02,9,.04)
        if fit=='log':
            plt.plot(x_s,linear_model_fn(np.log10(x_s)))  
        elif fit=='linear':
            plt.plot(x_s,linear_model_fn(x_s))
        plt.title(f"K ={stats_sample['K_points'][0]}")
        plt.xlabel('Smoothness Correlation Range')
        plt.ylabel(f'{dependent_labels[j]}')
        multi = '_multi' if multi_gaussian else ''
        plt.savefig('image_results/gaussian_comparisons/gaussian'+multi+'_'+str(stats_sample['K_points'][0])+'_'+each+'_correl_'+fit+'.png',facecolor='w', edgecolor='w')
        plt.close()


def clean_data(legend_slices, bounds, independent_names, each_ind, each_dep):
    for bound in bounds:
        index_ind = 0
        index_dep = 0
        
        #check independents
        for number in range(len(legend_slices[bound][each_dep])):
            if (legend_slices[bound][each_ind][index_ind] == 'NA' or legend_slices[bound][each_ind][index_ind] <= 0 or 
                np.isnan(legend_slices[bound][each_ind][index_ind]) or  np.isinf(legend_slices[bound][each_ind][index_ind])):
                legend_slices[bound][each_dep].pop(index_ind)
                for each in independent_names:
                    legend_slices[bound][each].pop(index_ind)
                index_ind -=1
            index_ind +=1
            if index_ind >= len(legend_slices[bound][each_ind]):
                break
        #check dependents
        for number in range(len(legend_slices[bound][each_dep])):
            if (legend_slices[bound][each_dep][index_dep] == 'NA' or legend_slices[bound][each_dep][index_dep] <= 0 or
                np.isinf(legend_slices[bound][each_dep][index_dep]) or np.isnan(legend_slices[bound][each_dep][index_dep])):
                legend_slices[bound][each_dep].pop(index_dep)
                for each in independent_names:
                    legend_slices[bound][each].pop(index_dep)
                index_dep -=1
            index_dep +=1
            if index_dep >= len(legend_slices[bound][each_dep]):
                break
            


def plot_private(gaussian:bool, multi_gaussian:bool, fit:str, legend_slices, bounds, independent_names, independent_labels, dependent_names, dependent_labels, filename_iteration, reduced_filename_store):
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

            clean_data(legend_slices, bounds, independent_names, each_ind, each_dep)

            # markers = [',', '+', '.', 'o', '*', '1', '2', '3', '4', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
            #each_dep compressor has own file
            plts = {}
            created = 0
            place = 0
            plot_needed = False
            pre_compressor = ''
            compressor_list, numerical_bound_list, x_values, y_values = ([] for k in range(4))

            for j, bound in enumerate(bounds):
                compressor = bound.split('_bound_')[0]
                numerical_bound = bound.split('_bound_')[1]
                if pre_compressor == compressor: 
                    plot_needed = True
                else:
                    plts.update({compressor:[]})
                    compressor_list.append(compressor)

                plts[compressor].append(plt.scatter(legend_slices[bound][each_ind], legend_slices[bound][each_dep], s=32, marker='.'))
                x_values.append(legend_slices[bound][each_ind])
                y_values.append(legend_slices[bound][each_dep])
                numerical_bound_list.append(numerical_bound)

                #if plot needed and next compressor not equal current compressor
                try:
                    next_compressor = bounds[j+1].split('_bound_')[0]
                except:
                    next_compressor = 'NA'
                if plot_needed and next_compressor != compressor:
                    if gaussian:
                        plt.title(f"K ={legend_slices[bound]['K_points'][0]} {compressor_list[created]}")
                    else:
                        plt.title(f"{reduced_filename_store[filename_iteration]} {compressor_list[created]}")   
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

                    plt.xlim(.5*np.min(min(x_values)), 1.9*np.max(max(x_values)))
                    plt.ylim(0.5*np.min(min(y_values)), 1.1*np.max(max(y_values)))
                    legend_list = []
                    for pos, num_bound in enumerate(numerical_bound_list):
                        legend_list.append(str(num_bound)+' '+str(np.round(linear_model[pos], decimals=2)))
                    plt.legend(plts[pre_compressor], legend_list, loc="lower right")

                    if gaussian:
                        multi = '_multi' if multi_gaussian else ''
                        plt.savefig('image_results/gaussian_comparisons/gaussian'+multi+'_'+str(legend_slices[bound]['K_points'][0])+'_'+
                        compressor_list[created]+'_'+each_ind+'_'+each_dep+'_correl_'+fit+'.png',facecolor='w', edgecolor='w')
                    else:
                        plt.savefig('image_results/sdrbench_comparisons/'+str(reduced_filename_store[filename_iteration])+'_'+compressor_list[created]+
                        '_'+each_ind+'_'+each_dep+'_correl_'+fit+'.png',facecolor='w', edgecolor='w')
                    plt.close()    
                    created += 1
                    #reset variables and lists
                    place = 0
                    plot_needed = False
                    numerical_bound_list, x_values, y_values = ([] for listed in range(3))
                pre_compressor = compressor
                place +=1  
   