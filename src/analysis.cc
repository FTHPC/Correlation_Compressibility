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
#include <filesystem>
#include <mpi.h>
#include <libdistributed/libdistributed_work_queue.h>
#include <libpressio_ext/cpp/serializable.h>
#include <libpressio_ext/cpp/printers.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

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

typedef struct cmdline_args{
  std::string       dataset;
  std::string       dtype;
  std::string       directory;
  std::string       filename;
  std::vector<uli>  dims;
  std::string       output;
  bool              verbose;
} cmdline_args;

void printHelp()
{
    std::cout <<
            "--dtype      -t: The data type of the files contained within the dataset folder\n"
            "--dataset    -i: Folder containing either hdf5 files or binary files\n"
            "--directory  -r: Full path for the parent dataset directory. ex: '$COMPRESS_HOME/datasets'\n"
            "--filename   -f: Specific file within a dataset directory to be run\n"
            "--dims       -d: Dimensions\n"
            "--output     -o: Ouput csv to store results in\n"
            "--verbose    -v: Verbose mode\n"
            "--help       -h: Show help\n"  
            ;
    exit(1);
}

cmdline_args parse_args(int argc, char* argv[]) {
  int c;
  int option_index = 0;
  cmdline_args args;
  static struct option long_options[] = {
    {"dims",required_argument,0,'d'},
    {"filename",required_argument,0,'f'},
    {"dataset",required_argument,0,'i'},
    {"directory",required_argument,0,'r'},
    {"dtype",required_argument,0,'t'},
    {"output",required_argument,0,'o'},
    {"verbose",no_argument,0,'v'},
    {"help",no_argument,0,'h'},
    {0,0,0,0}//required all-null entry
  };
  while(true) {
    c = getopt_long(argc, argv, "d:i:f:r:t:o:vh", long_options, &option_index);
    if(c == -1) break; //we are done 
    switch(c) {
      case 'd':
        args.dims.push_back(std::stoull(optarg));
        break;
      case 'i':
        args.dataset    = optarg;
        break;
      case 'r':
        args.directory  = optarg;
        break;
      case 'f':
        args.filename   = optarg;
        break;
      case 't':
        args.dtype      = optarg;
        break;
        case 'o':
        args.output     = optarg;
        break;
      case 'v':
        args.verbose    = true;
        break;
      case 'h':
      case '?':
      default:
        printHelp();
        break;
    }
  }
  return args;
}

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
  auto args = parse_args(argc, argv);

  pressio library;
  if ((!args.directory.length()) || (!args.dataset.length()) || (!args.dims.size())) {
    std::cerr << "Invalid arguments exiting" << std::endl;
    printHelp();
  }

  std::string output;
  if (!args.output.length()) output = "output.csv";
  else output = args.output;

  pressio_dtype dtype;
  if (!args.dtype.compare("float64"))
    dtype = pressio_double_dtype;
  else if (!args.dtype.compare("float32"))
    dtype = pressio_float_dtype;
  else { 
    std::cerr << "Invalid dtype exiting" << std::endl;
    printHelp();
  }
  
  bool stop = false;
  for (const auto & entry : std::filesystem::directory_iterator(args.directory+'/'+args.dataset)) {
    pressio_data input;
    std::string filename;
    pressio_options analysis_results;
    if (stop) break;
    if(!rank) {
      if (args.filename.length()) {
        filename = args.filename; 
        stop = true;
      } else filename = entry.path().filename().string();
      std::cout << "filename " << filename << std::endl;
      
      size_t lastindex = filename.find_last_of('.'); 
      std::string full_filepath = args.directory+'/'+args.dataset+'/'+filename;

      std::string dataset_name;
      pressio_io io;
      if (!filename.substr(lastindex, lastindex + 3).compare(".h5")){
        // if hdf5 file
        if (!filename.substr(lastindex - 4, lastindex + 3).compare(".dat.h5"))
          // .dat.h5 follows our naming scheme for dataset names of hdf5 files
          // ex: velocityx.d64.dat.h5 will have a dataset name of velocityx.d64.dat
          dataset_name = filename.substr(0, lastindex); 
        else dataset_name = 'Z'; // 'Z' is used for our generated Gaussian samples

        io = library.get_io("hdf5");
        io->set_options({
            {"io:path", full_filepath},
            {"hdf5:dataset", dataset_name}
            });
      } else {
        // if posix binary file
        io = library.get_io("posix");
        io->set_options({
            {"io:path", full_filepath}
            });
      }


      std::cout << full_filepath << std::endl;


      pressio_data metadata = pressio_data::owning(dtype, args.dims);  
      auto input_ptr = io->read(&metadata);
      if (!input_ptr) {
        std::cerr << io->error_msg() << std::endl;
        break;
      } else {
        input = std::move(*input_ptr);
      }
      pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
      pressio_compressor analysis = library.get_compressor("noop");
      analysis->set_options({{"pressio:metric", "data_analysis"s }, 
                            {"info:filepath", args.directory},
                            {"info:filename", filename},
                            {"info:dataset",  args.dataset}});
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
          exportcsv(results, output);

          return compression_response_t(request, std::move(results));
        },
        [](compression_response_t const& response) {}
    );
  }
  MPI_Finalize();
}
