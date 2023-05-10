/* 
    svd.cc
    Performs 3D and 2D SVD decomposition
    Clemson University and Argonne National Laboratory

    Eigen for svd https://eigen.tuxfamily.org/
*/

#include <Eigen/SVD>
#include <stdlib.h>
#include "compress.h"
// #include <RInside.h> 

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
    srand(time(NULL));
    int key = rand() % 100000;
    string output = filepath + to_string(key) + ".txt";
  
    // DOES NOT APPLY
    // reverse order of dimensions for julia
    // std::vector<size_t> dims = dimensions;
    // std::reverse(dims.begin(), dims.end());

    stringstream result;
    string julia_file = GPU_ACC ? "svd_cuda.jl" : "svd_cpu.jl";

    result << "julia -t 4 ./julia/" << julia_file << " " << filepath << " " << output << " ";
    copy(dimensions.begin(), dimensions.end(), ostream_iterator<int>(result, " "));
    
    string result_s = result.str();

    cout << result_s << endl;


    // run process for SVD3D
    if(system(result_s.c_str()) == -1) cerr << "Could not run Julia code" << endl;

    // read in julia created output file using key
    ifstream input(output, ios::binary);
    // seeks to end and finds position in bytes
    input.seekg (0, ios::end);
    streampos size = input.tellg();
    size_t elements = size / sizeof(double);

    // create buffer to store file contents
    char *buffer = new char [size];
    // seeks back to beginning after obtaining size
    input.seekg (0, ios::beg);
    input.read (buffer, size);
    // close and remove temp file
    input.close();
    string remove = "rm " + output;     
    system(remove.c_str());


    double* svds = (double*)buffer;
    Map<MatrixXd> sing(svds, 1, elements);
    return sing;
}


/* PUBLIC FUNCTIONS available in compress.h */

/*  svd_sv
 *  returns the singular value matrix based on the dimensions
 *  of the dataset inputted (num_dim)
 */
MatrixXd svd_sv(void* ptr, usi num_dim, void* block_meta, void* file_meta)
{
    file_metadata* meta = (file_metadata*) file_meta;
    if (num_dim == 2)
        return SVD_2D_Jacobi(ptr, meta->dims, meta->dtype);
    else { 
        if (block_meta) {
            block_metadata* meta = (block_metadata*) block_meta;
            return SVD_3D_Tucker(ptr, meta->block_dims, meta->file->dtype, meta->block_filepath);
        } else {
            return SVD_3D_Tucker(ptr, meta->dims, meta->dtype, meta->filepath);
        }
    }
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
