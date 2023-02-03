#ifndef DATA_H
#define DATA_H

#define UNIFORM   1555
#define RANDOM    1556
#define MULTIGRID 1557

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

// samples the inputted 
struct sampler {
  virtual ~sampler()=default;
  virtual std::vector<std::shared_ptr<loader>> sample(usi method, usi total_blocks, size_t block_dims) = 0;
};



// whole file loader (can load velocityx.f32 for example)
struct file_loader: public loader {
    file_loader(file_metadata* meta): meta(meta){}
    block_metadata* block_meta();
    file_metadata* metadata();
    pressio_data load();
    pressio_data retrieve();
    // private
    pressio_data input;
    file_metadata* meta;
};
// sets up file_metadata data structure for all the files loaded by file_loader
struct dataset_setup: public setup{
    dataset_setup(cmdline_args* args): args(args){}
    std::vector<std::shared_ptr<loader>> set();
    // private
    cmdline_args* args;
};
// loads samples (similar to file_loader but for sampling)
struct sample_loader: public loader{
    sample_loader(block_metadata* meta): meta(meta){}
    block_metadata* block_meta();
    file_metadata* metadata();
    pressio_data load();
    pressio_data retrieve();
    // private
    pressio_data cache;
    block_metadata* meta;
};
// samples the blocks and writes each block into a file within TMPDIR
struct block_sampler: public sampler{
    block_sampler(std::vector<std::shared_ptr<loader>> buffers): buffers(buffers){}
    std::vector<std::shared_ptr<loader>> sample(usi method_d, usi total_blocks, size_t block_dims);
    // private
    std::vector<std::shared_ptr<loader>> uniform_sample(usi total_blocks, size_t block_dims);
    std::vector<std::shared_ptr<loader>> random_sample(usi total_blocks, size_t block_dims);
    std::vector<std::shared_ptr<loader>> multigrid_sample(usi total_blocks, size_t block_dims);
    std::vector<std::shared_ptr<loader>> buffers;
    std::string method;
};

typedef std::shared_ptr<loader> buffer;
typedef std::vector<buffer>     dataset;
typedef std::shared_ptr<loader> sample;
typedef std::vector<buffer>     samples;

#endif