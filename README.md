# Correlation_Compressibility
To use on Palmetto:

source /zfs/ftdice/setup.sh 
spack load libpressio 
spack load libpressio tthresh
spack load py-h5py
spack load py-matplotlib
spack load py-mpi4py
spack load qcat
module load r

Python 3.6.4 or higher must be used due to dependacies

A folder is necessary named 'datasets' that will host all your datasets from SDR_Bench or other Ex: Coreelation_Compreesibility/datasets/SDR_BENCH_FOLDER/data.d64

If you change your dataset folder name, you must indicate it in script.py using the constructors to modify the setup operations stored in compress_package.setup.


ATTENTION: the only files that needs changing is the scripts. There is example code in each script file. Change it to do whatever the packages allow you to do.


#user input:

scripts- All the customization will occur within this file. Datasets will be entered here, ran, and graphed.

option 1 (run in order with mpi processes):
process_script_mpi.py - runs the inputted dataset in parralel (use if datasets are larger than 1000x1000) and outputs csv
concat_output_script.py - must be ran only if process_script_mpi.py is ran. This combines multiple output csv files into 1
import_script.py - imports csv and graphs data 

option 2 (run in order):
process_script.py - runs the inputted dataset in sequential (use if datsets are smaller than 1000x1000) and outputs csv
import_script.py - imports csv and graphs data 


#files:

compress_package.setup -  Setups data so the slicing and other operations can be done. Filename, paths and other options are stored here. 

compress_package.compare_compressors - data is compared using sz and zfp compressors.

compress_package.sampler - simulation of 2 samples from a 2D-GP with squared exponential covariance with range parameter 'a' 

compress_package.svd_coarsen - tiled svd and coarsening data operations are performed

compress_package.convert.convert_dat_h5 - will check the 'datasets' directory for hdf5 files. If can't find the hdf5 file, the module automatically converts the provided binary .d64 or .f32 files into hdf5 files with the .h5 extension.

compress_package.convert.slice_data - allows the user to create/delete temporary folders and files. These files are slices of the data based on the inputted specifications
 
