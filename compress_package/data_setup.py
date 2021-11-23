'''
data_setup.py 
contains classes that help store the data organized for all functions within the module
functions help setup the data to be read, stored, and outputted

classes:
    global_data 
    data
functions:
    setup_slice_file(data_class)
    read_slice_folder(global_class, data_folder, dimensions, dtype='float64', dataset_name='standard', 
                      parse='', slices_needed=[])
    slice_compression_ratio(data_class, compressed_file:str, decompressed_data_path:str, X=0)
    create_folder(folder_name:str)
    remove_folder(folder_name:str)
    export_class(data_class, output_name)
    import_class(input_name, global_class=False)
'''
import os
import numpy as np
from csv import DictWriter, DictReader
from pathlib import Path
# temp comment out to reduce dependacies
import h5py as h5
from compress_package import compare_compressors
from compress_package.convert import convert_dat_h5
from compress_package.convert import slice_data

#stats returned when compress_package.compress.run_compressors is ran
defaults = ['info:compressor',
            'info:bound',
            'size:compression_ratio',
            'error_stat:psnr',
            'error_stat:rmse',
            'error_stat:mse',
            'error_stat:average_difference',
            'error_stat:average_error',
            'error_stat:value_range',
            'error_stat:ssim',
            'sz:regression_blocks',
            'sz:lorenzo_blocks',
            'stat:entropy',
            'stat:quantized_entropy',
            ]

'''
@type class
Contains information that is relevant to every dataset that will be stored within
the class data. Must setup at beginning of script file.
'''
class global_data:
    def __init__(self, temp_folder='temp',dataset_directory='datasets',all_files=False,
                compress_metrics_needed = defaults):
        #bool
        #if the h5 equalivalent file isn't found, 
        #True if you want to convert everything witin data_folder
        #False if you want to convert the file the variable filename contains
        self.all_files = all_files
        #ex - 'datasets'
        #this is the main 'datasets' directory
        self.dataset_directory = dataset_directory
        #ex - 'temp'
        #temp_folder will be created and delted after run
        self.temp_folder = temp_folder
        #ex - 'datasets/temp'
        self.dataset_temp_folder = dataset_directory+'/'+temp_folder 
        #ex - ['size:compression_ratio']
        #this will be the compression metrics wanted for each dataset
        self.compress_metrics_needed = compress_metrics_needed      
