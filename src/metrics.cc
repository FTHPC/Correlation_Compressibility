#include "compress.h"

using namespace std;
using namespace std::string_literals;


class data_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      size_t dims_num = input->num_dimensions();
      auto dims = input->dimensions();
      auto dtype = input->dtype();

      if (dims_num != 2 && dims_num != 3) {
        return set_error(1, "Invalid amount of dimensions. Only 2D and 3D supported");
      }

      std::reverse(dims.begin(), dims.end()); //put in row major order

      // compute singular values and store values in ascending order
      Eigen::MatrixXd svd0_s = svd_sv(input->data(), dims_num, dims, dtype);

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

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      set(opt, "data_analysis:n100", n100);
      set(opt, "data_analysis:n9999", n9999);
      set(opt, "data_analysis:n999", n999);
      set(opt, "data_analysis:n99", n99);

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
      set(opt, "pressio:description", "Basic error statistics that can be computed in in one pass");
      set(opt, "data_analysis:n100",  "n100");
      set(opt, "data_analysis:n9999", "n9999");
      set(opt, "data_analysis:n999",  "n999");
      set(opt, "data_analysis:n99",   "n99");

      return opt;
    }
    std::unique_ptr<libpressio_metrics_plugin> clone() override {
      return compat::make_unique<data_analysis_metric_plugin>(*this);
    }
    const char* prefix() const override {
      return "data_analysis";
    }
    compat::optional<double> n100, n9999, n999, n99;
};

static pressio_register metrics_data_analysis_plugin(metrics_plugins(), "data_analysis", [](){ return compat::make_unique<data_analysis_metric_plugin>(); });



usi times_sset = 0;

// dependent on error bound
class compress_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      // size_t dims_num = input->num_dimensions();
      // auto dims = input->dimensions();
      auto dtype = input->dtype();
      auto num_elements = input->num_elements();

      // const float* ptr = static_cast<const float*>(input->data());    

      q_entropy = qentropy(input->data(), 1e-3, dtype, num_elements);
      std::cout << ++times_sset << std::endl;
      return 0;
    }

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      set(opt, "compress_analysis:qentropy", q_entropy);
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
      set(opt, "pressio:description",         "Basic error statistics that can be computed in in one pass");
      set(opt, "compress_analysis:qentropy",  "The quantized entropy based upon error bound");
      return opt;
    }
    std::unique_ptr<libpressio_metrics_plugin> clone() override {
      return compat::make_unique<compress_analysis_metric_plugin>(*this);
    }
    const char* prefix() const override {
      return "compress_analysis";
    }

    
    compat::optional<double> q_entropy;
};

static pressio_register metrics_compress_analysis_plugin(metrics_plugins(), "compress_analysis", [](){ return compat::make_unique<compress_analysis_metric_plugin>(); });
