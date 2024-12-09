/*
   analysis.cpp
   Performs compression of 2D and 3D datasets using Libpressio
   Computes estimation statistics
   Clemson University and Argonne National Laboratory

   Libpressio https://robertu94.github.io/libpressio
   */

#include "compress.h"
#include "data.h"

#include <libdistributed/libdistributed_work_queue.h>
#include <libpressio_ext/cpp/serializable.h>
#include <libpressio_ext/cpp/printers.h>
#include <libpressio.h>
#include <libpressio_ext/io/pressio_io.h>
#include <libpressio_meta.h>
#include <pressio_version.h>
#include <mpi.h>

using namespace std::string_literals;



static std::array comps = {
    "sz"s,
    "sz3"s,
    "zfp"s,
    "mgard"s,
    "tthresh"s,
    "digit_rounding"s,
    "fpzip"s,
    "bit_grooming"s,
    "sperr"s
};

pressio_options make_config(std::string compressor_id, std::string boundmode, float bound, int dtype)
{
  usi prec = 0;
  if (!compressor_id.compare("sz") ||
      !compressor_id.compare("sz3") ||
      !compressor_id.compare("zfp") ||
      !compressor_id.compare("mgard") ||
      !compressor_id.compare("tthresh") ||
      !compressor_id.compare("linear_quantizer") ||
      !compressor_id.compare("sperr"))
  {
    return {{boundmode, bound}};
  }
  else if (!compressor_id.compare("bit_grooming"))
  {
    if (bound == 1E-2)
      prec = 1;
    else if (bound == 1E-3)
      prec = 1;
    else if (bound == 1E-4)
      prec = 1;
    else if (bound == 1E-5)
      prec = 3;
    return {{"bit_grooming:n_sig_digits"s, prec},
            {"bit_grooming:error_control_mode_str"s, "NSD"s},
            {"bit_grooming:mode_str"s, "BITGROOM"s}};
  }
  else if (!compressor_id.compare("digit_rounding"))
  {
    if (bound == 1E-2)
      prec = 2;
    else if (bound == 1E-3)
      prec = 6;
    else if (bound == 1E-4)
      prec = 11;
    else if (bound == 1E-5)
      prec = 11;
    return {{"digit_rounding:prec"s, prec}};
  }
  // fpzip requires even prec values if the data is float64
  // prec of 4 is the minimum for float64
  else if (!compressor_id.compare("fpzip"))
  {
    if (bound == 1E-2)
      prec = (dtype == pressio_float_dtype) ? 2 : 4;
    else if (bound == 1E-3)
      prec = 10;
    else if (bound == 1E-4)
      prec = (dtype == pressio_float_dtype) ? 13 : 14;
    else if (bound == 1E-5)
      prec = (dtype == pressio_float_dtype) ? 15 : 16;
    return {{"fpzip:prec"s, prec}};
  }
  else
  {
    std::cerr << "ERROR: Unknown Configuration; Exiting 32" << std::endl;
    exit(32);
  }
}