'''
@type class
Contains information that is relevant dataset specfic. This will store measurments and calculations that will
be outputted to .csv or graphed. Must setup for each new dataset wanting to be inputted.
'''
class data:    
    def __init__(self, global_data_class):
        #measurements is a dictorary 
        self.info = {}
        self.stat_methods = {}
        self.compression_measurements = {}
        self.tiled_svd_measurements = {}
        self.coarsened_attributes = {}
        self.coarsened_variogram_measurements = {}
        #sets the globals 
        self.global_data = global_data_class
        self.all_files = global_data_class.all_files
        self.temp_folder = global_data_class.temp_folder
        self.dataset_directory = global_data_class.dataset_directory
        self.compress_metrics_needed = global_data_class.compress_metrics_needed
        self.dataset_temp_folder = global_data_class.dataset_temp_folder
        #set defaults
        self.set_dtype()
        self.set_created()
    #bool
    #tells class whether it was created or imported
    def set_created(self, created=False):
        self.created = created
    
    #ex - 0 
    #slice will be Vx[:,:,0] or Vx[:,:,99] in Python. This is the same as Vx[,,1] or Vx[,,100] in R.
    #this will turn the 3-D array into a 2-D array 
    def set_slice(self, slice = 0):
        self.slice = slice
        self.info.update({'info:slice':slice})

    #ex - 'velocityx.d64'
    #must be in binary format   
    def set_filename(self, filename=''):
        self.filename = filename
        self.info.update({'info:filename':filename})

    #ex - 'velocityx.d64.dat'
    #dataset name of the h5 file    
    def set_dataset_name(self, dataset_name=''):
        self.dataset_name = dataset_name
        self.info.update({'info:dataset_name':dataset_name})
    
    #ex - 'SDRBENCH-Miranda-256x384x384'
    #must be within a 'datasets' directory 
    def set_data_folder(self, data_folder=''):
        self.data_folder = data_folder
        self.info.update({'info:dataset_folder':data_folder})
    
    #ex - [256, 384, 384]
    def set_dimensions(self, dimensions):
        self.dimensions = dimensions
        self.info.update({'info:dimensions':dimensions})

    #ex - 'float64'
    def set_dtype(self, dtype='float64'):
        self.dtype = dtype
        self.info.update({'info:dtype':dtype})

    #stores the data of the slice
    def set_data(self, data):
        self.data = data
        self.dimensions = data.shape   

    #statistics 
    def set_compression_measurements(self, compressor_id, measurements):
        self.compression_measurements.update({compressor_id: measurements})

    def set_global_svd_measurements(self, measurements):
        self.global_svd_measurements = measurements
        self.stat_methods.update(measurements)

    def set_tiled_svd_measurements(self, measurements): 
        self.tiled_svd_measurements.update(measurements)
        self.stat_methods.update(measurements)
    
    def set_gaussian_attributes(self, measurements):
        self.gaussian_attributes = measurements
        self.info.update(measurements)

    def set_coarsened_attributes(self, measurements):
        self.coarsened_attributes.update(measurements)
        self.stat_methods.update(measurements)
        
    #coarsened variogram study
    def set_coarsened_variogram_measurements(self, measurements):
        self.coarsened_variogram_measurements.update(measurements)
        self.stat_methods.update(measurements)
    
    #global variogram study 
    def set_global_variogram_fitting(self, fitting):
        self.global_variogram_fitting = fitting
        self.stat_methods.update({'stat:global_variogram_fit':fitting})
    
    #local variogram study
    def set_local_variogram_measurements(self, measurements):
        self.local_variogram_measurements = measurements
        self.stat_methods.update(measurements)

    #ex - '/home/dkrasow/compression/datasets/temp/z_K64_a1_Sample1.dat.h5'   
    #this will set the full file path 
    def set_full_sliced_file_path(self, path=None):
        #by default, slices from datasets are named 'slice_{self.slice}_{self.filename}.dat.h5'
        if path == None:
            short_path = f'../{self.dataset_temp_folder}/slice_{self.slice}_{self.filename}.dat.h5'
            path = str(Path(__file__).parent.absolute() / short_path)
        self.full_sliced_file_path = path

    def setup_slice(self, filename, dataset_name, data_folder, full_sliced_file_path, dimensions, dtype):
        self.set_created(True)
        self.set_filename(filename)
        #ex - 'velocityx.d64.dat'
        #dataset name of the h5 file
        self.set_dataset_name(dataset_name)
        #ex - 'SDRBENCH-Miranda-256x384x384'
        #must be within a 'datasets' directory
        self.set_data_folder(data_folder) 
        #ex - '/home/dkrasow/compression/datasets/temp/z_K64_a1_Sample1.dat.h5' 
        self.set_full_sliced_file_path(full_sliced_file_path)
        #ex - [256, 384, 384]
        self.set_dimensions(dimensions)
        #ex - 'float64'
        self.set_dtype(dtype)

'''
@type function
Creates a subset of an binary data file using the properties of the data class.
inputs:
    data_class          : class storing the dataset and all metadata about it
returns: full file path of new slice
'''
def setup_slice_file(data_class):
    #check for h5 files and update filename with the h5 varient
    filename_h5, data_folder_h5 = convert_dat_h5.check_h5(data_class.filename, data_class.dimensions, data_class.dtype, 
                                                        data_class.data_folder, data_class.all_files, data_class.dataset_directory) 

    print(filename_h5+"\n")
    #creates a temporary folder
    slice_data.create_folder(data_class.dataset_temp_folder)

    #creates slice of data based on fields
    full_file_path, filename, data_name = slice_data.slice(filename_h5, data_class.dataset_name, data_folder_h5,
                              data_class.temp_folder, data_class.dtype, data_class.slice, data_class.dataset_directory)

    #sets new slice class stats               
    data_class.set_filename(filename)
    data_class.set_dataset_name(data_name)
    data_class.set_data_folder(f"{data_folder_h5}")
    data_class.set_full_sliced_file_path(full_file_path)
    data_class.set_data(compare_compressors.get_input_data(data_class))  
    data_class.set_dimensions(data_class.data.shape)
    return full_file_path

