#include "pressio_data.h"
#include "pressio_compressor.h"
#include "pressio_options.h"
#include "libpressio_ext/cpp/compressor.h"
#include "libpressio_ext/cpp/metrics.h"
#include "libpressio_ext/cpp/pressio.h"
#include "libpressio_ext/cpp/options.h"
#include "std_compat/memory.h"
#include <cmath>
#include <chrono>
#include <random>
#include <boost/random/sobol.hpp>
#include <unordered_set>

namespace libpressio { namespace poulos2024_metrics_ns {

class poulos2024_plugin : public libpressio_metrics_plugin {
  using location = std::vector<size_t>;
  struct result {
      double b,c,d;
  };
  std::vector<std::pair<pressio_data, location>> collect_samples(pressio_data const& input) const;
  //double locality(std::vector<location> const& locs) const;

  typedef std::chrono::nanoseconds ns;
  typedef std::chrono::duration<double, std::nano> duration;
  public:
    int begin_compress_impl(struct pressio_data const* input, pressio_data const*) override {
      start = std::chrono::high_resolution_clock::now();

      auto samples = collect_samples(*input);
      size_t N = 0;
      std::vector<double> stddevs, crs, loc;
      std::vector<location> locs;
      impl->set_metrics(make_m_composite({
                  metrics_plugins().build("error_stat"),
                  metrics_plugins().build("size"),
                  })); 
      for (auto const& sample : samples) {
          pressio_data tmp;
          impl->compress(&sample.first, &tmp);
          auto m = impl->get_metrics_results();
          double cr, stddev;
          m.get("size:compression_ratio", &cr);
          m.get("error_stat:value_std", &stddev);
          
          if(std::isnan(stddev)) { continue; }
          
          crs.emplace_back(std::log(cr));
          stddevs.emplace_back(stddev);
          locs.emplace_back(sample.second);
          N++;
      }
      auto mm = std::minmax(stddevs.begin(), stddevs.end());
      const double range = *mm.second - *mm.first;
      
      size_t size = stddevs.size();
      double b,c,d;
      b = c = d = 0.0;
      for (int i=0; i<size; i++) {
       
        double loc, num, denom;
        loc = num = denom = 0.0;
        for (int j=0; j<size; j++) {
          if(j == i) { continue; }
          num += (abs((int)locs[i][0]-(int)locs[j][0]) + abs((int)locs[i][1]-(int)locs[j][1]) + abs((int)locs[i][2]-(int)locs[j][2])) /
            (sqrt(pow((int)locs[i][0]-(int)locs[j][0],2) + pow((int)locs[i][1]-(int)locs[j][1],2) + pow((int)locs[i][2]-(int)locs[j][2],2)));
          denom += abs((int)locs[i][0]-(int)locs[j][0]) + abs((int)locs[i][1]-(int)locs[j][1]) + abs((int)locs[i][2]-(int)locs[j][2]);
        }
        loc = num / denom;
        
        stddevs[i] = (stddevs[i]-*mm.first)/range;

        b += loc * crs[i];
        c += stddevs[i] * crs[i];
        d += loc * stddevs[i] * crs[i];
      }
      results = result {b, c, d};

      end = std::chrono::high_resolution_clock::now();

      return 0;
    }

    int end_compress_impl(const struct pressio_data * input, struct pressio_data const *, int) override {
      end = std::chrono::high_resolution_clock::now();
      return 0;
    }

    int set_options(struct pressio_options const &options) override {
      get(options, "info:errorbound", &errorbound);
      get(options, "info:boundtype", &boundtype);
      get(options, "info:compressor", &compressor);
      get(options, "sample:blocksize", &blocksize);
      get(options, "sample:blockcount", &blockcount);
      get(options, "sample:samplemode", &samplemode);
      return 0;
    }

    pressio_options get_options() const override {
      pressio_options options;
      set(options, "info:errorbound", errorbound);
      set(options, "info:boundtype", boundtype);
      set(options, "info:compressor", compressor);
      set(options, "sample:blocksize", blocksize);
      set(options, "sample:blockcount", blockcount);
      set(options, "sample:samplemode", samplemode);
      return options;
    }

  
  struct pressio_options get_configuration_impl() const override {
    pressio_options opts;
    set(opts, "pressio:thread_safe", pressio_thread_safety_multiple);
    return opts;
  }

  struct pressio_options get_documentation_impl() const override {
    pressio_options opt;
    set(opt, "pressio:description", "");
    return opt;
  }

  pressio_options get_metrics_results(pressio_options const &) override {
    pressio_options opt;
    duration elapsed = end - start;
    if(results) {
        set(opt, "poulos2024:b", results->b);
        set(opt, "poulos2024:c", results->c);
        set(opt, "poulos2024:d", results->d);
        set(opt, "poulos2024:nanotime", elapsed.count());
    } else {
        set_type(opt, "poulos2024:b", pressio_option_double_type);
        set_type(opt, "poulos2024:c", pressio_option_double_type);
        set_type(opt, "poulos2024:d", pressio_option_double_type);
        set_type(opt, "poulos2024:nanotime", pressio_option_uint64_type);
    }
    return opt;
  }

