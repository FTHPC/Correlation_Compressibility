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
#include <mpi.h>

using namespace std::string_literals;

static std::array comps = {
  "sz"s, 
  "zfp"s,
  "mgard"s,
  "tthresh"s,
  "digit_rounding"s,
  "fpzip"s,
  "bit_grooming"s
};


pressio_options make_config(std::string compressor_id, std::string boundmode, float bound, int dtype){
  usi prec = 0;
  if (!compressor_id.compare("sz")      ||
      !compressor_id.compare("zfp")     ||
      !compressor_id.compare("mgard")   ||
      !compressor_id.compare("tthresh") ||
      !compressor_id.compare("linear_quantizer")) {
    return {{boundmode, bound}};
  }
  else if (!compressor_id.compare("bit_grooming")) {
    if (bound == 1E-2)        prec = 1;
    else if (bound == 1E-3)   prec = 1;
    else if (bound == 1E-4)   prec = 1;
    else if (bound == 1E-5)   prec = 3;
    return {{"bit_grooming:n_sig_digits"s, prec}, 
      {"bit_grooming:error_control_mode_str"s, "NSD"s},
      {"bit_grooming:mode_str"s, "BITGROOM"s}};    
  }
  else if (!compressor_id.compare("digit_rounding")) {
    if (bound == 1E-2)        prec = 2;
    else if (bound == 1E-3)   prec = 6;
    else if (bound == 1E-4)   prec = 11;
    else if (bound == 1E-5)   prec = 11;
    return {{"digit_rounding:prec"s, prec}};     
  }
  // fpzip requires even prec values if the data is float64
  // prec of 4 is the minimum for float64
  else if (!compressor_id.compare("fpzip")) {
    if (bound == 1E-2)        prec = (dtype == pressio_float_dtype) ? 2 : 4;
    else if (bound == 1E-3)   prec = 10;
    else if (bound == 1E-4)   prec = (dtype == pressio_float_dtype) ? 13 : 14;
    else if (bound == 1E-5)   prec = (dtype == pressio_float_dtype) ? 15 : 16;
    return {{"fpzip:prec"s, prec}};     
  }
  else{
    std::cerr << "ERROR: Unknown Configuration; Exiting 32" << std::endl;
    exit(32);
  }
}