'''
@type function
Creates a multiple subsets of a folder containing multiple binary data files 
using the properties of the inputs.
inputs:
    global_class        : class that contains data relevant to all datasets
    data_folder         : the folder containing the h5 data 
    dimensions          : dimensions of the data 
    dtype               : data type, default = 'float64'
    dataset_name        : name of the dataset within h5 file, default = 'standard'
    parse               : to parse filenames within the folder (ex: 'gaussian'), default = ''
    slices_needed       : a list of the slices that are needed, default = []
    slice_dimensions    : dimensions in which to slice the data
returns: list of new data_classes related to the new slices created
'''
def read_slice_folder(global_class, data_folder, dimensions, dtype='float64', dataset_name='standard',
                      parse='', slices_needed=[], slice_dimensions='X'):
    location = 0
    dset_name = dataset_name
    slicing_needed = False
    data_slice_classes = []

    path = "../"+global_class.dataset_directory+"/"+data_folder+"/"
    full_parent_path = Path(__file__).parent / path
    #goes through every file in the given parent path
    for i, files in enumerate(os.listdir(full_parent_path)):
        print(files)
        if files.startswith('.'):
            continue
        if files.endswith('.h5'):
            #if it finds a file ending with .h5, the file is going to be read 
            filename = files
            data_folder_h5 = data_folder
            if dataset_name == 'standard':
                dset_name = os.path.splitext(files)[0]
        else:
            #else it will convert the bin file to end in .h5
            filename, data_folder_h5 = convert_dat_h5.check_h5(files, dimensions, dtype, data_folder, True, global_class.dataset_directory)
            if dataset_name == 'standard':
                dset_name = files+'.dat'
        full_file_path = str(full_parent_path)+'/'+files

        #loop happens if there are multiple slices needed
        slice_data.create_folder(global_class.dataset_temp_folder)
        for slice_needed in slices_needed:
            data_slice_classes.append(data(global_class))
            slicing_needed = True
            full_file_path, sliced_filename, sliced_dataset_name= slice_data.slice(filename, dset_name, data_folder_h5, 
            global_class.temp_folder, dtype, slice_needed, global_class.dataset_directory, slice_dimensions)
            data_slice_classes[location].set_slice(slice_needed)
            if dataset_name == 'standard':
                new_dataset_name = sliced_dataset_name
            else:
                new_dataset_name = dataset_name
            data_slice_classes[location].setup_slice(sliced_filename, new_dataset_name, global_class.dataset_directory, full_file_path, dimensions, dtype)
            data_slice_classes[location].set_data(compare_compressors.get_input_data(data_slice_classes[location])) 
            data_slice_classes[location].set_data_folder(global_class.dataset_temp_folder)
            data_slice_classes[location].set_dimensions(data_slice_classes[location].data.shape)
            location += 1
        #no slicing is needed. Only reading of data and class storage is done
        if not slicing_needed: 
            data_slice_classes.append(data(global_class))
            data_slice_classes[location].setup_slice(filename, dset_name, data_folder_h5, full_file_path, dimensions, dtype)
            data_slice_classes[location].set_data(compare_compressors.get_input_data(data_slice_classes[location])) 
            data_slice_classes[location].set_dimensions(data_slice_classes[location].data.shape)

            #hardcoding parsing of file names to get key information

            #slice file shave the style: density-3072x3072x3072_slice_1200.f32.dat.h5
            if parse == 'slice':
                step = files.split('slice_')[1].split('.')
                data_slice_classes[location].set_slice(step[0])

            #Gaussian files have have the style: sample_gp_K64_a05_Sample1.dat.h5 
            if parse == 'gaussian' or parse == 'gaussian_multi':
                step = files.split('K')[1].split('_')
                K_points = step[0]
                if parse == 'gaussian':
                    a1 = str(step[1].split('a')[1].split('_')[0])
                    #adds a decimal place
                    if a1.startswith('0'):
                        a1 = a1[:1] + '.' + a1[1:]
                elif parse == 'gaussian_multi':
                    a1_step = step[2].split('a')
                    a2_step = step[3].split('a')
                    a1 = str(a1_step[1].split('_')[0])
                    a2 = str(a2_step[1].split('_')[0])
                    #adds a decimal place
                    if a1.startswith('0'):
                        a1 = a1[:1] + '.' + a1[1:]
                    if a2.startswith('0'):
                        a2 = a2[:1] + '.' + a2[1:]
                step = os.path.splitext(files)[0]
                sample = step.split('Sample')[1]
                
                sample_data_attributes = {"info:a_range":float(a1), "info:k_points":int(K_points), "info:sample": int(sample)}
                if parse == 'gaussian_multi':
                    sample_data_attributes.update({"info:a_range_secondary":float(a2)})

                data_slice_classes[location].set_gaussian_attributes(sample_data_attributes)
            location += 1
    return data_slice_classes

