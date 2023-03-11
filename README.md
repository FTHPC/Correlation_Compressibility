# Compressibility Analysis (Correlation_Compressibility)

## Statement of Purpose

This repo contains scripts to perform compressibility analysis on several leading lossy compressors. 
The compressibility analysis relies on deriving statistics on scientific data and explore their relationships to their compression ratios from various lossy compressors (based on various compression scheme). 
The extracted relationships between compression ratios and statistical predictors are modeled via regression models, which provide a statistical framework to predict compression ratios for the different studied lossy compressors. 

This repo contains an automatic framework of scripts that perform the compression of scientific datasets from 8 compressors (SZ2, ZFP, MGARD, FPZIP, Digit Rounding and Bit Grooming), the derivation of the statistical predictors of compression ratios (SVD, standard deviation, quantized entropy), and scripts to perform the training of the regression models (linear and spline regressions) as well as the validation of the regression predictions. 
A runtime analysis is also performed and associated codes are provided. 

### Main code structures
Compression metrics, including compression ratios, and derivation of statistical predictors (SVD, standard deviation, quantized entropy) codes are found in `compress_package` and are run via `scripts/run.sh` as described in the section "How to compute statistical predictors and compression analysis on datasets". 
Linear and spline regressions training and validation (functions `cr_regression_linreg` and `cr_regression_gam` from the script `replicate_figures/functions_paper.R`). 
Codes for the different runtime analysis are found in the folder `runtime_analysis` and are automated with the script `runtime.sh`, the study includes compression time for SZ2, ZFP, MAGRD, FPZIP, data quantization, SVD, local (tiled) variogram and local (tiled) variogram, and runtime for training and prediction of the regressions.   
Finally, the script `replicate_figures/graphs_paper_container.R` replicates and saves all the figures from the paper ad as well as numbers from the tables. 

For each dataset in the `dataset` folder, slicing is performed for each variable field (e.g. density in Miranda), each slice is stored in a class. The class is updated as compressions with the 8 compressors is performed and updated as the statistical predictors are derived. Results of each class are stored in a .csv file (example of csv files can be found at `replicate_figures/generated_data/`). 
All the datasets stored in the `dataset` folder can be analyzed with the given set of codes, one needs to source `scripts/config.json` with the appropriate dataset name as described in the below section "How to compute statistical predictors and compression analysis on datasets". 
The regression analysis and its prediction is then performed on R dataframes based on the aforementioned .csv files. 


## System Information

The hardware and software versions used for the performance evaluations can be found in the table below. These nodes come from Clemson University's Palmetto Cluster.

These nodes have:

| component   | version                     | component      | version  |
| ----------- | --------------------------- | ----------     | -------- |
| CPU         | Intel Xeon 6148G (40 cores) | sz2            | 2.1.12.2 |
| GPU         | 2 Nvidia v100               | sz3            | 3.1.3.1  |
| Memory      | 372GB                       | zfp            | 0.5.5    |
| Network     | 2 Mellanox MT27710 (HDR)    | mgard          | 1.0.0    |
| FileSystem  | BeeGFS 7.2.3 (24 targets)   | bit grooming   | 2.1.9    |
| Compiler    | GCC 8.4.1                   | digit rounding | 2.1.9    |
| OS          | CentOS 8.2.2004             | R              | 4.1.3    |
| MPI         | OpenMPI 4.0.5               | Python         | 3.9.12   |
| LibPressio  | 0.83.4                      |                |          |


## First time setup                         

### Container Installation (for ease of setup)

We provide a container for `x86_64` image for ease of installation.

This container differs from our experimental setup slightly. The production build used `-march=native -mtune=native` for architecture optimized builds where as the container does not use these flags to maximize compatibility across `x86_64` hardware.

NOTE this file is >= 11 GB , download with caution.


### Manual Installation

By default, it is recommended to follow the install locations that are indicated on the top of ```scripts/run.sh```
and the top of ```config.json```. These two files provide the configuration options to get the program running.

Spack should be installed in the following location: ```$HOME/spack/```

