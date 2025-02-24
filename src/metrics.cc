/* 
    metrics.cc
    Libpressio metrics plugins that call svd.cc and qentropy.cc to do analysis
    Clemson University and Argonne National Laboratory
*/

#include "compress.h"
#include "data.h"

using namespace std;
using namespace std::string_literals;
using namespace std::chrono;


class data_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      size_t dims_num = input->num_dimensions();
      auto dims = input->dimensions();
      auto dtype = input->dtype();
      dim1 = dims[0]; dim2 = dims[1];
      if (dims_num == 3) dim3 = dims[2];

      if (dims_num != 2 && dims_num != 3) {
        return set_error(1, "Invalid amount of dimensions. Only 2D and 3D supported");
      }

      return 0;
    }

    int set_options(struct pressio_options const& options) override {
      get(options, "data_analysis:meta", &file_meta);
      get(options, "data_analysis:file_meta", &file_meta);
      get(options, "data_analysis:block_meta", &block_meta);
      return 0;
    }

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      file_metadata* meta_cast    = (file_metadata*) file_meta;
      block_metadata* block_cast  = (block_metadata*) block_meta;
      set(opt, "info:filepath",     meta_cast->filepath);
      set(opt, "info:filename",     meta_cast->filename);
      set(opt, "info:dataset",      meta_cast->dataset);
      set(opt, "info:dim1",         meta_cast->dims[0]);
      set(opt, "info:dim2",         meta_cast->dims[1]);
      set(opt, "info:dim3",         meta_cast->dims[2]);
      if (block_cast != NULL){
      set(opt, "block:method",      block_cast->block_method);
      set(opt, "block:total_count", block_cast->total_blocks);
      set(opt, "block:number",      block_cast->block_number);
      set(opt, "block:size",        block_cast->block_size);
      set(opt, "block:dim1",        block_cast->block_dims[0]);
      set(opt, "block:dim2",        block_cast->block_dims[1]);
      set(opt, "block:dim3",        block_cast->block_dims[2]);
      set(opt, "block:loc1",        block_cast->block_loc[0]);
      set(opt, "block:loc2",        block_cast->block_loc[1]);
      set(opt, "block:loc3",        block_cast->block_loc[2]);
      }
      return opt;
    }
    struct pressio_options get_configuration_impl() const override {
      pressio_options opts;
      set(opts, "pressio:stability", "experimental");
      set(opts, "pressio:thread_safe", static_cast<int32_t>(pressio_thread_safety_multiple));
      return opts;
    }
    struct pressio_options get_documentation_impl() const override {
      pressio_options opt;
      set(opt, "pressio:description", "basic statistics of datasets themselves");
      set(opt, "info:filepath",     "full file path to locate dataset");
      set(opt, "info:filename",     "name of the file");
      set(opt, "info:dataset",      "name of the dataset");
      set(opt, "info:dim1",         "first dimension of the inputted data");
      set(opt, "info:dim2",         "second dimension of the inputted data");
      set(opt, "info:dim3",         "third dimension of the inputted data");
      set(opt, "block:method",      "type of block sampling method");
      set(opt, "block:total_count", "total count of the blocks sampled per buffer");
      set(opt, "block:number",      "block iteration/number");
      set(opt, "block:size",        "total size of the block (dim1 * dim2 * dim3)");
      set(opt, "block:dim1",        "first dimension of the block");
      set(opt, "block:dim2",        "second dimension of the block");
      set(opt, "block:dim3",        "third dimension of the block");
      set(opt, "block:loc1",        "first coordinate of the block");
      set(opt, "block:loc2",        "second coordinate of the block");
      set(opt, "block:loc3",        "third coordinate of the block");

      return opt;
    }
    std::unique_ptr<libpressio_metrics_plugin> clone() override {
      return compat::make_unique<data_analysis_metric_plugin>(*this);
    }
    const char* prefix() const override {
      return "data_analysis";
    }
    compat::optional<double> n100, n9999, n999, n99;
    compat::optional<uli> dim1, dim2, dim3;

    private:
    void* file_meta;
    void* block_meta;
};
static pressio_register metrics_data_analysis_plugin(metrics_plugins(), "data_analysis", [](){ return compat::make_unique<data_analysis_metric_plugin>(); });


// dependent on error bound
class compress_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      size_t dims_num = input->num_dimensions();
      // auto dims = input->dimensions();
      auto dtype = input->dtype();
      auto num_elements = input->num_elements();

      //q_entropy = qentropy(input->data(), error_bound, dtype, num_elements);
      q_entropy = 0;
      return 0;
    }

    int set_options(struct pressio_options const& options) override {
      get(options, "info:error_bound", &error_bound);
      get(options, "info:bound_type",  &bound_type);
      get(options, "info:compressor",  &compressor);
      return 0;
    }
  

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      set(opt, "info:error_bound",  error_bound);
      set(opt, "info:bound_type",   bound_type);
      set(opt, "info:compressor",   compressor);
      return opt;
    }
    struct pressio_options get_configuration_impl() const override {
      pressio_options opts;
      set(opts, "pressio:stability", "experimental");
      set(opts, "pressio:thread_safe", static_cast<int32_t>(pressio_thread_safety_multiple));
      return opts;
    }
    struct pressio_options get_documentation_impl() const override {
      pressio_options opt;
      set(opt, "pressio:description", "statistics requiring an error bound");
      set(opt, "info:error_bound",    "error bound used based on the bound_type");
      set(opt, "info:bound_type",     "error bound type (rel or abs)");
      set(opt, "info:compressor",     "compressor used to compress data");

      return opt;
    }
    std::unique_ptr<libpressio_metrics_plugin> clone() override {
      return compat::make_unique<compress_analysis_metric_plugin>(*this);
    }
    const char* prefix() const override {
      return "compress_analysis";
    }

    
    compat::optional<double> q_entropy;

    private:
    double error_bound;
    std::string bound_type;
    std::string compressor;
};
static pressio_register metrics_compress_analysis_plugin(metrics_plugins(), "compress_analysis", [](){ return compat::make_unique<compress_analysis_metric_plugin>(); });

class nanotime_metric_plugin : public libpressio_metrics_plugin {

  typedef std::chrono::nanoseconds ns;
  typedef std::chrono::duration<double, std::nano> duration;

  int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
    start = high_resolution_clock::now();
    return 0;
  }

  int end_compress_impl(const struct pressio_data * input, struct pressio_data const *, int) override {
    end = high_resolution_clock::now();
    return 0;
  }
  pressio_options get_metrics_results(pressio_options const &)  override {
    pressio_options opt;
    duration elapsed = end - start;
    set(opt, "nanotime:compress", elapsed.count());
    return opt;
  } 
  
  struct pressio_options get_documentation_impl() const override {
    pressio_options opt;
    set(opt, "pressio:description", "compression and error statistics timing");
    set(opt, "nanotime:compress",     "timing results");

    return opt;
  }
  std::unique_ptr<libpressio_metrics_plugin> clone() override {
    return compat::make_unique<nanotime_metric_plugin>(*this);
  }

  const char* prefix() const override {
    return "nanotime";
  }

  private:
  high_resolution_clock::time_point start;
  high_resolution_clock::time_point end;
};
static pressio_register metrics_nanotime_plugin(metrics_plugins(), "nanotime", [](){ return compat::make_unique<nanotime_metric_plugin>(); });

