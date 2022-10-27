#include <mpi.h>
#include <libpressio_ext/cpp/libpressio.h>
#include <libpressio_ext/cpp/serializable.h>
#include <libdistributed/libdistributed_comm.h>
#include <string>
#include <iostream>
using namespace std::string_literals;
int main(int argc, char *argv[])
{
  MPI_Init(&argc, &argv);
  int rank, size;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  pressio_options opts;
  if (rank == 0) {
  opts = {
    {"block:dim1", uint64_t{16}},
    {"block:dim2", uint64_t{16}},
    {"block:dim3", uint64_t{16}},
    {"block:method", "uniform"s},
    {"block:number", uint64_t{1}},
    {"block:size", uint64_t{4096}},
    {"block:total_count", uint64_t{3}},
    {"info:dataset", "SDRBENCH-Miranda-256x384x384"s},
    {"info:dim1", uint64_t{256}},
    {"info:dim2", uint64_t{384}},
    {"info:dim3", uint64_t{384}},
    {"info:filename", "velocityx.d64"s},
    {"info:filepath", "/home/dkrasow/compression/datasets/SDRBENCH-Miranda-256x384x384/velocityx.d64"s},
    {"stat:n100", 33.3333},
    {"stat:n99", 10.4167},
    {"stat:n999", 10.4167},
    {"stat:n9999", 10.4167},
  };
  }

  distributed::comm::bcast(opts, 0);

  for (int i = 0; i < size; ++i) {
    if (i == rank) {
      std::cout << i << std::endl;
      std::cout << opts << std::endl;
    }
    MPI_Barrier(MPI_COMM_WORLD);
  }


  MPI_Finalize();
  return 0;
}
