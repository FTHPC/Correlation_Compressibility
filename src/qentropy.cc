/* 
    qentropy.cc
    Finds the quantized entropy for a given dataset
    Clemson University and Argonne National Laboratory
*/

#include "compress.h"
#include <cstdint>
#include <random>
#include <functional>

double qentropy(void *ptr, double abs, int dtype, size_t num_elements) {
  if (dtype == pressio_float_dtype) {
    compat::span<float> data(static_cast<float*>(ptr), num_elements);
    const auto N = data.size();
    auto result = std::minmax_element(data.begin(), data.end());
    float min = *result.first;
    float max = *result.second;
    size_t bins = (max-min)/abs + 1;
    std::vector<uint32_t> bin_counts(bins);
    for (size_t i = 0; i < data.size(); ++i) {
      bin_counts.at(size_t((data[i] - min)/abs))++;
    }
    double sum = 0;
    double prop = 0;
  //#pragma omp parallel for simd reduction(+:sum)
    for (size_t bin: bin_counts) {
      if (bin){
        prop = static_cast<double>(bin)/N;
        sum += (prop * log2(prop));
      }
    }
    return -sum;
    
  } else if (dtype == pressio_double_dtype) {
    compat::span<double> data(static_cast<double *>(ptr), num_elements); 
    const auto N = data.size();
    auto result = std::minmax_element(data.begin(), data.end());
    double min = *result.first;
    double max = *result.second;
    size_t bins = (max-min)/abs + 1;
    std::vector<uint32_t> bin_counts(bins);
    for (size_t i = 0; i < data.size(); ++i) {
      bin_counts.at(size_t((data[i] - min)/abs))++;
    }
    double sum = 0;
    double prop = 0;
  //#pragma omp parallel for simd reduction(+:sum)
    for (size_t bin: bin_counts) {
      if (bin){
        prop = static_cast<double>(bin)/N;
        sum += (prop * log2(prop));
      }
    }
    return -sum;

  } else {
    std::cerr << "ERROR: Unknown dtype; Exiting 30" << std::endl;
    exit(30);
  }
}