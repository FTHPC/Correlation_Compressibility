/* 
    svd.cc
    Performs 3D and 2D SVD decomposition
    Clemson University and Argonne National Laboratory

    Eigen for svd https://eigen.tuxfamily.org/
*/

#include <Eigen/SVD>
#include "compress.h"
#include <nlohmann/json.hpp>

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


// SVD 3D
MatrixXd SVD_3D_Tucker(void* ptr, std::vector<size_t> dimensions, int dtype, std::string filepath)
{
    // // call the Julia code
    // ostringstream julia_call;
    // julia_call << "julia $COMPRESS_HOME/src/hosvd.jl.julia " << filepath << ' ' << dimensions[2] << ' ' << dimensions[1] << ' ' << dimensions[0];
    // string julia_call_str = julia_call.str();

    // char *julia_call_ptr = (char *) calloc(1, julia_call_str.length() + 1);
    // strcpy(julia_call_ptr, julia_call_str.c_str());
    // array<char, 128> buffer;
    // string output_julia;
    // unique_ptr<FILE, decltype(&pclose)> pipe(popen(julia_call_ptr, "r"), pclose);
    // if (!pipe) throw runtime_error("popen() failed!");
    // while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr)
    //     output_julia += buffer.data();

    // nlohmann::json json = nlohmann::json::parse(output_julia);
    // cout << json["singular_modes"] << endl;
    // return json["singular_modes"];
    return MatrixXd::Random(1,1);
}


/* PUBLIC FUNCTIONS available in compress.h */

/*  svd_sv
 *  returns the singular value matrix based on the dimensions
 *  of the dataset inputted (num_dim)
 */
MatrixXd svd_sv(void* ptr, usi num_dim, std::vector<size_t> dimensions, int dtype, std::string filepath)
{
    if (num_dim == 2)
        return SVD_2D_Jacobi(ptr, dimensions, dtype);
    else 
        return SVD_3D_Tucker(ptr, dimensions, dtype, filepath);
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
