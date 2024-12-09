import os
import pandas as pd
import glob
import compress_package as cp

data_folder = 'SDRBENCH-EXASKY-NYX-512x512x512_outputs'
os.chdir(data_folder)
output_filename = '../'+"output_exasky_mar20.csv"
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
cp.setup.remove_folder(data_folder)
