#include "compress.h"

#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

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
    {"verbose",no_argument,0,'v'},
    {"help",no_argument,0,'h'},
    {0,0,0,0}//required all-null entry
  };
  while(true) {
    c = getopt_long(argc, argv, "d:i:f:r:t:o:vh", long_options, &option_index);
    if(c == -1) break; //we are done 
    switch(c) {
      case 'd': args->dims.push_back(std::stoull(optarg)); break;
      case 'i': args->dataset   = optarg; break;
      case 'r': args->directory = optarg; break;
      case 'f': args->filename  = optarg; break;
      case 't': args->dtype     = optarg; break;
      case 'o': args->output    = optarg; break;
      case 'v': args->verbose   = true;   break;
      case 'h': case '?': 
      default:  
        printHelp(); break;
    }
  }
  if ((!args->directory.length()) || (!args->dataset.length()) || (!args->dims.size())) {
    std::cerr << "Invalid arguments exiting" << std::endl;
    printHelp();
  }
  if (!args->output.length()) args->output = "output.csv";

  return args;
}