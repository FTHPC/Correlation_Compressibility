'''
concat_output_script.py
combines multiple output files into one
https://www.freecodecamp.org/news/how-to-combine-multiple-csv-files-with-8-lines-of-code-265183e0854/
'''
import os
import glob
import pandas as pd
import compress_package as cp
os.chdir("outputs")
output_filename = '../output.csv'
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