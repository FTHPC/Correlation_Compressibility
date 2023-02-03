#include "compress.h"
#include "data.h"

/*
  sample_loader function definitions
  used to setup the files for sampling
*/
block_metadata* sample_loader::block_meta() {
  return meta;
}

file_metadata* sample_loader::metadata() {
  return meta->file;
}

pressio_data sample_loader::load() {
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
pressio_data sample_loader::retrieve() {
  return cache;
}



/*
  block_sampler function definitions
  sampling methods
*/
std::vector<std::shared_ptr<loader>> block_sampler::sample(usi method_d, usi total_blocks, size_t block_dims) {
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


std::vector<std::shared_ptr<loader>> block_sampler::uniform_sample(usi total_blocks, size_t block_dims) {
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

std::vector<std::shared_ptr<loader>> block_sampler::random_sample(usi total_blocks, size_t block_dims) {
  std::vector<std::shared_ptr<loader>> blocks;

  return blocks;
}

std::vector<std::shared_ptr<loader>> block_sampler::multigrid_sample(usi total_blocks, size_t block_dims) {
  std::vector<std::shared_ptr<loader>> blocks;

  return blocks;
}

