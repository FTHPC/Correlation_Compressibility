/* 
    analysis.cpp
    Performs compression of 2D and 3D datasets using Libpressio
    Computes estimation statistics
    Clemson University and Argonne National Laboratory

    Libpressio https://robertu94.github.io/libpressio
*/


#include <libpressio.h>
#include <libpressio_ext/io/pressio_io.h>
#include <libpressio_ext/io/posix.h>
#include "compress.h"



int main() {
  pressio library;
  pressio_data metadata = pressio_data::owning(pressio_float_dtype, {500,500,100});
  pressio_io io = library.get_io("posix");
  io->set_options({
      {"io:path", "/home/runderwood/git/datasets/hurricane/100x500x500/CLOUDf48.bin.f32"}
    });
  pressio_data input = std::move(*io->read(&metadata));
  pressio_data compressed = pressio_data::empty(pressio_byte_dtype, {});
  pressio_data decompressed = pressio_data::owning(input.dtype(), input.dimensions());

  pressio_compressor compressor = library.get_compressor("pressio");
  compressor->set_options({
      { "pressio:abs", 1e-5 },
      { "pressio:compressor", "sz"s },
      { "pressio:metric", "svd"s },
    });

  compressor->compress(&input, &compressed);
  compressor->decompress(&compressed, &decompressed);

  auto metrics_results = compressor->get_metrics_results();
  std::cout << metrics_results << std::endl;

}
