/*
   prediction.cpp
   Performs compression on samples of 3D datasets 
   using Libpressio. Computes regression coefficients
   for compression ratio estimation.
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

unsigned int get_prec(std::string compressor_id, std::string boundmode, float bound, int dtype)
{
  unsigned int prec = 0;
  if (!compressor_id.compare("bit_grooming"))
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
 
  // adding a barrier
  MPI_Barrier(MPI_COMM_WORLD);

  // utilizing pressio library
  libpressio_register_all();
  pressio library;
  pressio_data input;
  //pressio_data input_global;
  pressio_options analysis_results;

  size_t blocksize = args->block_size;
  size_t blockcount = args->blocks;
  

  for (auto buffer : buffers) {
    
    pressio_data input_pressio = buffer->load();
    void *input_global = NULL;
    
    file_metadata *meta = buffer->metadata();
    
    size_t xLen = floor(meta->dims[0] / blocksize);
    size_t yLen = floor(meta->dims[1] / blocksize);
    size_t zLen = floor(meta->dims[2] / blocksize);
    size_t max_blocks = xLen * yLen * zLen;

    if(blockcount > max_blocks) {
      std::cerr << "ERROR: unable to sample " << blockcount << " blocks. ";
      std::cerr << "Sampling " << max_blocks << " instead.";
      blockcount = max_blocks;
    }

    auto buff_type = input_pressio.dtype();
   
    assert(buff_type == meta->dtype);

    // load global data
    if (buff_type == pressio_float_dtype) { input_global = (float *) input_pressio.data(); } 
    else { input_global = (double *) input_pressio.data(); }

    pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
    pressio_compressor analysis = library.get_compressor("noop");
    pressio_options metrics_options = {
      {"pressio:metric","data_analysis"s},
      {"data_analysis:file_meta",meta}, 
    };
    analysis->set_options(metrics_options);


    //perform analysis
    analysis->compress(&input_pressio, &compressed);
    analysis_results = analysis->get_metrics_results();

    //static const std::array bound_types{"pressio:abs"s, "pressio:rel"s};
    static const std::array bound_types{"pressio:abs"s};
    static const std::vector metrics_composites{"error_stat"s, "size"s, "nanotime"s};

    for (auto const &bound_type : bound_types) {
      for (double bound = error_low; bound <= error_high; bound *= 10) {
        
        pressio_compressor noop = library.get_compressor("noop");
        noop->set_options({
            {"pressio:metric","poulos2024"s},
            {"info:errorbound",bound},
            {"info:boundtype",bound_type},
            {"sample:blocksize",blocksize},
            {"sample:blockcount",blockcount},
            {"sample:samplemode",args->block_method}
            {"info:compressor",args->comp}
        });
        noop->compress(&block_pressio, &compressed);
        pressio_options compress_analysis = noop->get_metrics_results();

        results.copy_from(compress_analysis);
        //results.copy_from(analysis_results);
        //results.copy_from(global_results);
        exportcsv(results, args->output);

      }
    }
    MPI_Barrier(MPI_COMM_WORLD);
  }
  MPI_Barrier(MPI_COMM_WORLD);
  int retcode = MPI_Finalize();
  exit(retcode);
}


/*
          pressio_options global_results;
          pressio_compressor global_compressor = library.get_compressor("pressio");
          pressio_data compressed_global = pressio_data::empty(pressio_byte_dtype, {});
          pressio_data decompressed_global = pressio_data::owning(input_pressio.dtype(), input_pressio.dimensions());
          
          if (!comp.compare("bit_grooming")) {
            unsigned int prec = 1;
            if (bound <= 1e-5) { prec = 3; }
            global_compressor->set_options({
                {"pressio:compressor",args->comp},
                {"bit_grooming:n_sig_digits"s, prec},
                {"bit_grooming:error_control_mode_str"s, "NSD"s},
                {"bit_grooming:mode_str"s, "BITGROOM"s},
                {"pressio:metric","composite"s},
                {"composite:plugins",metrics_composites}
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
*/



