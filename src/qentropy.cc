#include <cstdint>
#include <random>
#include <functional>
#include "compress.h"


double qentropy(std::vector<float> data, double abs) {
  const auto N = data.size();
  auto [min_it, max_it] = std::minmax_element(data.begin(), data.end());
  double min = *min_it;
  double max = *max_it;
  size_t bins = (max-min)/abs + 1;

  std::vector<uint32_t> bin_counts(bins);
  for (size_t i = 0; i < data.size(); ++i) {
    bin_counts.at(size_t((data[i] - min)/abs))++;
  }

  double sum = 0;
  double prop = 0;
 //#pragma omp parallel for simd reduction(+:sum)
  for (size_t i = 0; i < bins; ++i) {
    if (bin_counts[i]){
      prop = static_cast<double>(bin_counts[i])/N;
      sum += (prop * log2(prop));
    }
  }
  return -sum;
}