/* 
    svd.cpp
    Performs 3D and 2D SVD decomposition
    Clemson University and Argonne National Laboratory

    TuckerMPI for 3D https://gitlab.com/tensors/TuckerMPI 
    Eigen for for 2D https://eigen.tuxfamily.org/
*/

#include <Eigen/SVD>
#include "compress.h"
using namespace Eigen; 
using namespace std;


/* PRIVATE FUNCTIONS for svd.cc */
// JacobiSVD 2D
MatrixXd SVD_2D_Jacobi(void* ptr, std::vector<size_t> dimensions, int dtype)
{
    if (dtype == pressio_float_dtype){
        float* d = (float*)ptr;
        Map<MatrixXf> mapped(d, dimensions[0], dimensions[1]);
        JacobiSVD<MatrixXf, 0> svd(mapped);
        return svd.singularValues().cast <double> ();
    } else if (dtype == pressio_double_dtype) {
        double* d = (double*)ptr;
        Map<MatrixXd> mapped(d, dimensions[0], dimensions[1]);
        JacobiSVD<MatrixXd, 0> svd(mapped);
        return svd.singularValues();
    } else {
        std::cerr << "ERROR: Unknown dtype; Exiting 30" << std::endl;
        exit(30);
    }
}

// TuckerMPI 3D
Eigen::MatrixXd SVD_3D_Tucker(void* ptr, std::vector<size_t> dimensions, int dtype)
{
    MatrixXd g(1, 4);
    g << 3, 5, 7, 3;
    // cout << g << endl;
    return g;
}


/* PUBLIC FUNCTIONS available in compress.h */

/*  svd_sv
 *  returns the singular value matrix based on the dimensions
 *  of the dataset inputted (num_dim)
 */
Eigen::MatrixXd svd_sv(void* ptr, usi num_dim, std::vector<size_t> dimensions, int dtype)
{
    if (num_dim == 2)
        return SVD_2D_Jacobi(ptr, dimensions, dtype);
    else 
        return SVD_3D_Tucker(ptr, dimensions, dtype);
}

/*  find_svd_trunc
 *  svd tranction level of singular values based on a threshold
 */
double find_svd_trunc(std::vector<double> ev0, double threshold)
{
    uli loc = 0;
    for (double val: ev0) {
        if(val >= threshold) break;  
        loc++;
    }
    return (double)100*((loc+1)/(double)ev0.size());
}
