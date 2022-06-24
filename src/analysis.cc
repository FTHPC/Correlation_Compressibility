/* 
   analysis.cpp
   Performs compression of 2D and 3D datasets using Libpressio
   Computes estimation statistics
   Clemson University and Argonne National Laboratory

   Libpressio https://robertu94.github.io/libpressio
   */

#include "compress.h"
#include <array>
#include <tuple>
#include <mpi.h>
#include <libdistributed/libdistributed_work_queue.h>
#include <libpressio_ext/cpp/serializable.h>
#include <libpressio_ext/cpp/printers.h>

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
  MPI_Init(&argc, &argv);
  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  libpressio_register_all();
  pressio library;
  
  // auto dtype = pressio_float_dtype;
  // std::vector<size_t> dims {500,500,100};
  // pressio_io io = library.get_io("posix");
  // io->set_options({
  //     {"io:path", "/home/dkrasow/compression/datasets/SDRBENCH-Hurricane-ISABEL-100x500x500/CLOUDf48.bin.f32"}
  //     });

  auto dtype = pressio_double_dtype;
  std::vector<size_t> dims {1028, 1028};
  pressio_io io = library.get_io("hdf5");
  io->set_options({
      {"io:path", "/home/dkrasow/compression/datasets/spatialweight_fixed_sum/sample_gp_K1028_sum3ranges_Sample3.h5"},
      {"hdf5:dataset", "Z"}
      });


  pressio_data input;
  if(!rank) {
    pressio_data metadata = pressio_data::owning(dtype, dims);  
    input = std::move(*io->read(&metadata));
    pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});

    pressio_compressor analysis = library.get_compressor("noop");
    analysis->set_options({{ "pressio:metric", "data_analysis"s }});
    analysis->compress(&input, &compressed);

    auto analysis_results = analysis->get_metrics_results();
    std::cout << analysis_results << std::endl;
  }

  static const std::vector metrics_composites { 
    "error_stat"s, "size"s, "compress_analysis"s,
  };

  static const std::array bound_types { "pressio:abs"s, "pressio:rel"s };
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

  distributed::queue::work_queue(
      distributed::queue::work_queue_options<compression_request_t>(),
      requests.begin(),
      requests.end(),
      [&](compression_request_t const& request) {
        auto const& [comp, bound_type, bound] = request;
        pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
        pressio_data decompressed = pressio_data::owning(input.dtype(), input.dimensions());

        auto options = make_config(comp, bound_type, bound, input.dtype());
        pressio_compressor compressor = library.get_compressor("pressio");
        options.set("pressio:compressor", comp);
        options.set("pressio:metric", "composite"s);
        options.set("composite:plugins", metrics_composites);
        compressor->set_options(options);

        compressor->compress(&input, &compressed);
        compressor->decompress(&compressed, &decompressed);

        auto compress_results = compressor->get_metrics_results();
        std::cout << compress_results << std::endl;
        return compression_response_t(request, std::move(compress_results));
      },
      [](compression_response_t const& response) {}
  );

  MPI_Finalize();
}
