#include "compress.h"
#include "data.h"

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

bool GPU_ACC = 0;

void printHelp()
{
  std::cout <<
    "--dtype      -t: The data type of the files contained within the dataset folder\n"
    "--dataset    -i: Folder containing either hdf5 files or binary files\n"
    "--directory  -r: Full path for the parent dataset directory. ex: '$COMPRESS_HOME/datasets'\n"
    "--filename   -f: Specific file within a dataset directory to be run\n"
    "--dims       -d: Dimensions\n"
    "--output     -o: Ouput csv to store results in\n"
    "--gpu        -g: GPU accelerated mode. Must have an Nvidia GPU with CUDA\n" 
    "--help       -h: Show help\n"  
    ;
  exit(1);
}

cmdline_args* parse_args(int argc, char* argv[]) {
  int c;
  int option_index = 0;
  cmdline_args* args = (cmdline_args*) calloc(1, sizeof(cmdline_args));
  static struct option long_options[] = {
    {"dims",required_argument,0,'d'},
    {"filename",required_argument,0,'f'},
    {"dataset",required_argument,0,'i'},
    {"directory",required_argument,0,'r'},
    {"dtype",required_argument,0,'t'},
    {"output",required_argument,0,'o'},
    {"blocks",required_argument,0,'b'},
    {"block_size",required_argument,0,'s'},
    {"method", required_argument,0,'m'},
    {"gpu",no_argument,0,'g'},
    {"bound", no_argument,0,'e'},
    {"compressor", required_argument,0,'c'},
    {"help",no_argument,0,'h'},
    {0,0,0,0}//required all-null entry
  };
  std::string method;
  while(true) {
    c = getopt_long(argc, argv, "d:i:f:r:t:o:b:s:m:e:ghc:", long_options, &option_index);
    if(c == -1) break; //we are done 
    switch(c) {
      case 'd': args->dims.push_back(std::stoull(optarg)); break;
      case 'i': args->dataset    = optarg; break;
      case 'r': args->directory  = optarg; break;
      case 'f': args->filename   = optarg; break;
      case 't': args->dtype      = optarg; break;
      case 'o': args->output     = optarg; break;
      case 'b': args->blocks     = std::stoull(optarg); break;
      case 's': args->block_size = std::stoull(optarg); break;
      case 'm': method           = optarg; break;
      case 'e': args->error      = atof(optarg); break;
      case 'g': GPU_ACC          = 1; break;
      case 'c': args->comp       = optarg; break;
      case 'h': case '?': 
      default:  
        printHelp(); break;
    }
  }
  if ((!args->directory.length()) || (!args->dataset.length()) || (!args->dims.size())) {
    std::cerr << "Invalid arguments exiting" << std::endl;
    printHelp();
  }
  if (args->blocks && !args->block_size) {
    std::cerr << "No block size inputted. Blocks were set" << std::endl;
    printHelp();
  }
  if (args->block_size && !args->blocks) {
    std::cerr << "No amount of blocks inputted. Block size was set" << std::endl;
    printHelp();
  }

  if (method.empty()) std::cerr << "No sampling method provided. No sampling is being used." << std::endl;
  if      (!method.compare("UNIFORM"))     args->block_method = UNIFORM;
  else if (!method.compare("RANDOM"))      args->block_method = RANDOM;
  else if (!method.compare("MULTIGRID"))   args->block_method = MULTIGRID;
  else                                     args->block_method = NONE;


  return args;
}
