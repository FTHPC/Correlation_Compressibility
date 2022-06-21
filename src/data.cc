/* 
    data.cpp
    Manages data structures to store statistics regarding:
    1. 2D slices of datasets
    2. 3D tensors of datasets
    Clemson University and Argonne National Laboratory
*/


#include "compress.h"

slice slice_init()
{

    return created;
}


tensor tensor_init()
{

    return created;
}

void slice_free(slice A)
{
    free(A);
}


void tensor_free(tensor A)
{
    free(A);
}