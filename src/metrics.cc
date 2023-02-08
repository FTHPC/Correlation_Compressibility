/* 
    metrics.cc
    Libpressio metrics plugins that call svd.cc and qentropy.cc to do analysis
    Clemson University and Argonne National Laboratory
*/

#include "compress.h"
#include "data.h"

using namespace std;
using namespace std::string_literals;

class data_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      size_t dims_num = input->num_dimensions();
      auto dims = input->dimensions();
      auto dtype = input->dtype();
      dim1 = dims[0];
      dim2 = dims[1];
      if (dims_num == 3) dim3 = dims[2];

      if (dims_num != 2 && dims_num != 3) {
        return set_error(1, "Invalid amount of dimensions. Only 2D and 3D supported");
      }

      // std::reverse(dims.begin(), dims.end()); //put in row major order

      // compute singular values and store values in ascending order
      block_metadata* meta_cast = (block_metadata*) meta;

      cout << meta_cast->block_filepath << endl;

      Eigen::MatrixXd svd0_s = svd_sv(input->data(), dims_num, meta_cast);
      
      // stores the squared singular value matrix 
      Eigen::MatrixXd svd0_s_squared = svd0_s.array().square();
   
   // debug print out svd singular value array
    #ifdef DEBUG
      for(size_t i=0; i<svd0_s.size(); ++i)
        cout << svd0_s(i) << ' ';
      cout << endl;
    #endif

      // determines cumulative sum and sum of singular values
      double sum = 0;
      vector<double> cumsum_svd0;
      for(size_t i=0; i<svd0_s_squared.size(); ++i){
        sum += svd0_s_squared(i);
        cumsum_svd0.push_back(sum);
      } 

    // debug print of cumsum of the squared svd values
    #ifdef DEBUG
      for (double i: cumsum_svd0)
        cout << i << ' ';
      cout << "sum: " << sum << endl;
    #endif
  
      
      // determines ev0
      vector<double> ev0;
      for (size_t i=0; i<cumsum_svd0.size(); ++i){
        ev0.push_back(cumsum_svd0[i] / sum);
      }

    // debug print of the ev0 values
    #ifdef DEBUG
      for (double i: ev0)
        cout << i << ' ';
      cout << endl;
    #endif
  
      
      // singular values from svd trunction levels based on ev0 and thresholds
      n100  = find_svd_trunc(ev0, 1);
      n9999 = find_svd_trunc(ev0, .9999);
      n999  = find_svd_trunc(ev0, .999);
      n99   = find_svd_trunc(ev0, .99);
      

      return 0;
    }

    int set_options(struct pressio_options const& options) override {
      get(options, "data_analysis:meta", &meta);
      return 0;
    }

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      block_metadata* meta_cast = (block_metadata*) meta;
      set(opt, "info:filepath",     meta_cast->file->filepath);
      set(opt, "info:filename",     meta_cast->file->filename);
      set(opt, "info:dataset",      meta_cast->file->dataset);
      set(opt, "info:dim1",         meta_cast->file->dims[0]);
      set(opt, "info:dim2",         meta_cast->file->dims[1]);
      set(opt, "info:dim3",         meta_cast->file->dims[2]);
      set(opt, "block:method",      meta_cast->block_method);
      set(opt, "block:total_count", meta_cast->total_blocks);
      set(opt, "block:number",      meta_cast->block_number);
      set(opt, "block:size",        meta_cast->block_size);
      set(opt, "block:dim1",        meta_cast->block_dims[0]);
      set(opt, "block:dim2",        meta_cast->block_dims[1]);
      set(opt, "block:dim3",        meta_cast->block_dims[2]);
      set(opt, "block:loc1",        meta_cast->block_loc[0]);
      set(opt, "block:loc2",        meta_cast->block_loc[1]);
      set(opt, "block:loc3",        meta_cast->block_loc[2]);
      set(opt, "stat:n100",         n100);
      set(opt, "stat:n9999",        n9999);
      set(opt, "stat:n999",         n999);
      set(opt, "stat:n99",          n99);
      return opt;
    }
    struct pressio_options get_configuration() const override {
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
      set(opt, "stat:n100",         "svd truncation representing 100% of the data");
      set(opt, "stat:n9999",        "svd truncation representing 99.99% of the data");
      set(opt, "stat:n999",         "svd truncation representing 99.9% of the data");
      set(opt, "stat:n99",          "svd truncation representing 99% of the data");


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
    void* meta;
};

static pressio_register metrics_data_analysis_plugin(metrics_plugins(), "data_analysis", [](){ return compat::make_unique<data_analysis_metric_plugin>(); });




// dependent on error bound
class compress_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      size_t dims_num = input->num_dimensions();
      // auto dims = input->dimensions();
      auto dtype = input->dtype();
      auto num_elements = input->num_elements();

      q_entropy = qentropy(input->data(), error_bound, dtype, num_elements);
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
      set(opt, "stat:qentropy",     q_entropy);
      set(opt, "info:error_bound",  error_bound);
      set(opt, "info:bound_type",   bound_type);
      set(opt, "info:compressor",   compressor);
      return opt;
    }
    struct pressio_options get_configuration() const override {
      pressio_options opts;
      set(opts, "pressio:stability", "experimental");
      set(opts, "pressio:thread_safe", static_cast<int32_t>(pressio_thread_safety_multiple));
      return opts;
    }
    struct pressio_options get_documentation_impl() const override {
      pressio_options opt;
      set(opt, "pressio:description", "statistics requiring an error bound");
      set(opt, "stat:qentropy",       "quantized entropy based upon error bound");
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