  std::unique_ptr<libpressio_metrics_plugin> clone() override {
    return compat::make_unique<poulos2024_plugin>(*this);
  }
  const char* prefix() const override {
    return "poulos2024";
  }

  private:
  std::string impl_id = "noop";
  pressio_compressor impl = compressor_plugins().build(impl_id);

  double errorbound;
  std::string boundtype;
  std::string compressor;
  size_t blockcount;
  size_t blocksize;
  std::string samplemode;
  std::optional<result> results;

  std::chrono::high_resolution_clock::time_point start;
  std::chrono::high_resolution_clock::time_point end;
  
  std::vector<std::pair<pressio_data, location>> collect_samples_uniform(pressio_data const& input) const;
  std::vector<std::pair<pressio_data, location>> collect_samples_random(pressio_data const& input) const;
  std::vector<std::pair<pressio_data, location>> collect_samples_sobol(pressio_data const& input) const;

};

static pressio_register metrics_poulos2024_plugin(metrics_plugins(), "poulos2024", [](){ return compat::make_unique<poulos2024_plugin>(); });
}}


std::vector<std::pair<pressio_data, std::vector<size_t>>>
libpressio::poulos2024_metrics_ns::poulos2024_plugin::collect_samples_uniform(pressio_data const &input) const {
 
  auto dims = input.dimensions();
  auto dtype = input.dtype();

  size_t xLen = floor(dims[0] / blocksize);
  size_t yLen = floor(dims[1] / blocksize);
  size_t zLen = floor(dims[2] / blocksize);
  size_t max_blocks = xLen * yLen * zLen;

  //uniformly partition the space
  size_t stride = floor(max_blocks / blockcount);

  void *data = NULL;
  if(dtype == pressio_float_dtype) {
    data = (float *) input.data();
  } else {
    data = (double *) input.data();
  }

  uint32_t sq_bs = (uint32_t)std::pow(blocksize, 2);
  uint32_t cb_bs = (uint32_t)std::pow(blocksize, 3);
  uint32_t d1d2 = dims[1] * dims[2];
  uint32_t total_size = dims[0] * dims[1] * dims[2];

  std::vector<std::pair<pressio_data, std::vector<size_t>>> samples;

  size_t block_num = 1;
  size_t count = 0;
  void *block = NULL;
  while(count < blockcount) {
    if (dtype == pressio_float_dtype) { block = malloc(sizeof(float)*cb_bs); } 
    else { block = malloc(sizeof(double)*cb_bs); }
    
    size_t i = ((size_t)(floor((block_num-1) / (xLen * yLen))) % zLen) * blocksize;
    size_t j = ((size_t)floor((block_num-1) / xLen) % yLen) * blocksize;
    size_t k = (size_t)(((block_num-1) % xLen) * blocksize);

    std::vector<size_t> loc = {i,j,k};

    for(size_t block_i=0; block_i < blocksize; block_i++) {
      for(size_t block_j=0; block_j < blocksize; block_j++) {
        for(size_t block_k=0; block_k < blocksize; block_k++) {
          
          uint32_t block_idx = block_i*sq_bs + block_j*blocksize + block_k;
          assert(block_idx < cb_bs);
          
          uint32_t input_idx = (i+block_i)*d1d2 + (j+block_j)*dims[2] + (k + block_k);
          assert(input_idx < total_size);

          if (dtype == pressio_float_dtype) {
            ((float*)block)[block_idx] = ((float*)data)[input_idx]; 
          } else {
            ((double*)block)[block_idx] = ((double*)data)[input_idx];
          }

        }
      }
    }
    pressio_data block_pressio = pressio_data::move(dtype, block, {blocksize,blocksize,blocksize}, pressio_data_libc_free_fn, nullptr);
    samples.emplace_back(std::make_pair(block_pressio,loc));
    block_num += stride;
    count++;
  }
  return samples;
}