int main(int argc, char* argv[]) {
  // init stuff
  MPI_Init(&argc, &argv);
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);


  // utilizing pressio library
  libpressio_register_all();
  pressio library;
  pressio_data input;
  pressio_data input_global;
  pressio_options analysis_results;

  float error_high = 1e-2;
  float error_low  = 1e-5;
  
  auto args = parse_args(argc, argv);
  if (args->error != 0) {
    error_high = args->error;
    error_low  = args->error;
  }

  // store large buffers (velocityx.d64, xxx.d64, xxx.d64) in a loader
  
  auto loaders = std::make_unique<dataset_setup>(args);
  dataset buffers = loaders->set();

  // all sampling methods are defined as a short int greater than NONE
  if (args->block_method != NONE){
    // transform the buffers into blocks if a block sampling mode is selected
    samples blocks = std::make_unique<block_sampler>(buffers)->sample(args->block_method, args->blocks, args->block_size);
    // frees the large dataset buffers
    loaders->release();
    buffers = std::move(blocks); // replace buffers w/ blocks to utilize blocks in analysis
  }

  for (auto block : buffers) {
    if (!rank) {
      // rank 0 loads block OR buffer depending on blocking mode
      input = block->load();
      // grab file meta data
      file_metadata *file_meta = block->metadata();
      // will be NULL if no blocking mode wasn't selected
      block_metadata *block_meta = block->block_meta();

      if (block_meta == NULL && args->block_method != NONE) {
        std::cerr << "Block metadata configuration invalid. Exiting 32" << std::endl;
        exit(32);
      }

      // setup metrics for data_analysis and metadata
      // performed on a block OR buffer and is only dependent on statistical properties of the dataset
      // NOT dependent on error bound, error mode, or compressor
      pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
      pressio_compressor analysis = library.get_compressor("noop");
      pressio_options metrics_options = {
          {"pressio:metric", "data_analysis"s }, 
          {"data_analysis:file_meta", file_meta}, 
          {"data_analysis:block_meta", block_meta},  
      };

      analysis->set_options(metrics_options);
      // perform analysis 
      analysis->compress(&input, &compressed);
      analysis_results = analysis->get_metrics_results();
      std::cout << analysis_results << std::endl;
    }

    static const std::vector metrics_composites { 
      "error_stat"s, "size"s
    };
    static const std::array bound_types {"pressio:abs"s, "pressio:rel"s };

    
    using compression_request_t = std::tuple<std::string, std::string, double, pressio_options>;
    using compression_response_t = std::tuple<compression_request_t, pressio_options>;
    std::vector<compression_request_t> requests;

    // loop to go through the different compressors
    for (auto const& comp: comps){
      // loop to go through the different bound types (rel and abs)
      for (auto const& bound_type: bound_types){
        // fpzip, digit_rounding, and bit_grooming have no relative boundmode
        if (!(bound_type.compare("pressio:rel")) && 
            (!comp.compare("fpzip") || !comp.compare("digit_rounding") ||
             !comp.compare("bit_grooming")))
          continue;
        // loop to go through different bounds 1e-5 upto 1e-2
        // reset bound for each bound type and compressor
        for (double bound=error_low; bound<=error_high; bound*=10){
          requests.push_back(std::make_tuple(comp, bound_type, bound, analysis_results));
        }
      }
    }

    distributed::comm::bcast(input, 0, MPI_COMM_WORLD);
    // distributed::comm::bcast(analysis_results, 0, MPI_COMM_WORLD);

    distributed::queue::work_queue(
        distributed::queue::work_queue_options<compression_request_t>(),
        requests.begin(),
        requests.end(),
        [&](compression_request_t const& request) {
        auto const& [comp, bound_type, bound, analysis_results] = request;
        auto options = make_config(comp, bound_type, bound, input.dtype());
        options.set("pressio:compressor", comp);
        options.set("pressio:metric", "composite"s);
        options.set("composite:plugins", metrics_composites);


      
        // GLOBAL METRICS ON ENTIRE DATASET
        pressio_options global_results;
        // perform global analysis if block sampling is used
        // this will load the global buffer from a sampled block
        // velocityx_block1.d64 will load velocityx.d64
        if (args->block_method != NONE){
          input_global = block->load_global();
          pressio_data compressed_global   = pressio_data::empty(pressio_byte_dtype, {});
          pressio_data decompressed_global = pressio_data::owning(input_global.dtype(), input_global.dimensions());
          pressio_compressor global_compressor = library.get_compressor("pressio");
          global_compressor->set_options(options);
          global_compressor->compress(&input_global, &compressed_global);
          global_compressor->decompress(&compressed_global, &decompressed_global);
          pressio_options global_results_unsorted = global_compressor->get_metrics_results();
          global_results = {
            {"global:value_std", global_results_unsorted.get("error_stat:value_std")},
            {"global:compression_ratio", global_results_unsorted.get("size:compression_ratio")},
            {"global:value_range", global_results_unsorted.get("error_stat:value_range")}
          };
        }

 
        // LOCAL METRICS ON INDIVIDUAL LOCAL BUFFER
        pressio_data compressed   = pressio_data::empty(pressio_byte_dtype, {});
        pressio_data decompressed = pressio_data::owning(input.dtype(), input.dimensions());
        pressio_compressor compressor = library.get_compressor("pressio");
        compressor->set_options(options);
        compressor->compress(&input, &compressed);
        compressor->decompress(&compressed, &decompressed);
        pressio_options results = compressor->get_metrics_results();

        pressio_compressor noop = library.get_compressor("noop");
        noop->set_options({
            {"pressio:metric", "compress_analysis"s }, 
            {"info:error_bound", bound},
            {"info:bound_type", bound_type},
            {"info:compressor", comp},
            });
        noop->compress(&input, &compressed);
        pressio_options compress_analysis  = noop->get_metrics_results();

        // combine distributed results and data results
        results.copy_from(compress_analysis);
        results.copy_from(analysis_results);
        if (args->block_method != NONE){
          results.copy_from(global_results);
        }
        // export to csv
        exportcsv(results, args->output);

        return compression_response_t(request, std::move(results));
        },
        [](compression_response_t const& response) {}
    );
    // free resources for this iteration
    block->release();
  }
  MPI_Finalize();
}
