#ifndef DATA_H
#define DATA_H

#include "compress.h"

// uses dataset metadata provided by setup() to load the buffers
struct loader {
  virtual ~loader()=default;
  // loads pressio data buffer from file provided by metadata
  virtual pressio_data load() = 0;
  // loads pressio data buffer from cache 
  virtual pressio_data retrieve() = 0; 
  // returns specific file metadata
  virtual file_metadata* metadata() = 0;
  // only used if its a block
  virtual block_metadata* block_meta() = 0;
};

// gets metadata of a dataset folder
struct setup {
  virtual ~setup()=default;
  virtual std::vector<std::shared_ptr<loader>> set() = 0;
};
 


// // allows for block data to be stored
// struct sample_loader {
//   virtual ~sample_loader()=default;
//   // could potentially use fseek to load in data instaead of just cacheing the data
//   // virtual pressio_data load() = 0;
//   // loads block pressio data buffer from inputted cache 
//   virtual pressio_data retrieve() = 0; 
//   // returns specific block metadata
//   virtual file_metadata* metadata() = 0;
//   virtual block_metadata* block_metadata() = 0;
// };



// load data from setup() 
struct file_loader: public loader {
  file_loader(file_metadata* meta): meta(meta) {}

  block_metadata* block_meta() {
    block_metadata* data = (block_metadata*) calloc(1, sizeof(block_metadata));
    data->file = meta;
    data->total_blocks = 0;
    data->block_number = 0;
    data->block_size = meta->dims[0] * meta->dims[1] * meta->dims[2];
    data->block_dims = meta->dims;
    data->block_method = "none";
    return data;
  }
  file_metadata* metadata() {
    return meta;
  }

  pressio_data load() {
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

// load data from setup() 
struct sample_loader: public loader {
  sample_loader(block_metadata* meta): meta(meta) {}

  block_metadata* block_meta() {
    return meta;
  }
  
  file_metadata* metadata() {
    return meta->file;
  }

  pressio_data load() {
    pressio_data metadata = pressio_data::owning(meta->file->dtype, meta->block_dims);  
    auto input_ptr = meta->block_io->read(&metadata);
    if (!input_ptr) {
      std::cerr << meta->block_io->error_msg() << std::endl;
      exit(1);
    } else {
      cache = std::move(*input_ptr);
    }
    return cache;
  }

  // returns whats cached in input.
  pressio_data retrieve() {
    return cache;
  }
  // private:
  pressio_data cache;
  block_metadata* meta;
};



// samples the inputted 
struct sampler {
  virtual ~sampler()=default;
  virtual std::vector<std::shared_ptr<loader>> sample(usi method, usi total_blocks, size_t block_dims) = 0;
};

struct block_sampler: public sampler {
  block_sampler(std::vector<std::shared_ptr<loader>> buffers): buffers(buffers){}

  // uniform sampling 
  std::vector<std::shared_ptr<loader>> uniform_sample(usi total_blocks, size_t block_dims) {
    pressio library; 

    std::vector<std::shared_ptr<loader>> blocks;

    for (auto buffer : buffers){
      pressio_data input_pressio  = buffer->load(); 
      double *input = (double *) input_pressio.data();
      file_metadata* meta = buffer->metadata();
      
      size_t block_num = 1;
      // organize data into uniform blocks
      for (size_t i=0; i<meta->dims[0]; i+=(block_dims+meta->dims[0]/total_blocks))  // goes along x dimension 
        for (size_t j=0; j<meta->dims[1]; j+=(block_dims+meta->dims[0]/total_blocks)) // goes along y dimension
          for (size_t k=0; k<meta->dims[2]; k+=(block_dims+meta->dims[0]/total_blocks)) { // goes along z dimension
            // new block created
            double* block = new double[(int)std::pow(block_dims, 3)];
            for (size_t block_i=0; block_i<block_dims; block_i++)
              for (size_t block_j=0; block_j<block_dims; block_j++)
                for (size_t block_k=0; block_k<block_dims; block_k++)
                {
                  block[block_i*(int)std::pow(block_dims, 2) + block_j*block_dims + block_k] 
                  = input[(i+block_i)*meta->dims[1]*meta->dims[2] + (j+block_j)*meta->dims[2] + (k + block_k)];

                  if (block_num > total_blocks) goto STOP;
                }
                
            std::stringstream block_data_output;
            block_data_output << std::getenv("TMPDIR") << "/" << block_num << "_" << meta->filename << ".blk";
            pressio_io block_io = library.get_io("posix");
            block_io->set_options({{"io:path", block_data_output.str()}});

            //assumption blocks are cubes
            std::vector<size_t> block_dims_vec = {block_dims, block_dims, block_dims}; 
            pressio_data block_pressio = pressio_data::nonowning(meta->dtype, (void*)block, block_dims_vec);  
            block_io->write(&block_pressio);

            block_metadata* data = (block_metadata*) calloc(1, sizeof(block_metadata));
            // copy over file metadata
            data->file = meta;

            // determine block metadata
            data->block_io       = block_io;
            data->block_filepath = block_data_output.str();
            data->block_dims     = block_dims_vec;
            data->block_size     = (int)std::pow(block_dims, 3); 
            data->block_method   = method;
            data->block_number   = block_num;
            data->total_blocks   = total_blocks;

            blocks.emplace_back(std::make_shared<sample_loader>(data));
            block_num++;
            free(block);
          }
    }
STOP:
    return blocks;
  }

  std::vector<std::shared_ptr<loader>> random_sample(usi total_blocks, size_t block_dims) {
    std::vector<std::shared_ptr<loader>> blocks;

    return blocks;
  }

  std::vector<std::shared_ptr<loader>> multigrid_sample(usi total_blocks, size_t block_dims) {
    std::vector<std::shared_ptr<loader>> blocks;

    return blocks;
  }

  std::vector<std::shared_ptr<loader>> sample(usi method_d, usi total_blocks, size_t block_dims) {
    std::vector<std::shared_ptr<loader>> blocks;
    switch (method_d) {
      case(UNIFORM):
        method = "uniform";
        blocks = uniform_sample(total_blocks, block_dims);
        break;
      case(RANDOM):
        method = "random";
        blocks = random_sample(total_blocks, block_dims);
        break;
      case(MULTIGRID):
        method = "multigrid";
        blocks = multigrid_sample(total_blocks, block_dims);
        break;
      default:
        break;
    }
    return blocks;
  }
  std::vector<std::shared_ptr<loader>> buffers;
  std::string method;
};


typedef std::shared_ptr<loader> buffer;
typedef std::vector<buffer> dataset;
typedef std::shared_ptr<loader> sample;
typedef std::vector<buffer> samples;


#endif