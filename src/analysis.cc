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
  libpressio_register_all();
  pressio library;
  pressio_data input;
  pressio_options analysis_results;
  
  auto args = parse_args(argc, argv);
  dataset buffers = std::make_unique<dataset_setup>(args)->set();

  // at this point assuming blocks are used


  samples blocks = std::make_unique<block_sampler>(buffers)->sample(UNIFORM, args->blocks, args->block_size);


  for (auto block : blocks) {
    if (!rank) {
      input = block->load();
      block_metadata *meta = block->block_meta();

      pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
      pressio_compressor analysis = library.get_compressor("noop");
      analysis->set_options({
          {"pressio:metric", "data_analysis"s }, 
          {"data_analysis:meta", meta},     
      });
      analysis->compress(&input, &compressed);

      analysis_results = analysis->get_metrics_results();
      std::cout << analysis_results << std::endl;
    }

    static const std::vector metrics_composites { 
      "error_stat"s, "size"s
    };

    static const std::array bound_types {"pressio:abs"s, "pressio:rel"s };
    using compression_request_t = std::tuple<std::string, std::string, double>;
    using compression_response_t = std::tuple<compression_request_t,pressio_options>;
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
        for (double bound=1e-5; bound<1e-1; bound*=10){
          requests.push_back(std::make_tuple(comp, bound_type, bound));
        }
      }
    }

    distributed::comm::bcast(input, 0, MPI_COMM_WORLD);
    distributed::comm::bcast(analysis_results, 0, MPI_COMM_WORLD);

    distributed::queue::work_queue(
        distributed::queue::work_queue_options<compression_request_t>(),
        requests.begin(),
        requests.end(),
        [&](compression_request_t const& request) {
        auto const& [comp, bound_type, bound] = request;
        pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
        pressio_data decompressed = pressio_data::owning(input.dtype(), input.dimensions());

        pressio_compressor noop = library.get_compressor("noop");
        noop->set_options({
            {"pressio:metric", "compress_analysis"s }, 
            {"info:error_bound", bound},
            {"info:bound_type", bound_type},
            {"info:compressor", comp},
            });
        noop->compress(&input, &compressed);

        pressio_compressor compressor = library.get_compressor("pressio");
        auto options = make_config(comp, bound_type, bound, input.dtype());
        options.set("pressio:compressor", comp);
        options.set("pressio:metric", "composite"s);
        options.set("composite:plugins", metrics_composites);
        compressor->set_options(options);
        compressor->compress(&input, &compressed);
        compressor->decompress(&compressed, &decompressed);


        pressio_options results  = noop->get_metrics_results();
        pressio_options results2 = compressor->get_metrics_results();
        // combine distributed results and data results
        results.copy_from(results2);
        results.copy_from(analysis_results);
        // export to csv
        exportcsv(results, args->output);

        return compression_response_t(request, std::move(results));
        },
        [](compression_response_t const& response) {}
    );
  }
  MPI_Finalize();
}
