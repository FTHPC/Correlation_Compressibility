'''
compress_dat_h5.py
converts binary file to the hdf5.h file format
must run with python 3.6 or greater

dataset_name is the filename with the .dat extension appendend
the output file is the filename with .dat.h5 extension appended
the dataset must be within a /datasets folder containing the folder to be converted

functions:
    check_h5(filename:str, dims_data:list, data_type:str, dataset_folder:str, 
             all_file:bool, dataset_directory)
    convert_h5(dims_data:list, data_type, file_to_convert:str, dataset_folder:str, 
               all_files:bool, dataset_directory)
'''
from pathlib import Path
import h5py as h5
import numpy as np
import os

'''
@type function
checks /dataset folder for h5 file based on inputted filename
inputs:
    dims_data           : dimensions of data
    data_type           : datatype in str form
    filename            : the file to be checked
    dataset_folder      : foldername of the file/s to be converted
    all_file            :
        True if you want to convert everything within the folder.
        False if you want to convert the file the variable file_to_convert contains
    dataset_directory   : foldername of where the datasets are contained
    
returns: the filename of h5 file, the parent directory of the h5 file
'''
def check_h5(filename:str, dims_data:list, data_type:str, dataset_folder:str, all_file:bool, dataset_directory):                     
    try:
        for files in os.listdir(Path(__file__).parent / "../../"+dataset_directory+"/"):
            if(filename+".dat.h5" == files):
                return files, "/"
    except:
        pass
    try:
        for files in os.listdir(Path(__file__).parent / str("../../"+dataset_directory+"/"+dataset_folder+"_h5/")):
            if(filename+".dat.h5" == files):
                return files, dataset_folder+"_h5"
    except: 
        pass
    #converts file if not found
    if all_file:
        dir = "/"+dataset_folder+"_h5/"
    else:
        dir = "/"
    convert_h5(dims_data, data_type, filename, dataset_folder, all_file, dataset_directory)
    return filename+".dat.h5", dir 
'''
@type function
creates a replica folder/file of a data set in the hdf5 file format
inputs:
    dims_data           : dimensions of data
    data_type           : datatype in str form
    file_to_convert     : filename of the file
    dataset_folder      : foldername of the file/s to be converted
    all_file            : 
        True if you want to convert everything within the folder.
        False if you want to convert the file the variable file_to_convert contains
    dataset_directory   : foldername of where the datasets are contained
'''
def convert_h5(dims_data:list, data_type, file_to_convert:str, dataset_folder:str, all_files:bool, dataset_directory): 
    #do not change these lines
    for files in os.listdir(Path(__file__).parent / str("../../"+dataset_directory+"/"+dataset_folder+"/")):
        if all_files == True:
            if files.startswith('.'):
                continue
            file_to_convert = files
            #creates a new folder with "_h5" appended
            file_output_path = "../../"+dataset_directory+"/"+dataset_folder+"_h5/"
        else:
            #a single file conversion will be placed in the datasets folder. No new folder created
            file_output_path = "../../"+dataset_directory+"/"

        dataset_name = file_to_convert+".dat"

        file_input = "../../"+dataset_directory+"/"+dataset_folder+"/"+file_to_convert
        file_input_full = Path(__file__).parent / file_input

        file_output = file_output_path+file_to_convert+".dat.h5"
        file_output_full = Path(__file__).parent / file_output

        input_data = np.fromfile(file_input_full, dtype=data_type)

        folder_output_path = Path(__file__).parent / file_output_path
        folder_output_path.mkdir(exist_ok = True)

   
        with h5.File(file_output_full, 'w') as f:
            f.create_dataset(name = dataset_name, shape = dims_data, dtype=data_type, data = input_data)
        f.close()
        #will only perform loop once since just 1 file
        if (all_files == False):
            break
