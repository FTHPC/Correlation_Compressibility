#include "compress.h"
#include "data.h"

/*
  file_loader function definitions
*/

block_metadata* file_loader::block_meta() {
  return NULL;
}
file_metadata* file_loader::metadata() {
  return this->meta;
}

pressio_data file_loader::load() {
  if (this->input.has_data()) {
    // returns whats cached in input.
    return this->input;
  }

  pressio_data metadata = pressio_data::owning(this->metadata()->dtype, 
                                               this->metadata()->dims);  
  auto input_ptr = this->metadata()->io->read(&metadata);
  if (!input_ptr) {
    std::cerr << this->metadata()->io->error_msg() << std::endl;
    exit(1);
  } else {
    this->input = std::move(*input_ptr);
  }
  return this->input;
}

// returns global file input
pressio_data file_loader::load_global() {
  return this->load();
}

void file_loader::release() {
  this->input.~pressio_data();
}



/*
  dataset_setup function definitions
*/
std::vector<std::shared_ptr<loader>> dataset_setup::set() {
  pressio library;
  bool stop = false;
  
  for (const auto & entry : std::filesystem::directory_iterator(args->directory+'/'+args->dataset)) {
    std::string filename;
    if (stop) break;
    if (args->filename.length()) {
      filename = args->filename; 
      stop = true;
    } else filename = entry.path().filename().string();

    //std::cout << filename << std::endl;

    if (!filename.compare("sampled")) continue;  

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
    this->loaders.emplace_back(std::make_shared<file_loader>(data));
  }
  return this->loaders;
}

void dataset_setup::release() {
  for (auto buff : this->loaders) {
    buff->release();
  }
}
