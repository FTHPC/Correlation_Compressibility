'''
slice_data.py
A 2-d slice is made out of a larger data 3-d set Vx
The slice looks like Vx[:,:,X]
X represents the Zth dimension to make a 2-d slice out of

functions:
    slice(filename:str, dataset_name:str, data_folder:str, temp_folder:str,
          dtype:str, X:int, dataset_directory='datasets')
    custom_slice(data, filename:str, dataset_name:str, dataset_directory,
                 new_dataset_folder:str, dtype:str)
    create_folder(folder:str)
    remove_temp_file(temp_folder:str, filename:str)
    remove_temp_folder(temp_folder:str)
'''

from pathlib import Path
import h5py as h5
import numpy as np
import os

'''
@type function
Slices data from the appriate dataset into Vx[:,:,X]
This data is slored in a sliced temporary file
inputs:
    filename            : name of h5 file
    dataset_name        : name of the dataset within h5 file
    data_folder         : the folder containing the h5 data
    temp_folder         : temporary folder name
    dtype               : data type
    X                   : the chosen slice
    dataset_directory   : foldername of where the datasets are contained, default = 'datasets'
returns the output path of the newly created file
'''
def slice(filename:str, dataset_name:str, data_folder:str, temp_folder:str, dtype:str, X:int, dataset_directory='datasets', dimension_needed= 'X'):
    new_addition = '_'+'slice_'+str(X)+'_'+dimension_needed
    new_file_name = os.path.splitext(os.path.splitext(filename)[0])[0]+new_addition+'.dat.h5'
    new_dataset_name = os.path.splitext(new_file_name)[0]
    input_file = '../../'+dataset_directory+'/'+data_folder+'/'+filename
    input_file_full = Path(__file__).parent.absolute() / input_file
    output_file = '../../'+dataset_directory+'/'+temp_folder+'/'+new_file_name
    output_file_full = str(Path(__file__).parent.absolute() / output_file)
    with h5.File(input_file_full, 'r') as f:
        #transposes the stored array into Vx
        if dimension_needed == 'X':
            Vx = np.transpose(f[dataset_name])[:,:,X]
        elif dimension_needed == 'Y':
            Vx = np.transpose(f[dataset_name])[:,X,:]
        elif dimension_needed == 'Z':
            Vx = np.transpose(f[dataset_name])[X,:,:]
        f.close()

    dims_data = Vx.shape
    
    with h5.File(output_file_full, 'w') as f:
        f.create_dataset(name = new_dataset_name, shape = dims_data, dtype = dtype, data = Vx)
    f.close()
    return output_file_full, new_file_name, new_dataset_name

'''
@type function
Creates a h5 file containing data that was stored within a 2-d matrix
inputs:
    data                : The created 2-d matrix of data
    filename            : wanted name of h5 file
    dataset_name        : name of the dataset within h5 file
    dataset_directory   : folder where the h5 files are stored to be sliced
    new_dataset_folder  : folder where the sliced data will be stored
    dtype               : data type
returns the output path of the newly created file
'''
def custom_slice(data, filename:str, dataset_name:str, dataset_directory, new_dataset_folder:str, dtype:str):
    sliced_path = '../../'+dataset_directory+'/'+new_dataset_folder+'/'+filename+'.dat.h5'
    create_folder('../../'+dataset_directory+'/'+new_dataset_folder)
    temporary_file_full = str(Path(__file__).parent.absolute() / sliced_path)
    with h5.File(temporary_file_full, 'w') as f:
        f.create_dataset(name = dataset_name, shape = data.shape, dtype=dtype, data = data)
    f.close()
    return temporary_file_full

'''
@type function
Creates a binary file containing data that was stored within a 2-d matrix
inputs:
    data                : The created 2-d matrix of data
    filename            : wanted name of binary file
    dataset_directory   : folder where the binary files are stored
    new_dataset_folder  : folder where the sliced data will be stored
returns the output path of the newly created file
'''
def custom_binary_slice(data, filename:str, dataset_directory, new_dataset_folder:str):
    sliced_path = '../../'+dataset_directory+'/'+new_dataset_folder+'/'+filename
    create_folder('../../'+dataset_directory+'/'+new_dataset_folder)
    temporary_file_full = str(Path(__file__).parent.absolute() / sliced_path)
    with open(temporary_file_full, 'wb') as f:
        f.write(bytearray(data))
    f.close()
    return temporary_file_full

    
'''
@type function
creates a folder 
inputs:
    folder              : folder name
'''
def create_folder(folder:str):
    try:
        os.mkdir(folder)
    except:
        pass

'''
@type function
removes the temporary file created
inputs: 
    temp_folder         : temporary folder name 
    filename            : filename within temp folder to be removed
returns:
    0 - removal is successful
    1 - removal has errors
'''
def remove_temp_file(temp_folder:str, filename:str):
    #removes the temp folder and files created
    if os.path.exists(temp_folder+'/'+filename):
        os.remove(temp_folder+'/'+filename)
    if os.path.exists(temp_folder+'/'+filename):
        return 1
    return 0

'''
@type function
removes the temporary folder created
inputs:
    temp_folder         : temporary folder name
returns:
    0 - removal is successful
    1 - removal has errors
'''
def remove_temp_folder(temp_folder:str):
    try: 
        #the directory cannot be removed if full
        os.rmdir(temp_folder)
    except:
        #deletes other files in temp just incase
        for files in os.listdir(temp_folder):
            if files.startswith('.'):
                continue
            os.remove(temp_folder+'/'+files)
    if os.path.exists(temp_folder):
        #The folder will remain on the disk if there is hidden files within the temp folder
        try:
            os.rmdir(temp_folder)
        except:
            pass
            return 1
    return 0
