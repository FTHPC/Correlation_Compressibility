#include <array>
#include <map>
#include <vector>
#include <cstdint>
#include <random>
#include <random>
#include <ranges>
#include <numeric>
#include <functional>
#include <algorithm>
#include <execution>
#include <chrono>
#include <iostream>
#include <memory_resource>


double qentropy(std::vector<float> const& copy, double abs, std::pmr::memory_resource& pool) {
  const auto N = copy.size();
  auto [min_it, max_it] = std::minmax_element(copy.begin(), copy.end());
  double min = *min_it;
  double max = *max_it;
  size_t bins = (max-min)/abs + 1;
  std::cout << bins << std::endl;
  std::pmr::vector<uint32_t> bin_counts(bins, &pool);
  for (size_t i = 0; i < copy.size(); ++i) {
    bin_counts.at(size_t((copy[i] - min)/abs))++;
  }
  std::cout << "prob" << std::endl;

  double sum = 0;
//#pragma omp parallel for simd reduction(+:sum)
  for (size_t i = 0; i < bins; ++i) {
    double prop = static_cast<double>(bin_counts[i])/N;
    sum += (prop * log2(prop));
  }
  std::cout << "sum" << std::endl;

  return -sum;
}

int main() {
  std::array<std::size_t,2> dims{512,512};
  const size_t N = std::reduce(dims.begin(), dims.end(),size_t{1}, std::multiplies{});
  std::vector<float> v(N,0);
  std::seed_seq seed;
  std::mt19937_64 gen {seed};
  std::normal_distribution<float> dist;
  auto rand = [&]{ return dist(gen);};
#pragma omp parallel for
  for (size_t i = 0; i < N; ++i) {
    v[i] = rand();
  }

  std::cout << "setup" << std::endl;

  for (int i = 0; i < 10; ++i) {
    std::vector<float> copy(v);
    std::pmr::monotonic_buffer_resource pool(sizeof(uint32_t) * 108117* 2);
    auto start = std::chrono::steady_clock::now();
    auto q = qentropy(copy, 1e-4, pool);
    auto stop = std::chrono::steady_clock::now();
    using ms_dbl = std::chrono::duration<double, std::milli>;
    std::cout << q << " " << std::chrono::duration_cast<ms_dbl>(stop-start).count() << std::endl;
  }

}
