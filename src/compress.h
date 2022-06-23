#ifndef COMPRESS_H
#define COMPRESS_H

#include <libpressio_ext/cpp/libpressio.h>
#include <libpressio_ext/io/pressio_io.h>
#include <libpressio_ext/io/posix.h>
#include <std_compat/optional.h>
#include <std_compat/memory.h>
#include <libpressio_meta.h>

#include <map>
#include <iostream>
#include <cstdint>
#include <memory>
#include <algorithm>
#include <numeric>
#include <vector>
#include <array>
#include <string>
#include <Eigen/Dense>


typedef unsigned long int uli;
typedef unsigned short int usi;

// from svd.cc
Eigen::MatrixXd svd_sv(void* ptr, usi num_dim, std::vector<size_t> dimensions, int dtype);
double find_svd_trunc(std::vector<double> ev0, double threshold);

// from qentropy.cc
double qentropy(std::vector<float> data, double abs);

#endif
