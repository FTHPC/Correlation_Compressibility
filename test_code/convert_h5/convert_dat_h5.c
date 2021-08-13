//convert binary data into hdf5 file format. The directory is changed within the Makefile.
//must have libpressio loaded (dependancy)
//only converts a singular file unlike the python equivalent
#include <stdio.h>
#include <stdlib.h>
#include <libpressio.h>
#include <libpressio_ext/io/posix.h>
#include <libpressio_ext/io/hdf5.h>

int main(int argc, char *argv[])
{
	typedef char param[100];
	//change these files based on the file	
	param file_input = "velocityx.d64";
	param file_output = "velocityx.d64.dat.h5";
	param dataset_name = "velocityx.d64.dat";
	param file_path;

	//read in the dataset
	size_t dims[] = {256, 384, 384};
	size_t ndims = sizeof(dims)/sizeof(dims[0]);
	sprintf(file_path, "%s%s", DATADIR, file_input);
	printf("%s\n",file_path);
	struct pressio_data* metadata = pressio_data_new_empty(pressio_double_dtype, ndims, dims);
	struct pressio_data* input_data = pressio_io_data_path_read(metadata, file_path);

 	if (pressio_io_data_path_h5write(input_data, file_output, dataset_name)){
		printf("There was an error in converting the file. \nPlease make sure the parameters are correct. \n");
	}
 }
