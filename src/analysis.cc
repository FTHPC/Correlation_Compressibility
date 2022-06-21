/* 
    analysis.cpp
    Performs compression of 2D and 3D datasets using Libpressio
    Computes estimation statistics
    Clemson University and Argonne National Laboratory

    Libpressio https://robertu94.github.io/libpressio
*/

#include "compress.h"
#include <initializer_list>

using namespace std::string_literals;

static std::vector<std::string> comps = {
  "sz", 
  "zfp",
  "mgard",
  "tthresh",
  "digit_rounding",
  "fpzip",
  "bit_grooming"
};


std::initializer_list<std::vector<std::string>> make_config(std::string compressor_id, float bound, std::string boundmode, int dtype){
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
    //fpzip requires even prec values if the data is float64
    //prec of 4 is the minimum for float64
    else if (!compressor_id.compare("fpzip")) {
      if (bound == 1E-2)        prec = (dtype == pressio_float_dtype) ? 2 : 4;
      else if (bound == 1E-3)   prec = 10;
      else if (bound == 1E-4)   prec = (dtype == pressio_float_dtype) ? 13 : 14;
      else if (bound == 1E-5)   prec = (dtype == pressio_float_dtype) ? 15 : 16;
      return {{"fpzip:prec"s, prec}};     
    }
    else{
      fprintf(stderr, "ERROR: Unknown Configuration; Exiting 32");
      exit(32);
    }
}





int main() {
  pressio library;
  auto dtype = pressio_float_dtype;

  pressio_data metadata = pressio_data::owning(dtype, {500,500,100});  
  pressio_io io = library.get_io("posix");
  io->set_options({
      {"io:path", "/home/dkrasow/compression/datasets/SDRBENCH-Hurricane-ISABEL-100x500x500/CLOUDf48.bin.f32"}
    });
  pressio_data input = std::move(*io->read(&metadata));
  pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});

  pressio_compressor analysis = library.get_compressor("pressio");
  analysis->set_options({
      { "pressio:metric", "data_analysis"s },
    });


  analysis->compress(&input, &compressed);
  

  auto analysis_results = analysis->get_metrics_results();
  std::cout << analysis_results << std::endl;





  /* run different compressors on different bounds */
  pressio_compressor compressor = library.get_compressor("pressio");
  compressed = pressio_data::empty(pressio_byte_dtype, {});
  pressio_data decompressed = pressio_data::owning(input.dtype(), input.dimensions());

  float bound;

  static std::vector<std::string> metrics_composites = {
    "error_stat"s, "size"s, "compress_analysis"s,
  };

  static std::vector<std::string> bound_type = {
    "pressio:abs", "pressio:rel"
  };

  // loop to go through the different compressors
  for (usi i=0; i<comps.size(); i++){
    // loop to go through the different bound types (rel and abs)
    for (usi j=0; j<bound_type.size(); j++){
      // fpzip, digit_rounding, and bit_grooming have no relative boundmode
      if (!(bound_type[j].compare("pressio:rel")) && 
         (!comps[i].compare("fpzip") || !comps[i].compare("digit_rounding") 
                                     || !comps[i].compare("bit_grooming")))
        continue;
      // loop to go through different bounds 1e-5 upto 1e-2
      // reset bound for each bound type and compressor
      bound = 1e-5;
      for (usi k=1; k<5; k++){
      
        compressor->set_options({
            { "compressor_config", make_config(comps[i], bound_type[j], bound, input.dtype()) },
            { "pressio:compressor", comps[i] },
            { "pressio:metric", "composite"s },
            { "composite:plugins", metrics_composites }
          });


        compressor->compress(&input, &compressed);
        compressor->decompress(&compressed, &decompressed);

        auto compress_results = compressor->get_metrics_results();
        std::cout << "bound: " << bound << std::endl;
        std::cout << "compr: " << comps[i] << std::endl;
        std::cout << compress_results << std::endl;
        
        bound *= 10;
      }
    }
  }
}
