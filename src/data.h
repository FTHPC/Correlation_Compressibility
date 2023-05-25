#ifndef DATA_H
#define DATA_H

#define NONE      1554
#define UNIFORM   1555
#define RANDOM    1556
#define MULTIGRID 1557

// uses dataset metadata provided by setup() to load the buffers
struct loader {
  virtual ~loader()=default;
  // loads pressio data buffer from file provided by metadata
  virtual pressio_data load() = 0;
  virtual pressio_data load_global() = 0;
  // returns specific file metadata
  virtual file_metadata* metadata() = 0;
  // only used if its a block
  virtual block_metadata* block_meta() = 0;
  // free data
  virtual void release() = 0; 
};

// gets metadata of a dataset folder
struct setup {
  virtual ~setup()=default;
  virtual std::vector<std::shared_ptr<loader>> set() = 0;
  virtual void release() = 0;
};

// samples the inputted 
struct sampler {
  virtual ~sampler()=default;
  virtual std::vector<std::shared_ptr<loader>> sample(int rank, usi method, usi total_blocks, size_t block_dims) = 0;
};

// sets up file_metadata data structure for all the files loaded by file_loader
struct dataset_setup: public setup{
    dataset_setup(cmdline_args* args): args(args){}
    std::vector<std::shared_ptr<loader>> set();
    void release();
    
    private:
    cmdline_args* args;
    std::vector<std::shared_ptr<loader>> loaders;
};

// whole file loader (can load velocityx.f32 for example)
struct file_loader: public loader {
    file_loader(file_metadata* meta): meta(meta){}
    block_metadata* block_meta();
    file_metadata* metadata();
    pressio_data load();
    pressio_data load_global();
    void release();

    private:
    pressio_data input;
    file_metadata* meta;
};

// loads samples (similar to file_loader but for sampling)
struct sample_loader: public loader {
    sample_loader(block_metadata* meta): meta(meta){}
    block_metadata* block_meta();
    file_metadata* metadata();
    pressio_data load();
    pressio_data load_global();
    void release();

    private:
    pressio_data block_data;
    pressio_data file_data;
    block_metadata* meta;
};
// samples the blocks and writes each block into a file within TMPDIR
struct block_sampler: public sampler{
    block_sampler(std::vector<std::shared_ptr<loader>> buffers): buffers(buffers){}

    std::vector<std::shared_ptr<loader>> sample(int rank, usi method_d, usi total_blocks, size_t block_dims);
    
    private:
    void uniform_sample(usi total_blocks, size_t block_dims);
    void random_sample(usi total_blocks, size_t block_dims);
    void multigrid_sample(usi total_blocks, size_t block_dims);
    std::vector<std::shared_ptr<loader>> buffers;
    std::vector<std::shared_ptr<loader>> blocks;
    std::string method;
    int rank;
};


// There are multiple samples in one buffer (if sampling used)
// There are multiple buffers in a dataset (velocityx.d64, xxx.d64, yyy.d64, etc.)

// buffer and sample are the same type
typedef std::shared_ptr<loader> buffer;
typedef std::shared_ptr<loader> sample;

// dataset and samples are the same type
typedef std::vector<buffer>     dataset;
typedef std::vector<buffer>     samples;

#endif