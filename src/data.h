#ifndef DATA_H
#define DATA_H

#include "compress.h"

typedef struct file_metadata{
  std::string           filename;
  std::string           directory;
  std::string           filepath; 
  std::string           dataset;
  std::vector<size_t>   dims;
  pressio_dtype         dtype;
  std::string           dataset_name;
  pressio_io            io;
} file_metadata;


// uses dataset metadata provided by setup()
struct loader {
  virtual ~loader()=default;
  // loads pressio data buffer from file provided by metadata
  virtual pressio_data load() = 0;
  // loads pressio data buffer from cache 
  virtual pressio_data retrieve() = 0; 
  // returns specific file metadata
  virtual file_metadata* metadata() = 0;
};

// gets metadata of a dataset folder
struct setup {
  virtual ~setup()=default;
  virtual std::vector<std::shared_ptr<loader>> set() = 0;
};
 

// samples the inputted 
struct sampler {
  virtual ~sampler()=default;
  virtual std::vector<pressio_data> sample(std::vector<std::shared_ptr<loader>> const&) = 0;
};



// load data from setup() 
struct file_loader: public loader {
  file_loader(file_metadata* meta): meta(meta) {}

  file_metadata* metadata() {
    return meta;
  }

  pressio_data load() {
    std::cout << meta->filepath << std::endl;
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

  // returns whats cached in input. If load() hasn't been called, return is NULL
  pressio_data retrieve() {
    return input;
  }
  // private:
  pressio_data input;
  file_metadata* meta;
};

struct dataset_setup: public setup {
  dataset_setup(cmdline_args* args): args(args){}
  std::vector<std::shared_ptr<loader>> set() {
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
  cmdline_args* args;
};



struct block_sampler: public sampler {
  block_sampler(std::vector<std::shared_ptr<loader>> buffers, usi method): buffers(buffers), method(method){}
  
  std::vector<pressio_data> uniform_sample(std::vector<std::shared_ptr<loader>> buffers) {
    std::vector<pressio_data> blocks;
    for (auto buffer : buffers){
      pressio_data input = buffer->retrieve(); 

      
      blocks.emplace_back(input);
      buffer->~loader();
    }
    return blocks;
  }

  std::vector<pressio_data> random_sample(std::vector<std::shared_ptr<loader>> buffers) {
    std::vector<pressio_data> blocks;

    return blocks;
  }

  std::vector<pressio_data> multigrid_sample(std::vector<std::shared_ptr<loader>> buffers) {
    std::vector<pressio_data> blocks;

    return blocks;
  }

  std::vector<pressio_data> sample(std::vector<std::shared_ptr<loader>> buffers, usi method) {
    std::vector<pressio_data> blocks;
    switch (method) {
      case(UNIFORM):
        blocks = uniform_sample(buffers);
        break;
      case(RANDOM):
        blocks = random_sample(buffers);
        break;
      case(MULTIGRID):
        blocks = multigrid_sample(buffers);
        break;
      default:
        break;
    }
    return blocks;
  }

  std::vector<std::shared_ptr<loader>> const& buffers;
  usi method;
};



typedef std::shared_ptr<loader> buffer;
typedef std::vector<buffer> dataset;


#endif