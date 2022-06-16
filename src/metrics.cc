#include <libpressio_ext/cpp/libpressio.h>
#include <std_compat/optional.h>
#include <std_compat/memory.h>
#include <iostream>

using namespace std::string_literals;

class svd_metric_plugin : public libpressio_metrics_plugin {
    int begin_compress_impl(const struct pressio_data * input, struct pressio_data const * ) override {
      auto dims = input->dimensions();
      auto dtype = input->dtype();
      const float* ptr = static_cast<const float*>(input->data());

      //not recommended, just an example of what is possible
      if(dtype != pressio_float_dtype) {
        return set_error(1, "only float supported");
      }

      std::reverse(dims.begin(), dims.end()); //put in row major order

      (void)ptr;
      svd = 1.23; //TODO call eigen's svd functions

      return 0;
    }

    pressio_options get_metrics_results(pressio_options const &)  override {
      pressio_options opt;

      //newer way
      set(opt, "svd:svd", svd);

      //older way
      /*
      if(svd) {
        set(opt, "svd:svd", *svd);
      } else {
        set_type(opt, "svd:svd", pressio_option_double_type);
      }
      */
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
      set(opt, "svd:svd", "the singular value decomp....");
      return opt;
    }
    std::unique_ptr<libpressio_metrics_plugin> clone() override {
      return compat::make_unique<svd_metric_plugin>(*this);
    }
    const char* prefix() const override {
      return "svd";
    }

    
    compat::optional<double> svd;
};
static pressio_register metrics_svd_plugin(metrics_plugins(), "svd", [](){ return compat::make_unique<svd_metric_plugin>(); });



int main() {
  pressio library;
  pressio_data metadata = pressio_data::owning(pressio_float_dtype, {500,500,100});
  pressio_io io = library.get_io("posix");
  io->set_options({
      {"io:path", "/home/dkrasow/compression/datasets/SDRBENCH-Hurricane-ISABEL-100x500x500/CLOUDf48.bin.f32"}
    });
  pressio_data input = std::move(*io->read(&metadata));
  pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
  pressio_data decompressed = pressio_data::owning(input.dtype(), input.dimensions());

  pressio_compressor compressor = library.get_compressor("pressio");
  compressor->set_options({
      { "pressio:metric", "svd"s },
    });

  compressor->compress(&input, &compressed);
  //compressor->decompress(&compressed, &decompressed);

  auto metrics_results = compressor->get_metrics_results();
  std::cout << metrics_results << std::endl;

}
