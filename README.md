# Compressibility Analysis (Correlation_Compressibility)

## Statement of Purpose

This repo contains scripts to perform compressibility analysis on several leading lossy compressors. 
The compressibility analysis relies on deriving statistics on scientific data and explore their relationships to their compression ratios from various lossy compressors (based on various compresison scheme). 
The extracted relationships between compression ratios and statistical predictors are modeled via regression models, which provide a statistical framework to predict compression ratios for the different studied lossy compressors. 

This repo contains an automatic framework of scripts that perform the compression of scientific datasets from 8 compressors (SZ2, ZFP, MGARD, FPZIP, Digit Rounding and Bit Grooming), the derivation of the statistical predictors of compression ratios (SVD, standard deviation, quantized entropy), and scripts to perform the training of the regression models (linear and spline regressions) as well as the validation of the regression predictions. 
A runtime analysis is also performed and associated codes are provided. 

Main code structures: compression (), derivation of statistical predictors (SVD, standard deviation, quantized entropy) (), linear and spline regressions training and validation (functions `cr_regression_linreg` and `cr_regression_gam` from the script `replicate_figures/functions_paper.R`). 
Codes for the different runtime analysis are found in the folder `runtime_analysis` and are automated with the script `runtime.sh`, the study includes compression time for SZ2, ZFP, MAGRD, FPZIP, data quantization, SVD, local (tiled) variogram and local (tiled) variogram, and runtime for training and prediction of the regressions.   
Finally, the script `replicate_figures/graphs_paper_container.R` replicates and saves all the figures from the paper ad as well as numbers from the tables. 

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

### Container Install (for ease of setup)

We provide a container for `x86_64` image for ease of installation.

This container differs from our experimental setup slightly. The production build used `-march=native -mtune=native` for architecture optimized builds where as the container does not use these flags to maximize compatibility across `x86_64` hardware.

NOTE this file is >= 11 GB , download with caution.


#### Singularity

You can install and start the container on many super computers using singularity.

```bash
# this first commmand may issue a ton of warnings regarding xattrs depending on your filesystem on your container host; these were benign in our testing.
singularity pull corr.sif ghcr.io/fthpc/correlation_compressibility:latest

# -c enables additional confinement than singularity uses by default to prevent polution from /home
singularity run -c  corr.sif bash
```


#### Docker

Many other systems can use podman or docker.

```bash
docker pull ghcr.io/fthpc/correlation_compressibility:latest

#most systems
docker run -it --rm ghcr.io/fthpc/correlation_compressibility:latest

# if running on a SeLinux enforcing system
docker run -it --rm --security-opt label=disable ghcr.io/fthpc/correlation_compressibility:latest
```

### Building the Container

You can build the container yourself as follows:
NOTE this process takes 3+ hours on a modern laptop, and most clusters do not
provide sufficient permissions to run container builds on the cluster.

Additionally compiling MGRAD -- one of the compressors we use takes >= 4GB RAM per core, be cautious
with systems with low RAM.  You may be able compensate by using fewer cores by changing the spack install
instruction in the Dockerfile to have a `-j N` where `N` is the number of cores you wish to use

```bash
# install/module load git-lfs, needed to download example_data for building the container
sudo dnf install git-lfs #Fedora/CentOS Stream 8
sudo apt-get install git-lfs # Ubuntu
spack install git-lfs; spack load git-lfs # using spack

# clone this repository
git clone --recursive https://github.com/FTHPC/Correlation_Compressibility
cd Correlation_Compressibility
docker build . -t correlation_compressibility
```

### Manual Install

By default, it is recommended to follow the install locations that are indicated on the top of ```scripts/run.sh```
and the top of ```config.json```. These two files provide the configuration options to get the program running.

Spack should be installed in the following location: ```$HOME/spack/```

This Github repo should be cloned in the following location: ```$HOME/Correlation_Compressibility/```

A dataset folder called 'datasets' should be in the following location: ```$HOME/Correlation_Compressibility/datasets/```

Clone the repo.  Make sure to install/load git-lfs first

