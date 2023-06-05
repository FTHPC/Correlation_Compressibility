#include "compress.h"
#include "data.h"

/*
  sample_loader function definitions
  used to setup the files for sampling
*/
// block file metadata
block_metadata* sample_loader::block_meta() {
  return this->meta;
}

// global buffer file metadata
file_metadata* sample_loader::metadata() {
  return this->meta->file;
}

pressio_data sample_loader::load() {
  if (this->block_data.has_data()) {
    // returns whats cached in file_data.
    return this->block_data;
  }

  pressio_data metadata = pressio_data::owning(this->metadata()->dtype,
                                               this->block_meta()->block_dims);  
  auto input_ptr = meta->block_io->read(&metadata);
  if (!input_ptr) {
    std::cerr << meta->block_io->error_msg() << std::endl;
    exit(1);
  } else {
    this->block_data = std::move(*input_ptr);
  }
  return this->block_data;
}

// returns global file input
pressio_data sample_loader::load_global() {
  if (this->file_data.has_data()) {
    // returns whats cached in file_data.
    return this->file_data;
  }

  pressio_data metadata = pressio_data::owning(this->metadata()->dtype, 
                                              this->metadata()->dims);  
  auto input_ptr = this->metadata()->io->read(&metadata);
  if (!input_ptr) {
    std::cerr << this->metadata()->io->error_msg() << std::endl;
    exit(1);
  } else {
    this->file_data = std::move(*input_ptr);
  }
  return this->file_data;
}


void sample_loader::release() {
  this->file_data.~pressio_data();
  this->block_data.~pressio_data();
}

/*
  block_sampler function definitions
  sampling methods
*/
std::vector<std::shared_ptr<loader>> block_sampler::sample(int rank, usi method_d, usi total_blocks, size_t block_dims) {
  this->rank = rank;
  switch (method_d) {
    case(UNIFORM):
      this->method = "uniform";
      uniform_sample(total_blocks, block_dims);
      break;
    case(RANDOM):
      this->method = "random";
      random_sample(total_blocks, block_dims);
      break;
    case(MULTIGRID):
      this->method = "multigrid";
      multigrid_sample(total_blocks, block_dims);
      break;
    default:
      break;
  }
  return this->blocks;
}


void block_sampler::uniform_sample(usi total_blocks, size_t block_dims) {
  pressio library; 

  void *block = NULL;

  for (auto buffer : buffers){
    pressio_data input_pressio = buffer->load(); 
    void *input = NULL;

    file_metadata* meta = buffer->metadata();
    auto buff_type = input_pressio.dtype();

    // check for sanity
    if (buff_type != meta->dtype) {
      std::cerr << "Block dtype does not allign with input dtype" << std::endl;
      exit(32);
    }
 
    if (buff_type == pressio_float_dtype) {
      input = (float *) input_pressio.data();
    } else {
      input = (double *) input_pressio.data();
    }

    size_t block_num = 1;
    // organize data into uniform blocks
    for (size_t i=0; i<meta->dims[0]-block_dims; i+=block_dims)  // goes along x dimension 
      for (size_t j=0; j<meta->dims[1]-block_dims; j+=block_dims) // goes along y dimension
        for (size_t k=0; k<meta->dims[2]-block_dims; k+=block_dims) { // goes along z dimension
          // new block created
          if (block_num > total_blocks) goto STOP;
          if (this->rank == 0) 
          {
            if (buff_type == pressio_float_dtype) {
              block = new float[(int)std::pow(block_dims, 3)];
            } else {
              block = new double[(int)std::pow(block_dims, 3)];
            }
            for (size_t block_i=0; block_i<block_dims; block_i++) {
              for (size_t block_j=0; block_j<block_dims; block_j++) { 
                for (size_t block_k=0; block_k<block_dims; block_k++) {   
                  uint32_t block_idx = block_i*(int)std::pow(block_dims, 2) + block_j*block_dims + block_k;
                  uint32_t input_idx = (i+block_i)*meta->dims[1]*meta->dims[2] + (j+block_j)*meta->dims[2] + (k + block_k);
                  if (buff_type == pressio_float_dtype) {
                    ((float*)block)[block_idx] = ((float*)input)[input_idx];
                  } else {
                    ((double*)block)[block_idx] = ((double*)input)[input_idx];
                  }
                }
              }
            }
          }
          std::stringstream block_data_output;
          block_data_output << std::getenv("TMPDIR") << "/" << block_num << "_" << meta->filename << ".blk";
          pressio_io block_io = library.get_io("posix");
          block_io->set_options({{"io:path", block_data_output.str()}});

          //assumption blocks are cubes
          std::vector<size_t> block_dims_vec = {block_dims, block_dims, block_dims}; 
          std::vector<size_t> block_loc_vec  =  {i, j, k}; 
        
          if (this->rank == 0) 
          {
            pressio_data block_pressio = pressio_data::nonowning(meta->dtype, (void*)block, block_dims_vec);
            block_io->write(&block_pressio);
            free(block);
            block = NULL;
          }

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
          // this isn't accurate if the loop iterations don't allow it
          // under STOP: is a fix
          data->total_blocks   = total_blocks;
          // emplace meta/file data for block created
          this->blocks.emplace_back(std::make_shared<sample_loader>(data));
          block_num++;
        }
    STOP:
    // if the previously counted total doesn't allign with actual total
    if (block_num < total_blocks) {
      for (auto b : this->blocks){
        b->block_meta()->total_blocks = block_num;
      }
    }
  }
}

void block_sampler::random_sample(usi total_blocks, size_t block_dims) {

}

void block_sampler::multigrid_sample(usi total_blocks, size_t block_dims) {

}