'''
@type function
finds the compression ratio between a compressed and decompressed file
inputs:
    data_class                  : class that contains the compressed dataset
    decompressed_data_path      : original dataset path 
returns: the compression ratio
'''
def slice_compression_ratio(data_class, decompressed_data_path:str):
    X = data_class.data 
    compressed_file = data_class.full_sliced_file_path

    if Path(decompressed_data_path).is_file():
        pass
    else:
        if X.any():
            with h5.File(decompressed_data_path, 'w') as f:
                f.create_dataset(name = data_class.dataset_name, shape = X.shape, dtype=data_class.dtype, data = X)
            f.close()
    file_size_compressed = os.path.getsize(compressed_file)
    file_size_decompressed = os.path.getsize(decompressed_data_path)

    return file_size_decompressed / file_size_compressed

'''
@type function
creates a folder 
inputs:
    folder_name                 : folder name
'''
def create_folder(folder_name:str):
    slice_data.create_folder(folder_name)

'''
@type function
removes a folder created
inputs:
    folder_name                 : temporary folder name
returns:
    0 - removal is successful
    1 - removal has errors
'''
def remove_folder(folder_name:str):
    return slice_data.remove_temp_folder(folder_name)

'''
@type function
exports information stored within data_class into a .csv in appened mode
inputs:
    data_class                  : class that contains the dataset to be outputted
    output                      : the filename of the .csv to be outputted no
no return, exports a .csv file 
'''
def export_class(data_class, output_name):
    # # list of column names 
                # common file attributes
    field_names = ['info:filename','info:dtype', 'info:dataset_name','info:dataset_folder',
                # 'a_range', 'a_range_secondary','K_points', and 'Sample' realte to 2D Guassian sample created
                'info:dimensions','info:slice','info:a_range','info:a_range_secondary','info:k_points','info:sample',
                # n values are global SVD
                'stat:n100','stat:n9999','stat:n999','stat:n99', 
                # H values are 2D tiled stats of singular modes
                'stat:H8_mean_singular_mode', 'stat:H8_median_singular_mode', 'stat:H8_std_singular_mode', 
                'stat:H16_mean_singular_mode','stat:H16_median_singular_mode','stat:H16_std_singular_mode',
                'stat:H32_mean_singular_mode','stat:H32_median_singular_mode','stat:H32_std_singular_mode',
                'stat:H64_mean_singular_mode','stat:H64_median_singular_mode','stat:H64_std_singular_mode',
                # coarsened standard deviations of the data
                'stat:res4_coarsen_std', 'stat:res8_coarsen_std', 'stat:res12_coarsen_std', 'stat:res16_coarsen_std',
                'stat:res24_coarsen_std', 'stat:res32_coarsen_std', 'stat:res48_coarsen_std', 'stat:res64_coarsen_std', 
                # coarsened global variogram study 
                'stat:res4_coarsen_variogram', 'stat:res8_coarsen_variogram', 'stat:res12_coarsen_variogram', 'stat:res16_coarsen_variogram',
                'stat:res24_coarsen_variogram', 'stat:res32_coarsen_variogram', 'stat:res48_coarsen_variogram', 'stat:res64_coarsen_variogram', 
                # global variogram study statistics
                'stat:global_variogram_fit', 
                # local variogram study statistics
                'stat:H8_avg_local_variogram', 'stat:H8_std_local_variogram',
                'stat:H16_avg_local_variogram', 'stat:H16_std_local_variogram',
                'stat:H32_avg_local_variogram', 'stat:H32_std_local_variogram',
                ] + data_class.global_data.compress_metrics_needed
                #adds the compression metrics needed
 

    #list of dictionaries
    dict_list = []
    dict_list.append({})

    for i, metric in enumerate(data_class.info):
        dict_list[0].update({metric:data_class.info.get(metric)})

    if len(data_class.stat_methods):
        for i, metric in enumerate(data_class.stat_methods):
            dict_list[0].update({metric:data_class.stat_methods.get(metric)})

    #checks for compression measurments 
    if len(data_class.compression_measurements):
        for i, keys in enumerate(data_class.compression_measurements):
            if i:
                #the new dictionary has all the quantities of the previous dict_list. 
                #This will just result in different compression measurements. 
                #This will result in another row being added.
                #Two copies were required since it was a dictionary within a list
                copy = dict_list[i-1].copy()
                dict_list.append(copy)
            temp = data_class.compression_measurements.get(keys)
            for j, stat in enumerate(data_class.global_data.compress_metrics_needed):
                dict_list[i].update({stat:temp.get(stat)})

    # Open CSV file in append mode
    # Create a file object for this file
    file_out = '../'+output_name
    path = str(Path(__file__).parent.absolute() / file_out)
    file_exists = os.path.isfile(path)
    with open(path, 'a') as f_object:
        new = DictWriter(f_object, delimiter=',', fieldnames=field_names)
        if not file_exists:
            #only write head first time
            new.writeheader()
        for i, element in enumerate(dict_list):
            new.writerow(element)
        f_object.close()