This Github repo should be cloned in the following location: ```$HOME/Correlation_Compressibility/```
This location is also referenced as the ```COMPRESS_HOME``` environment variable.

A dataset folder called 'datasets' should be in the following location: ```$HOME/Correlation_Compressibility/datasets/```.

Clone the repo but make sure to install or load `git-lfs` first. 

```bash
# install/module load git-lfs, needed to download example_data for building the container
sudo dnf install git-lfs #Fedora/CentOS Stream 8
sudo apt-get install git-lfs # Ubuntu
spack install git-lfs; spack load git-lfs # using spack

# clone this repository
git clone https://github.com/FTHPC/Correlation_Compressibility $HOME/Correlation_Compressibility
cd $HOME/Correlation_Compressibility
```

If you forgot to install `git-lfs` before and have an empty file in the  `datasets` folder, you should install `git-lfs`
and then run the following:

```
git lfs fetch
git lfs checkout
```


Once Spack is installed, there is a ```spack.yaml``` configuration file containing the Spack environment necessary to run the program.

```bash
cd $HOME
git clone --depth=1 https://github.com/spack/spack
git clone --depth=1 https://github.com/robertu94/spack_packages 
source ./spack/share/spack/setup-env.sh 
spack compiler find
spack external find 
spack repo add --scope=site ./spack_packages 
cd $HOME/Correlation_Compressibility 
spack env activate .
spack install
export COMPRESS_HOME=$HOME/Correlation_Compressibility 
```
These commands will install the environment. The environment only needs to be installed once.
If you are using an older < gcc11, then you will need to add the following to the ```spack.yaml``` file:
```
^libstdcompat+boost
```
after ```^mgard@robertu94+cuda``` but before the ```,```.
 

### To run the training and prediction timing analysis demonstration

In order to run the timing analysis, a dataset must be specified.
There are two datasets setup within this demonstration. 

```bash
sh runtime_analysis/runtime.sh -d [DATASET]
```
[DATASET] can be either [NYX] or [SCALE]

After running the above script, an *.RData file(s) will be produced giving the approprirate timing information of 
the training and prediction for the regression models.

Note: A quicker and more efficient quantized entropy method is demonstrated in ```qentropy.cc```
#### The following below runs ```qentropy.cc```
```bash 
g++ -std=c++2a -O3 qentropy.cc -o qentropy -march=native -mtune=native
./qentropy
```

Note: Please run the runtime analysis for both datasets before running the following section. 


### Replication of figures: how to run statistical prediction of compression ratios and the prediction validation 

The script ```graphs_paper_container.R```  saves the graphs presented in the paper and provides associated validation metrics (correlation and median absolute error percentage). 

The script ```graphs_paper_container.R``` will source the scripts  ```load_dataset_paper.R``` and ```functions_paper.R``` that respectively load the dataset of interest and perform the regression analysis (training and prediction in cross-validation). 
As a consequence the scripts  ```load_dataset_paper.R``` and ```functions_paper.R``` do not need to be run by the user. 

The script ```graphs_paper_container.R```  is run via the command:
```bash sh replicate.sh```

From running the script once, it will save all Figures 1, 3, 4 and 5 into .png files from the paper as well as corresponding validation metrics. 
Figure 2 is not saved as it provides a simple vizualization of slices of the datasets. 
Slices of the datasets are generated in the Section "How to compute statistical predictors and compression metrics" and can be stored, however we do not save them here to save space in the container. 
Numbers for Tables 2, 3 and 5 are printed in the R console. 
All printed validation metrics are save into a file named ```figure_replication.log```.
Figures and the log-file are saved in the same folder as the one where R script is run and the filename structure is `figY_*.png` with Y is the figure number reference in the paper and `*` provides additional informnation about the data and the compressor.  
Numbers for Table 4 are saved in the last section in .txt files `statistic_benchmark_runtime_X.txt` with X the studied dataset (NYX or SCALE). 

In order to limit the container size to aid reproducibility, we only added a restricted number of scientific datasets in the container and we rely on csv files from our production runs (saved as described above in the Section "How to compute statistical predictors on datasets"). 
More datasets are available on [SDRBench](https://sdrbench.github.io). 

