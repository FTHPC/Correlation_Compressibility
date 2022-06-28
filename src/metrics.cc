/* 
    metrics.cc
    Libpressio metrics plugins that call svd.cc and qentropy.cc to do analysis
    Clemson University and Argonne National Laboratory
*/

#include "compress.h"

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

      std::reverse(dims.begin(), dims.end()); //put in row major order

      // compute singular values and store values in ascending order
      Eigen::MatrixXd svd0_s = svd_sv(input->data(), dims_num, dims, dtype, filepath);
      
      if (dims_num == 2){
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
      
      } 

      return 0;
    }

    int set_options(struct pressio_options const& options) override {
      get(options, "info:filepath", &filepath);
      get(options, "info:filename", &filename);
      get(options, "info:dataset",  &dataset);
      return 0;
    }

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      set(opt, "info:filepath", filepath);
      set(opt, "info:filename", filename);
      set(opt, "info:dataset",  dataset);
      set(opt, "info:dim1",     dim1);
      set(opt, "info:dim2",     dim2);
      set(opt, "info:dim3",     dim3);
      set(opt, "stat:n100",     n100);
      set(opt, "stat:n9999",    n9999);
      set(opt, "stat:n999",     n999);
      set(opt, "stat:n99",      n99);

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
      set(opt, "info:filepath", "full file path to locate dataset");
      set(opt, "info:filename", "name of the file");
      set(opt, "info:dataset",  "name of the dataset");
      set(opt, "info:dim1",  "dimension of the inputted data");
      set(opt, "info:dim2",  "second dimension of the inputted data");
      set(opt, "info:dim3",  "third dimension of the inputted data");
      set(opt, "stat:n100",  "svd truncation representing 100% of the data");
      set(opt, "stat:n9999", "svd truncation representing 99.99% of the data");
      set(opt, "stat:n999",  "svd truncation representing 99.9% of the data");
      set(opt, "stat:n99",   "svd truncation representing 99% of the data");


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
    std::string filepath;
    std::string filename;
    std::string dataset;
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