```bash
# install/module load git-lfs, needed to download example_data for building the container
sudo dnf install git-lfs #Fedora/CentOS Stream 8
sudo apt-get install git-lfs # Ubuntu
spack install git-lfs; spack load git-lfs # using spack

# clone this repository
git clone https://github.com/FTHPC/Correlation_Compressibility $HOME/Correlation_Compressibility
cd $HOME/Correlation_Compressibility
```

If you forgot to install `git-lfs` before and have an empty files in the  `datasets` folder, you should install `git-lfs`
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

## Replication of Results

### How to compute statistical predictors on datasets

In order to run the statistical analysis that computes the statistical predictors (SVD, standard deviation, quantized entropy) of compression ratios, a dataset and a configuration file must be specified.
TEST is a dataset that is specified within the config.json file. 

```bash
sh scripts/run.sh -c config.json -d TEST
```

The command above performs the computation of statistical predictors and writes output to the output file specified in the configuration file.
This will use local hardware without a scheduler. Use ```-n``` to specify the MPI processes on your local system. 
It is recommended that this value matches your CPU core count.

If one has the PBS scheduler and run outside of the container, feel free to use flags ```-p``` or ```-s``` for job execution.
```-p``` will schedule multiple jobs based on the quantized error bounds and error bound types for a specififed dataset.
```-s``` will schedule a single job grouping all the analysis for a specified dataset.

See ```-h``` for more options or help with syntax.


If a dataset is wanted to run, the config.json file provides options to add datasets.
The following options must be followed when adding another dataset in the configuration file:
```json
"_comment" : 
{
    "folder"            : "folder containing h5 or binary files",
    "data_dimensions"   : "dimensions of the datasets within dataset_folder. Either 1x2 or 1x3. EX: '1028, 1028'",
    "slice_dimensions"  : "list of the dimensions wanted: EX: 'None' or 'X, Y, Z'",
    "output"            : "name of the output csv file: EX: 'test.csv'",
    "dtype"             : "data type. can be 'float32' or 'float64'",
    "parse_info"        : "type of parsing needed: 'None', 'slice', 'gaussian', 'gaussian_multi', 'spatialweight', or 'scalarweight'",
    "dataset_name"      : "necessary accessing 2D HDF5 files: 'standard' if not custom. custom EX: 'Z'"
} 
```

** descrobe outputs in csv files and how they are used to build figures 


### To run the training and prediction timing analysis demonstration

In order to run the timing analysis, a dataset must be specified.
There are two datasets setup within this demonstration. 

```bash
sh runtime_analysis/runtime.sh -d [DATASET]
```
[DATASET] can be either [NYX] or [SCALE]

After running the above script, an *.RData file(s) will be produced giving the approprirate timing information of 
the training and prediction models.

### Replication of figures: how to run statistical prediction of compression ratios and the prediction validation 

The script ```graphs_paper_container.R```  saves the graphs presented in the paper and provides associated validation metrics (correlation and median absolute error percentage). 

The script ```graphs_paper_container.R``` will source the scripts  ```load_dataset_paper.R``` and ```functions_paper.R``` that respectively load the dataset of interest and perform the regression analysis (training and prediction in cross-validation). 
As a consequence the scripts  ```load_dataset_paper.R``` and ```functions_paper.R``` do not need to be run by the user. 

The script ```graphs_paper_container.R```  is run via the command:
```bash sh replicate.sh```

From running the script once, it will save all Figures 1, 3, 4 and 5 into .png files from the paper as well as corresponding validation metrics. 
Figure 2  is not saved as it only shows the data. same folder as r script and filename strcutrue figX_*.png with X the figure number reference in the paper
Numbers for Tables 2, 3 and 5 are printed. 
Refer to table 4 *david 
All printed validation metrics are save into a file named ```figure_replication.log```

In order to limit the container size to aid reproducibility, we only added a restrcited number of scientific datasets in the container and we rely on csv files from our porduction runs (saved as described above in the Section "How to compute statistical predictors on datasets"). 
More datasets are available on [SDRBench](https://sdrbench.github.io). 