std::vector<std::pair<pressio_data, std::vector<size_t>>>
libpressio::poulos2024_metrics_ns::poulos2024_plugin::collect_samples_random(pressio_data const &input) const {

  auto dims = input.dimensions();
  auto dtype = input.dtype();

  size_t xLen = floor(dims[0] / blocksize);
  size_t yLen = floor(dims[1] / blocksize);
  size_t zLen = floor(dims[2] / blocksize);
  size_t max_blocks = xLen * yLen * zLen;

  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<size_t> dist(1, max_blocks);

  void *data = NULL;
  if(dtype == pressio_float_dtype) {
    data = (float *) input.data();
  } else {
    data = (double *) input.data();
  }

  uint32_t sq_bs = (uint32_t)std::pow(blocksize, 2);
  uint32_t cb_bs = (uint32_t)std::pow(blocksize, 3);
  uint32_t d1d2 = dims[1] * dims[2];
  uint32_t total_size = dims[0] * dims[1] * dims[2];

  std::vector<std::pair<pressio_data, std::vector<size_t>>> samples;

  void *block = NULL;
  
  std::unordered_set<size_t> block_indices;
  while(block_indices.size() < blockcount) {
    size_t block_num = dist(gen);
    
    if (block_indices.insert(block_num).second) {
      if (dtype == pressio_float_dtype) { block = malloc(sizeof(float)*cb_bs); } 
      else { block = malloc(sizeof(double)*cb_bs); }
      
      size_t i = ((size_t)(floor((block_num-1) / (xLen * yLen))) % zLen) * blocksize;
      size_t j = ((size_t)floor((block_num-1) / xLen) % yLen) * blocksize;
      size_t k = (size_t)(((block_num-1) % xLen) * blocksize);

      std::vector<size_t> loc = {i,j,k};

      for(size_t block_i=0; block_i < blocksize; block_i++) {
        for(size_t block_j=0; block_j < blocksize; block_j++) {
          for(size_t block_k=0; block_k < blocksize; block_k++) {
            
            uint32_t block_idx = block_i*sq_bs + block_j*blocksize + block_k;
            assert(block_idx < cb_bs);
            
            uint32_t input_idx = (i+block_i)*d1d2 + (j+block_j)*dims[2] + (k + block_k);
            assert(input_idx < total_size);

            if (dtype == pressio_float_dtype) {
              ((float*)block)[block_idx] = ((float*)data)[input_idx]; 
            } else {
              ((double*)block)[block_idx] = ((double*)data)[input_idx];
            }
          }
        }
      }
      pressio_data block_pressio = pressio_data::move(dtype, block, {blocksize,blocksize,blocksize}, pressio_data_libc_free_fn, nullptr);
      samples.emplace_back(std::make_pair(block_pressio,loc));
    }
  }
  return samples;
}


std::vector<std::pair<pressio_data, std::vector<size_t>>>
libpressio::poulos2024_metrics_ns::poulos2024_plugin::collect_samples_sobol(pressio_data const &input) const {

  auto dims = input.dimensions();
  auto dtype = input.dtype();

  size_t xLen = floor(dims[0] / blocksize);
  size_t yLen = floor(dims[1] / blocksize);
  size_t zLen = floor(dims[2] / blocksize);
  size_t max_blocks = xLen * yLen * zLen;

  boost::random::sobol eng(1);
  std::uniform_int_distribution<uint32_t> dist(1, max_blocks);
  auto s = [&]() -> size_t { return static_cast<size_t>(dist(eng)); };
    
  void *data = NULL;
  if(dtype == pressio_float_dtype) {
    data = (float *) input.data();
  } else {
    data = (double *) input.data();
  }

  uint32_t sq_bs = (uint32_t)std::pow(blocksize, 2);
  uint32_t cb_bs = (uint32_t)std::pow(blocksize, 3);
  uint32_t d1d2 = dims[1] * dims[2];
  uint32_t total_size = dims[0] * dims[1] * dims[2];

  std::vector<std::pair<pressio_data, std::vector<size_t>>> samples;

  void *block = NULL;
  
  std::unordered_set<size_t> block_indices;

  while(block_indices.size() < blockcount) {
    size_t block_num = s();
    
    if (block_indices.insert(block_num).second) {
      if (dtype == pressio_float_dtype) { block = malloc(sizeof(float)*cb_bs); } 
      else { block = malloc(sizeof(double)*cb_bs); }
      
      size_t i = ((size_t)(floor((block_num-1) / (xLen * yLen))) % zLen) * blocksize;
      size_t j = ((size_t)floor((block_num-1) / xLen) % yLen) * blocksize;
      size_t k = (size_t)(((block_num-1) % xLen) * blocksize);

      std::vector<size_t> loc = {i,j,k};

      for(size_t block_i=0; block_i < blocksize; block_i++) {
        for(size_t block_j=0; block_j < blocksize; block_j++) {
          for(size_t block_k=0; block_k < blocksize; block_k++) {
            
            uint32_t block_idx = block_i*sq_bs + block_j*blocksize + block_k;
            assert(block_idx < cb_bs);
            
            uint32_t input_idx = (i+block_i)*d1d2 + (j+block_j)*dims[2] + (k + block_k);
            assert(input_idx < total_size);

            if (dtype == pressio_float_dtype) {
              ((float*)block)[block_idx] = ((float*)data)[input_idx]; 
            } else {
              ((double*)block)[block_idx] = ((double*)data)[input_idx];
            }
          }
        }
      }
      pressio_data block_pressio = pressio_data::move(dtype, block, {blocksize,blocksize,blocksize}, pressio_data_libc_free_fn, nullptr);
      samples.emplace_back(std::make_pair(block_pressio,loc));
    }
  }
  return samples;
}

std::vector<std::pair<pressio_data, std::vector<size_t>>>
libpressio::poulos2024_metrics_ns::poulos2024_plugin::collect_samples(pressio_data const &input) const {
  if (samplemode == "uniform") { return collect_samples_uniform(input); }
  if (samplemode == "random") { return collect_samples_random(input); }
  if (samplemode == "sobol") { return collect_samples_sobol(input); }

  exit(1);
}

