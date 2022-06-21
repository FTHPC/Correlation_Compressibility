#ifndef COMPRESS_H
#define COMPRESS_H

#include <libpressio_ext/cpp/libpressio.h>
#include <libpressio_ext/io/pressio_io.h>
#include <libpressio_ext/io/posix.h>
#include <std_compat/optional.h>
#include <std_compat/memory.h>

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
void SVD_2D_Jacobi(const float* ptr, compat::optional<float*> m);
void SVD_2D_DC(const float* ptr, compat::optional<float*> m);
void SVD_3D_Tucker(const float* ptr, compat::optional<float*> m);
double find_svd_trunc(compat::optional<float*> m, float threshold);

// from qentropy.cc
double qentropy(std::vector<float> const& copy, double abs);

#endif
