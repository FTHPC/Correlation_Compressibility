# Correlation_Compressibility
## First time setup:

Clone the repo
```bash
git clone https://github.com/FTHPC/Correlation_Compressibility $HOME/compression
```

### Using Docker
There are two options when using docker. The first option is creating the image with the following command:
```bash
docker build -t compress_docker .
```

The second option is downloading the image from the hosting site.
```bash
wget placeholder.tar.gz
```

Start a container from the image
```bash
docker run --publish 8000:8000 compress_docker
```

### Without Docker
By default, it is recommended to to follow the install locations that are indicated on the top of ```scripts/run.sh```
and the top of ```config.json```. These two files provide the configuration options to get the program running.

Spack is recommend to be installed in the following location:
```bash
$HOME/spack/
```
This Github is recommended to be installed in the following location: 
```bash
$HOME/compression/
```
A dataset folder called 'datasets' is recommended to be in the following location:
```bash
$HOME/compression/datasets
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
    spack env activate $HOME/compression 
    spack install
```
These commands will install the environment. The environment only needs to be installed once.

## To Run training and prediction timing analysis demonstration.

In order to run the timing analysis, a dataset must be specified.
There are two datasets setup within this demonstration. 

```bash
sh runtime_analysis/runtime.sh -d [DATASET]
```
[DATASET] can be either [NYX] or [SCALE]

After running the above script, an *.RData file(s) will be produced giving the approprirate timing information of 
the training and prediction models.

## To Run the code to before statistical analysis on datasets


In order to run the statistical analysis, a dataset and a configuration file must be specified.
TEST is a dataset that is specified within the config.json file. 

```bash
sh scripts/run.sh -c config.json -d TEST
```

The command above performs the analysis an writes output to the output file specified in the configuration file.
This will use local hardware without a scheduler. Use ```-n``` to specify the MPI Processors on your local system. 
It is recommended that this value to match your CPU core count.

If one has the PBS scheduler, feel free to use flags ```-p``` or ```-s``` for job execution.
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
    "parse_info"        : "type of parsing needed: 'None', 'slice', 'gaussian', 'gaussian_multi', 'spatialweight_fixed', 'spatialweight_random', or 'scalarweight_random'",
    "dataset_name"      : "necessary accessing 2D HDF5 files: 'standard' if not custom. custom EX: 'Z'"
} 
```
