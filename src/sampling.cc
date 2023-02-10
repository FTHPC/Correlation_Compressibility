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
    block_data = std::move(*input_ptr);
  }
  return block_data;
}

// returns global file input
pressio_data sample_loader::load_global() {
  pressio_data metadata = pressio_data::owning(meta->file->dtype, meta->file->dims);  
  auto input_ptr = meta->file->io->read(&metadata);
  if (!input_ptr) {
    std::cerr << meta->file->io->error_msg() << std::endl;
    exit(1);
  } else {
    file_data = std::move(*input_ptr);
  }
  return file_data;
}

// returns cached block file input
pressio_data sample_loader::retrieve(){
  return block_data;
}


// returns cached global file input
pressio_data sample_loader::retrieve_global(){
  return file_data;
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
    for (size_t i=0; i<=meta->dims[0]-block_dims; i+=block_dims)  // goes along x dimension 
      for (size_t j=0; j<=meta->dims[1]-block_dims; j+=block_dims) // goes along y dimension
        for (size_t k=0; k<=meta->dims[2]-block_dims; k+=block_dims) { // goes along z dimension
          // new block created
          if (block_num > total_blocks) goto STOP;
          double* block = new double[(int)std::pow(block_dims, 3)];
          for (size_t block_i=0; block_i<block_dims; block_i++)
            for (size_t block_j=0; block_j<block_dims; block_j++)
              for (size_t block_k=0; block_k<block_dims; block_k++)
              {
                block[block_i*(int)std::pow(block_dims, 2) + block_j*block_dims + block_k] 
                = input[(i+block_i)*meta->dims[1]*meta->dims[2] + (j+block_j)*meta->dims[2] + (k + block_k)];
              }
              
          std::stringstream block_data_output;
          block_data_output << std::getenv("TMPDIR") << "/" << block_num << "_" << meta->filename << ".blk";
          pressio_io block_io = library.get_io("posix");
          block_io->set_options({{"io:path", block_data_output.str()}});

          //assumption blocks are cubes
          std::vector<size_t> block_dims_vec = {block_dims, block_dims, block_dims}; 
          std::vector<size_t> block_loc_vec  =  {i, j, k}; 
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
          data->block_loc      = block_loc_vec;
          data->block_number   = block_num;
          data->total_blocks   = total_blocks;

          blocks.emplace_back(std::make_shared<sample_loader>(data));
          block_num++;
          free(block);
        }
    STOP:
    continue;
  }
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

