/* 
    svd.cpp
    Performs 3D and 2D SVD decomposition
    Clemson University and Argonne National Laboratory

    TuckerMPI for 3D https://gitlab.com/tensors/TuckerMPI 
    Eigen for for 2D https://eigen.tuxfamily.org/
*/


#include <Eigen/SVD>
#include "compress.h"


// JacobiSVD 2D
void SVD_2D_Jacobi(slice A)
{
    JacobiSVD<MatrixXf, 0> svd(A->data);
    A->SVD = svd.singularValues();
}


// Recursive divide and conquer SVD 2D
void SVD_2D_DC(slice A)
{
    BDCSVD<MatrixXf, 0> svd(A->data);
    A-->SVD = svd.singularValues();
}


// TuckerMPI 3D
void SVD_3D(tensor B)
{


}


int main()
{
    MatrixXf m = MatrixXf::Random(3,2);
    
    


}