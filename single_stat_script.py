'''
single_stat_script.py
reads in datasets and peforms statistical analysis on them.
results are outputted in a 'outputs' folder. The files are then combined to
a specified output file.
'''
output_file = 'entropy.csv'

import compress_package as cp
import pandas as pd
import os
import glob
from csv import DictWriter
from pathlib import Path
from mpi4py import MPI

#must setup a global data class
global_data = cp.setup.global_data()
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

if not rank:
    dimensions = [256,384,384]
    data_folder = 'SDRBENCH-Miranda-256x384x384'
    
    sample_data_classes_X = cp.setup.read_slice_folder(global_data, data_folder, dimensions,
            slices_needed=range(0, 255, 5), slice_dimensions='X')
    sample_data_classes_Y = cp.setup.read_slice_folder(global_data, data_folder, dimensions,
            slices_needed=range(0, 255, 5), slice_dimensions='Y')
    sample_data_classes_Z = cp.setup.read_slice_folder(global_data, data_folder, dimensions,
            slices_needed=range(0, 255, 5), slice_dimensions='Z')
    sample_data_classes = sample_data_classes_X + sample_data_classes_Y + sample_data_classes_Z
    
        
else:
    sample_data_classes = []

sample_data_classes = comm.bcast(sample_data_classes, root=0)
comm.Barrier()
    
#does global_svd, coarsening, and compression measurements on the list of sample data class
i = rank
while i<len(sample_data_classes):
    data_class = sample_data_classes[i]

    dict_list = []
    entropy = cp.compress.entropy(data_class.data)
    quan_entropy = cp.compress.quantized_entropy(data_class.data)

    field_names = ['filename', 'slice', 'entropy', 'quantized_entropy', 'quantized_rel_entropy']
    dict_list.append({'filename':data_class.filename,'slice':data_class.slice, 
                      'entropy':entropy,'quantized_entropy':quan_entropy})
    file_out = '../'+output_file
    path = str(Path(__file__).parent.absolute() / file_out)
    file_exists = os.path.isfile(path)
    

    with open(path, 'a') as f_object:
        new = DictWriter(f_object, delimiter=',', fieldnames=field_names)
        if not file_exists:
            #only write head first time
            new.writeheader()
        for i, element in enumerate(dict_list):
            new.writerow(dict_list[i])
        f_object.close()
    i += size


comm.Barrier()
'''
combines multiple output files into one
https://www.freecodecamp.org/news/how-to-combine-multiple-csv-files-with-8-lines-of-code-265183e0854/
'''
if not rank:
    os.chdir("outputs")
    output_filename = '../'+output_file
    extension = 'csv'
    all_filenames = [i for i in glob.glob('*.{}'.format(extension))]
    #combine all files in the list
    combined_csv = pd.concat([pd.read_csv(f) for f in all_filenames])
    #export to csv
    if os.path.exists(output_filename):
        combined_csv.to_csv( output_filename, mode='a', header=False, index=False, encoding='utf-8-sig')
    else:
        combined_csv.to_csv( output_filename, mode='a', index=False, encoding='utf-8-sig')

    os.chdir("..")
    cp.setup.remove_folder('outputs')

comm.Barrier()
MPI.Finalize()
