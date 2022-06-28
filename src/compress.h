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
#include <iostream>
#include <cstdint>
#include <memory>
#include <algorithm>
#include <numeric>
#include <vector>
#include <array>
#include <string>
#include <sstream>
#include <Eigen/Dense>

typedef unsigned long int uli;
typedef unsigned short int usi;

// from svd.cc
Eigen::MatrixXd svd_sv(void* ptr, usi num_dim, std::vector<size_t> dimensions, int dtype, std::string filepath);;
double find_svd_trunc(std::vector<double> ev0, double threshold);

// from qentropy.cc
double qentropy(void *ptr, double abs, int dtype, size_t num_elements);

// from export.cc
void exportcsv(pressio_options options, std::string output_file);
#endif
