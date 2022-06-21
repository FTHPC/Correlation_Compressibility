#include <mpi.h>
int main(int argc, char *argv[])
{
  int rank, shared_rank;
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm shared;
  MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, rank, MPI_INFO_NULL, &shared);
  MPI_Comm_rank(shared, &shared_rank);

  size_t num_elements = 500*500*100;
  MPI_Win win;
  float* window;
  if(shared_rank == 0) {
    MPI_Win_allocate_shared(sizeof(float)*num_elements, 0, MPI_INFO_NULL, shared, &window, &win);
  } else {
    MPI_Win_allocate_shared(0, 0, MPI_INFO_NULL, shared, &window, &win);
    MPI_Win_shared_query(win, 0, NULL, NULL, &window);
  }


  MPI_Win_free(&win);

  MPI_Finalize();
  return 0;
}
