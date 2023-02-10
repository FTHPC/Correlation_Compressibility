#include "compress.h"
#include "data.h"

/*
  file_loader function definitions
*/

block_metadata* file_loader::block_meta() {
  return NULL;
}
file_metadata* file_loader::metadata() {
  return meta;
}

pressio_data file_loader::load() {
  pressio_data metadata = pressio_data::owning(meta->dtype, meta->dims);  
  auto input_ptr = meta->io->read(&metadata);
  if (!input_ptr) {
    std::cerr << meta->io->error_msg() << std::endl;
    exit(1);
  } else {
    input = std::move(*input_ptr);
  }
  return input;
}

// returns global file input
pressio_data file_loader::load_global() {
  return input;
}

// returns whats cached in input. If load() hasn't been called, return is NULL
pressio_data file_loader::retrieve() {
  return input;
}

// returns cached global file input
pressio_data file_loader::retrieve_global(){
  return input;
}




/*
  dataset_setup function definitions
*/
std::vector<std::shared_ptr<loader>> dataset_setup::set() {
  pressio library;
  bool stop = false;
  std::vector<std::shared_ptr<loader>> loaders;
  for (const auto & entry : std::filesystem::directory_iterator(args->directory+'/'+args->dataset)) {
    std::string filename;
    if (stop) break;
    if (args->filename.length()) {
      filename = args->filename; 
      stop = true;
    } else filename = entry.path().filename().string();


    file_metadata* data = (file_metadata*) calloc(1, sizeof(file_metadata));
    data->filename  = filename;
    data->filepath  = args->directory+'/'+args->dataset+'/'+filename; 
    data->dataset   = args->dataset;
    data->dims      = args->dims; 
    data->directory = args->dataset;

    if (!args->dtype.compare("float64"))
      data->dtype = pressio_double_dtype;
    else if (!args->dtype.compare("float32"))
      data->dtype = pressio_float_dtype;
    else { 
      std::cerr << "Invalid dtype exiting" << std::endl;
      printHelp();
    }
  
    size_t lastindex = data->filename.find_last_of('.'); 

    if (!data->filename.substr(lastindex, lastindex + 3).compare(".h5")){
      // if hdf5 file
      if (!data->filename.substr(lastindex - 4, lastindex + 3).compare(".dat.h5"))
        // .dat.h5 follows our naming scheme for dataset names of hdf5 files
        // ex: velocityx.d64.dat.h5 will have a dataset name of velocityx.d64.dat
        data->dataset_name = data->filename.substr(0, lastindex); 
      else data->dataset_name = 'Z'; // 'Z' is used for our generated Gaussian samples

      data->io = library.get_io("hdf5");
      data->io->set_options({
          {"io:path", data->filepath},
          {"hdf5:dataset", data->dataset_name}
          });
    } else {
      // if posix binary file
      data->io = library.get_io("posix");
      data->io->set_options({
          {"io:path", data->filepath}
          });
    }
    loaders.emplace_back(std::make_shared<file_loader>(data));
  }
  return loaders;
}