int main(int argc, char *argv[])
{
  // init stuff
  MPI_Init(&argc, &argv);
  int rank;
  int n_procs;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &n_procs);


  float error_high = 1e-2;
  float error_low = 1e-5;

  auto args = parse_args(argc, argv);
  if (args->error != 0)
  {
    error_high = args->error;
    error_low = args->error;
  }

  // store large buffers (velocityx.d64, xxx.d64, xxx.d64) in a loader
  auto loaders = std::make_unique<dataset_setup>(args);
  dataset buffers = loaders->set();
 
  /*
  // length of the buffers list
  size_t iterations = buffers.size();
  */
  
  // adding a barrier
  MPI_Barrier(MPI_COMM_WORLD);

  // utilizing pressio library
  libpressio_register_all();
  pressio library;
  pressio_data input;
  //pressio_data input_global;
  pressio_options analysis_results;

  size_t block_dims = args->block_size;

  void *block = NULL;

  for (auto buffer : buffers) {
    
    pressio_data input_pressio = buffer->load();
    //input_global = buffer->load();
    void *input_global = NULL;
    
    file_metadata *meta = buffer->metadata();
    auto buff_type = input_pressio.dtype();
    //block_metadata *block_meta = block->block_meta();
   
    // check for sanity
    if (buff_type != meta->dtype) {
      std::cerr << "Block dtype does not align with input dtype" << std::endl;
      exit(32);
    }

    // load global data
    if (buff_type == pressio_float_dtype) {
      input_global = (float *) input_pressio.data();
    } else {
      input_global = (double *) input_pressio.data();
    }

    pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
    pressio_compressor analysis = library.get_compressor("noop");
    pressio_options metrics_options = {
      {"pressio:metric","data_analysis"s},
      {"data_analysis:file_meta",meta}, 
      //{"data_analysis:block_meta",block_meta}, //TODO figure out how to separate this from metric
    };
    analysis->set_options(metrics_options);

    //perform analysis
    analysis->compress(&input_pressio, &compressed);
    analysis_results = analysis->get_metrics_results();

    //static const std::array bound_types{"pressio:abs"s, "pressio:rel"s};
    static const std::array bound_types{"pressio:abs"s};
    static const std::vector metrics_composites{"error_stat"s, "size"s, "nanotime"s};

    size_t xLen = floor(meta->dims[0] / block_dims);
    size_t yLen = floor(meta->dims[1] / block_dims);
    size_t zLen = floor(meta->dims[2] / block_dims);
    size_t max_blocks = xLen * yLen * zLen;

    std::vector<size_t> block_dims_vec = {block_dims, block_dims, block_dims};
    
    size_t block_num = rank+1;
    while(block_num <= max_blocks) {
      if (buff_type == pressio_float_dtype) {
        block = new float[(int)std::pow(block_dims,3)];
        assert(block != NULL);
      } else {
        block = new double[(int)std::pow(block_dims,3)];
      }

      size_t i = ((size_t)(floor((block_num-1) / (xLen * yLen))) % zLen) * block_dims;
      size_t j = ((size_t)floor((block_num-1) / xLen) % yLen) * block_dims;
      size_t k = (size_t)(((block_num-1) % xLen) * block_dims);
      
      std::vector<size_t> block_loc_vec = {i, j, k};

      for (size_t block_i=0; block_i < block_dims; block_i++) {
        for (size_t block_j=0; block_j < block_dims; block_j++) {
          for (size_t block_k = 0; block_k < block_dims; block_k++) {

            uint32_t block_idx = block_i*(int)std::pow(block_dims, 2) + block_j*block_dims + block_k;
            assert(block_idx < std::pow(block_dims,3));
            uint32_t input_idx = (i+block_i)*meta->dims[1]*meta->dims[2] + (j+block_j)*meta->dims[2] + (k + block_k);
            assert(input_idx < (meta->dims[0] * meta->dims[1] * meta->dims[2]));

            if (buff_type == pressio_float_dtype) {
              ((float*)block)[block_idx] = ((float*)input_global)[input_idx];
            } else {
              ((double*)block)[block_idx] = ((double*)input_global)[input_idx];
            }
            
          }
        }
      }
      //convert data block to pressio type
      pressio_data block_pressio = pressio_data::nonowning(meta->dtype, (void*)block, block_dims_vec);
      //pressio_data block_pressio = pressio_data::copy(meta->dtype, (void*)block, block_dims_vec);

      block_metadata *data = (block_metadata*) calloc(1, sizeof(block_metadata));
      //copy over file metadata -- not sure if needed
      data->file = meta;
      data->block_dims = block_dims_vec;
      data->block_size = (int)std::pow(block_dims,3);
      data->block_method = args->block_method;
      data->block_loc = block_loc_vec;
      data->block_number = block_num;
      data->total_blocks = max_blocks;

      for (auto const &bound_type : bound_types) {

        //do analysis here with block
        for (double bound = error_low; bound <= error_high; bound *= 10)
        {
          auto options = make_config(args->comp, bound_type, bound, input.dtype());
          
          pressio_options global_results;
          pressio_compressor global_compressor = library.get_compressor("pressio");
          pressio_data compressed_global = pressio_data::empty(pressio_byte_dtype, {});
          pressio_data decompressed_global = pressio_data::owning(input_pressio.dtype(), input_pressio.dimensions());

          if (!args->comp.compare("bit_grooming")) {
            unsigned int prec = 1;
            if (bound <= 1e-5) { prec = 3; }
              global_compressor->set_options({
                  {"pressio:compressor",args->comp},
                  {"bit_grooming:n_sig_digits"s,prec},
                  {"bit_grooming:error_control_mode_str"s, "NSD"s},
                  {"bit_grooming:mode_str"s, "BITGROOM"s},
                  {"pressio:metric","composite"s},
                  {"composite:plugins",metrics_composites}
              });
          } else {
            global_compressor->set_options({
                {"pressio:compressor",args->comp},
                {bound_type, bound},
                {"pressio:metric","composite"s},
                {"composite:plugins",metrics_composites}
            });
          }
          global_compressor->compress(&input_pressio, &compressed_global);
          global_compressor->decompress(&compressed_global, &decompressed_global);
          pressio_options global_results_unsorted = global_compressor->get_metrics_results();
          global_results = {
            {"global:value_std", global_results_unsorted.get("error_stat:value_std")},
            {"global:compression_ratio", global_results_unsorted.get("size:compression_ratio")},
            {"global:time_compress",global_results_unsorted.get("nanotime:compress")}};

          pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
          pressio_data decompressed = pressio_data::owning(input.dtype(), input.dimensions());
          pressio_compressor compressor = library.get_compressor("pressio");
          compressor->set_options({
              {"pressio:compressor",args->comp},
              {bound_type,bound},
              {"pressio:metric","composite"s},
              {"composite:plugins",metrics_composites}
          });

          compressor->compress(&block_pressio, &compressed);
          compressor->decompress(&compressed, &decompressed);
          pressio_options results = compressor->get_metrics_results();

          pressio_compressor noop = library.get_compressor("noop");
          noop->set_options({
              {"pressio:metric", "compress_analysis"s},
              {"info:error_bound",bound},
              {"info:bound_type",bound_type},
              {"info:compressor",args->comp}
          });
          noop->compress(&block_pressio, &compressed);
          pressio_options compress_analysis = noop->get_metrics_results();

          results.copy_from(compress_analysis);
          results.copy_from(analysis_results);
          results.copy_from(global_results);
          exportcsv(results, args->output);

        }
      }
      block_num += n_procs; 
    }
    MPI_Barrier(MPI_COMM_WORLD);
  }
  MPI_Barrier(MPI_COMM_WORLD);
  int retcode = MPI_Finalize();
  exit(retcode);
}
