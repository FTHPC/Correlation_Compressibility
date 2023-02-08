#ifndef COMPRESS_H
#define COMPRESS_H

#include <libpressio_ext/cpp/libpressio.h>
#include <libpressio_ext/io/pressio_io.h>
#include <libpressio_ext/io/posix.h>
#include <std_compat/optional.h>
#include <std_compat/memory.h>
#include <libpressio_meta.h>

#include <map>
#include <fstream>
#include <iterator>
#include <iostream>
#include <cstdint>
#include <memory>
#include <algorithm>
#include <numeric>
#include <vector>
#include <array>
#include <tuple>
#include <string>
#include <sstream>
#include <filesystem>
#include <Eigen/Dense>
#include <cmath>

typedef unsigned long int uli;
typedef unsigned short int usi;

extern bool GPU_ACC;

typedef struct cmdline_args{
  std::string           dataset;
  std::string           dtype;
  std::string           directory;
  std::string           filename;
  std::vector<size_t>   dims;
  std::string           output;
  size_t                blocks;
  size_t                block_size;
  usi                   block_method;
  float                 error;
} cmdline_args;


typedef struct file_metadata{
  std::string           filename;
  std::string           directory;
  std::string           filepath; 
  std::string           dataset;
  std::vector<size_t>   dims;
  pressio_dtype         dtype;
  std::string           dataset_name;
  pressio_io            io;              
} file_metadata;


typedef struct block_metadata{
  // provide ptr to for the overall metadata
  struct file_metadata* file;
  // block specific data
  size_t                total_blocks;
  size_t                block_number;
  size_t                block_size; 
  std::vector<size_t>   block_dims; 
  std::vector<size_t>   block_loc;           
  std::string           block_method; 
  std::string           block_filepath;
  pressio_io            block_io; 
} block_metadata;


// from svd.cc
Eigen::MatrixXd svd_sv(void* ptr, usi num_dim, block_metadata* meta);
double find_svd_trunc(std::vector<double> ev0, double threshold);

// from qentropy.cc
double qentropy(void *ptr, double abs, int dtype, size_t num_elements);

// from export.cc
void exportcsv(pressio_options options, std::string output_file);

// from analysis.cc
pressio_options make_config(std::string compressor_id, std::string boundmode, float bound, int dtype);

// from arguments.cc
cmdline_args* parse_args(int argc, char* argv[]);
void printHelp();

#endif