'''
@type function
import information stored within a .csv file into a series of data_classes
inputs:
    input_name                 : the filename of the .csv to be outputted to
    global_class               : the global class containing all the defaults, default: False
returns : a list of dataclasses
'''
def import_class(input_name, global_class=False):
    index = 0
    class_list = []
    prev_filename = ''
    file_in = '../'+input_name
    path = str(Path(__file__).parent.absolute() / file_in)
    with open(path, 'r', encoding='utf-8-sig') as f_object:
        csv_file = DictReader(f_object)
        for lines in csv_file:
            #only happens due to multiple compressor bounds/ compressors used
            if lines['info:filename']==prev_filename:
                #append to a dataclass
                metrics = {}
                for measurement in class_list[index-1].global_data.compress_metrics_needed:
                    if measurement == 'info:bound' or measurement == 'info:compressor':
                        metrics.update({measurement:lines[measurement]})
                    else:
                        if lines[measurement] == '':
                            metrics.update({measurement:np.nan})
                        elif lines[measurement] == '#NAME?':
                            metrics.update({measurement:np.inf})
                        else:
                            metrics.update({measurement:np.float64(lines[measurement])})
                class_list[index-1].set_compression_measurements(f"{lines['compressor']}_bound_{lines['bound']}", metrics)
            else:
                #new dataclass
                if global_class:
                    class_list.append(data(global_class))
                else:
                    global_data_class = global_data()
                    class_list.append(data(global_data_class))
                class_list[index].set_filename(lines['info:filename'])
                class_list[index].set_dataset_name(lines['info:dataset_name'])
                class_list[index].set_data_folder(lines['info:dataset_folder'])
                class_list[index].set_dimensions(eval(lines['info:dimensions']))
                if not lines['info:slice'] == '':
                    class_list[index].set_slice(np.int(lines['info:slice']))
                #if has first element, it will have all elements in list
                if not lines['info:a_range_secondary'] == '':
                    class_list[index].set_gaussian_attributes({
                        'info:a_range': np.float64(lines['info:a_range']),
                        'info:a_range_secondary': np.float64(lines['info:a_range_secondary']),
                        'info:k_points': int(lines['info:k_points']),
                        'info:sample' : int(lines['info:sample'])
                    })
                elif not lines['info:a_range'] == '':
                    class_list[index].set_gaussian_attributes({
                        'info:a_range': np.float64(lines['info:a_range']),
                        'info:k_points': int(lines['info:k_points']),
                        'info:sample' : int(lines['info:sample'])
                    })
                if not lines['stat:n100'] == '':
                    class_list[index].set_global_svd_measurements({
                        'stat:n100': np.float64(lines['stat:n100']), 'stat:n9999': np.float64(lines['stat:n9999']),
                        'stat:n999': np.float64(lines['stat:n999']), 'stat:n99': np.float64(lines['stat:n99'])})
                if not lines['H8_mean_singular_mode'] == '':
                    for H in [8,16,32,64]:
                        class_list[index].set_tiled_svd_measurements({
                            'stat:H'+str(H)+'_mean_singular_mode'   :np.float64(lines['stat:H'+str(H)+'_mean_singular_mode']), 
                            'stat:H'+str(H)+'_median_singular_mode' :np.float64(lines['stat:H'+str(H)+'_median_singular_mode']), 
                            'stat:H'+str(H)+'_std_singular_mode'    :np.float64(lines['stat:H'+str(H)+'_std_singular_mode'])
                        })
                if not lines['H8_avg_local_variogram'] == '':
                    class_list[index].set_local_variogram_measurements({
                        'stat:H8_avg_local_variogram'   :np.float64(lines['stat:H8_avg_local_variogram']), 
                        'stat:H8_std_local_variogram'   :np.float64(lines['stat:H8_std_local_variogram']), 
                        'stat:H16_avg_local_variogram'  :np.float64(lines['stat:H16_avg_local_variogram']),
                        'stat:H16_std_local_variogram'  :np.float64(lines['stat:H16_std_local_variogram']), 
                        'stat:H32_avg_local_variogram'  :np.float64(lines['stat:H32_avg_local_variogram']),
                        'stat:H32_std_local_variogram'  :np.float64(lines['stat:H32_std_local_variogram'])
                        })

                #check what resolutions were used based on size
                res_list = [4, 8, 12, 16, 24, 32, 48, 64]
                N = []
                dims = class_list[index].dimensions
                #dim1*dim2/resolution_tocheck^2 >= 16
                for res in res_list:
                    #checks res list with to see if it fits the model
                    if (dims[0]*dims[1])/res**2 >= 16:
                        N.append(res)
                if not lines['stat:res4_coarsen_std'] == '':
                    for res in N:
                        coarsen_data_measurements = {"stat:res_"+str(res)+"_coarsen_std":np.float64(lines[f'stat:res{res}_coarsen_std'])}
                        class_list[index].set_coarsened_attributes(coarsen_data_measurements)
                if not lines['stat:res4_coarsen_variogram'] == '':
                    for res in N:
                        coarsen_variogram_measurements = {'stat:res_'+str(res)+'_coarsen_variogram':np.float64(lines[f'stat:res{res}_coarsen_variogram'])}
                        class_list[index].set_coarsened_variogram_measurements(coarsen_variogram_measurements)      
                if not lines['stat:global_variogram_fit'] == '':
                    if lines['stat:global_variogram_fit'] == 'NA':
                        class_list[index].set_global_variogram_fitting(lines['stat:global_variogram_fit'])
                    else:
                        class_list[index].set_global_variogram_fitting(np.float64(lines['stat:global_variogram_fit']))

                if not lines['info:compressor'] == '':
                    metrics = {}
                    for measurement in class_list[index].global_data.compress_metrics_needed:
                        if lines[measurement] == '':
                            metrics.update({measurement:lines[measurement]})
                        else:
                            metrics.update({measurement:np.float64(lines[measurement])})
                    class_list[index].set_compression_measurements(f"{lines['info:compressor']}_bound_{lines['info:bound']}", metrics)
                #increases the class index
                index += 1
            prev_filename = lines['info:filename']
        f_object.close()       
    return class_list
