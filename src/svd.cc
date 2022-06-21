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
using Eigen::MatrixXf;
using namespace std;

// JacobiSVD 2D
void SVD_2D_Jacobi(const float* ptr, compat::optional<float*> m)
{
    JacobiSVD<MatrixXf> svd(*ptr, 0);
    //svd.singularValues();
    *m = 0;
}


// Recursive divide and conquer SVD 2D
void SVD_2D_DC(const float* ptr, compat::optional<float*> m)
{
    BDCSVD<MatrixXf> svd(*ptr, 0);
    // svd.singularValues();
    *m = 0;
}


// TuckerMPI 3D
void SVD_3D_Tucker(const float* ptr, compat::optional<float*> m)
{
    MatrixXf g = MatrixXf::Random(3,2);
    cout << g << endl;
    *m = 0;
}

//svd tranction level of singular values based on a threshold
double find_svd_trunc(compat::optional<float*> m, float threshold)
{
    return (double)threshold*10000;
}
