#include "compress.h"

using namespace std;
using namespace std::string_literals;


class data_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      size_t dims_num = input->num_dimensions();
      auto dims = input->dimensions();
      // auto dtype = input->dtype();
      const float* ptr = static_cast<const float*>(input->data());

      //not recommended, just an example of what is possible
      // if(dtype != pressio_float_dtype) {
      //   return set_error(1, "only float supported");
      // }

      std::reverse(dims.begin(), dims.end()); //put in row major order
      
      
      (void)ptr;

      /* run functions to produce metrics */
      
      // 2D SVD
      if (dims_num == 2)
        SVD_2D_Jacobi(ptr, svd);
      // 3D SVD
      else if (dims_num == 3)
        SVD_3D_Tucker(ptr, svd);

      // singular values from svd trunction levels
      
      n100  = find_svd_trunc(svd, 1);
      n9999 = find_svd_trunc(svd, .9999);
      n999  = find_svd_trunc(svd, .999);
      n99   = find_svd_trunc(svd, .99);


#ifdef DEBUG
      // std::cout << svd << std::endl;
#endif
      return 0;
    }

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      //newer way
      set(opt, "data_analysis:svd", svd);
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
      set(opt, "data_analysis:svd",   "the singular value decomposition");
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

    compat::optional<float*> svd;
    compat::optional<double> n100, n9999, n999, n99;
};

static pressio_register metrics_data_analysis_plugin(metrics_plugins(), "data_analysis", [](){ return compat::make_unique<data_analysis_metric_plugin>(); });





// dependent on error bound
class compress_analysis_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      // size_t dims_num = input->num_dimensions();
      // auto dims = input->dimensions();
      // auto dtype = input->dtype();

      const float* ptr = static_cast<const float*>(input->data());    
      (void)ptr;

      qentropy = 1.234;
      return 0;
    }

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;
      set(opt, "compress_analysis:qentropy", qentropy);
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

    
    compat::optional<double> qentropy;
};

static pressio_register metrics_compress_analysis_plugin(metrics_plugins(), "compress_analysis", [](){ return compat::make_unique<compress_analysis_metric_plugin>(); });
