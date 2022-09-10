'''
compare_compressors.py
Produce statistics using specified compressors with libpressio. 
Thanks to robertu94 providing example code snippets.

'''
from compress_package.convert import slice_data
import os
import json
import ctypes
import itertools
import libpressio
import subprocess
import numpy as np
import cv2 as cv
'''
@type function
Finds the ssim between two matrices of data
Code is implemented from:
https://github.com/szcompressor/qcat/tree/master/qcat

inputs:
    data_class                  : the class of data inputted that will store the metrics generated
    full_original_path          : the inputed data path before being compressed
    full_comp_path              : the decompressed data path after being compressed
returns: the computed ssim
'''
def get_qcat_ssim(data_class, full_original_path, full_decomp_path):
    d1 = data_class.dimensions[0]
    d2 = data_class.dimensions[1]
    if data_class.dtype == 'float64':
        flag = '-d'
    else:
        flag = '-f'
    '''
    qcat calculateSSIM
    Usage: calculateSSIM [datatype (-f or -d)] [original data file] [decompressed data file] 
            [dimesions... (from fast to slow)]
			-f means single precision; -d means double precision
    Example: calculateSSIM -f CLOUD_100x500x500.dat CLOUD_100x500x500.dat.sz.out 500 500 100
    '''
    qcat_out = subprocess.getoutput([f"calculateSSIM {flag} {full_original_path} {full_decomp_path} {d2} {d1}"])
    return qcat_out.split('ssim =')[1]

    

'''
@type function
Finds the ssim between two matrices of data
Code is implemented from:
https://docs.opencv.org/master/d5/dc4/tutorial_video_input_psnr_ssim.html
inputs:
    data_class              : the class of data inputted that will store the metrics generated
    decomp_data             : the decompressed data after being compressed
returns: the computed ssim
'''
def get_open_cv_ssim(data_class, decomp_data):
    C1 = 6.5025
    C2 = 58.5225
    # INITS
    I1 = np.float64(data_class.data) 
    I2 = np.float64(decomp_data)
    I2_2 = I2 * I2 # I2^2
    I1_2 = I1 * I1 # I1^2
    I1_I2 = I1 * I2 # I1 * I2
    # END INITS
    # PRELIMINARY COMPUTING
    mu1 = cv.GaussianBlur(I1, (11, 11), 1.5)
    mu2 = cv.GaussianBlur(I2, (11, 11), 1.5)
    mu1_2 = mu1 * mu1
    mu2_2 = mu2 * mu2
    mu1_mu2 = mu1 * mu2
    sigma1_2 = cv.GaussianBlur(I1_2, (11, 11), 1.5)
    sigma1_2 -= mu1_2
    sigma2_2 = cv.GaussianBlur(I2_2, (11, 11), 1.5)
    sigma2_2 -= mu2_2
    sigma12 = cv.GaussianBlur(I1_I2, (11, 11), 1.5)
    sigma12 -= mu1_mu2
    t1 = 2 * mu1_mu2 + C1
    t2 = 2 * sigma12 + C2
    t3 = t1 * t2                    # t3 = ((2*mu1_mu2 + C1).*(2*sigma12 + C2))
    t1 = mu1_2 + mu2_2 + C1
    t2 = sigma1_2 + sigma2_2 + C2
    t1 = t1 * t2                    # t1 =((mu1_2 + mu2_2 + C1).*(sigma1_2 + sigma2_2 + C2))
    ssim_map = cv.divide(t3, t1)    # ssim_map =  t3./t1;
    mssim = cv.mean(ssim_map)       # mssim = average of ssim map
    return mssim[0]

'''
@type function
obtain the input data of the h5 slice by reading it using libpressio
inputs:
    data_class              : the class of data inputted that will store the metrics generated
returns : the data read from the h5 file
'''
def get_input_data(data_class):
    #must import sliced file with libpressio
    return libpressio.PressioIO.from_config({
                "io_id": "hdf5",
                "io_config": {
                "io:path": data_class.full_sliced_file_path,
                "hdf5:dataset": data_class.dataset_name
                }
            }).read(None)

'''
@type function
makes the configuration of the compressors used 
inputs:
    compressor_id           : string that has the id of compressor, ex: 'sz'
    bound                   : a float that contains the error bound for the lossy compressor
returns : configuration of the compressor
'''
def make_config(compressor_id: str, bound: float, boundmode: list, dtype: str, sz_opt=None):
    prec = 0
    if boundmode:
        boundmode = "pressio:" + boundmode


    if compressor_id == "sz":
        if sz_opt == None:
            return {boundmode: bound}
        elif sz_opt == "high":
            return {boundmode: bound, "sz:quantization_intervals": 1E6}

    elif compressor_id == "sz3":
        if sz_opt == "interpolation":
            return {boundmode: bound, "sz3:algorithm_str": "algo_interp"}
        elif sz_opt == "lorenzo":
            return {boundmode: bound,
                    "sz3:algorithm_str": "algo_lorenzo_reg",
                    "sz3:lorenzo": True,
                    "sz3:lorenzo2": False,
                    "sz3:regression": False,
                    "sz3:regression2": False,}
        elif sz_opt == "regression":
            return {boundmode: bound,
                    "sz3:algorithm_str": "algo_lorenzo_reg",
                    "sz3:lorenzo": False,
                    "sz3:lorenzo2": False,
                    "sz3:regression": True,
                    "sz3:regression2": False,}

    elif compressor_id == "zfp":
        return {boundmode: bound}
    elif compressor_id == "mgard":
        return {boundmode: bound} 
    elif compressor_id == "bit_grooming":
        if bound == 1E-2:
            prec = 1
        elif bound == 1E-3:
            prec = 1
        elif bound == 1E-4:
            prec = 1
        elif bound == 1E-5:
            prec = 3
        return {"bit_grooming:n_sig_digits": prec,"bit_grooming:error_control_mode_str": "NSD", "bit_grooming:mode_str": "BITGROOM"}    
    elif compressor_id == "digit_rounding":
        if bound == 1E-2:
            prec = 2
        elif bound == 1E-3:
            prec = 6
        elif bound == 1E-4:
            prec = 11
        elif bound == 1E-5:
            prec = 11
        return {"digit_rounding:prec": prec}   
    #fpzip requires even prec values if the data is float64
    #prec of 4 is the minimum for float64
    elif compressor_id == "fpzip":
        if bound == 1E-2:
            prec = 2 if dtype == 'float32' else 4
        elif bound == 1E-3:
            prec = 10
        elif bound == 1E-4:
            prec = 13 if dtype == 'float32' else 14
        elif bound == 1E-5:
            prec = 15 if dtype == 'float32' else 16
        return {"fpzip:prec": prec}
    elif compressor_id == "tthresh":
        ctypes.cdll.LoadLibrary('liblibpressio_tthresh.so')
        return {boundmode: bound}
    elif compressor_id == "linear_quantizer":
        return {boundmode: bound}
    else:
        raise RuntimeError("unknown configuration")

'''
@type function
runs the inputed compressors on the data inputted within the dataclass. metrics of the compression
will be stored within the data_class. Calls get_ssim()
inputs:
    data_class              : the class of data inputted that will store the metrics generated
    compressors             : A list of str of the compressors to be used ex: ["sz", "zfp"]
    start                   : the start of the np.logspace, default=-5
    stop                    : the stop of the np.logspace, default=-3
    bound_type              : the bound type to be run, default ['rel', 'abs']
no return
'''
def run_compressors(data_class, compressors, start=-5, stop=-3, bound_type=['rel', 'abs']):
    input_data = data_class.data
    decomp_data = input_data.copy()
    independent_metrics={}
    #bound/compressor indepenedent 
    if "stat:entropy" in data_class.compress_metrics_needed:
        independent_metrics.update({'stat:entropy':entropy(data_class.data)})
    if "stat:quantized_entropy" in data_class.compress_metrics_needed:
        independent_metrics.update({'stat:quantized_entropy':quantized_entropy(data_class.data)})
    if "stat:quantized_rel_entropy" in data_class.compress_metrics_needed:
        independent_metrics.update({'stat:quantized_rel_entropy':quantized_rel_entropy(data_class.data)})
    
    #bound/compressor dependent
    comp_count = 0 
    for compressor_id, bound, boundmode in itertools.product(compressors, np.logspace(start=start, stop=stop, num=-1*(start-stop-1)), bound_type):
        sz_opt = None
     
        if compressor_id in ["fpzip", "digit_rounding", "bit_grooming"] and boundmode == "rel":
            continue
        elif compressor_id == "sz:high":
            sz_opt = "high"
            compressor_id = "sz"
        elif compressor_id == "sz:interpolation":
            sz_opt = "interpolation"
            compressor_id = "sz3"
        elif compressor_id == "sz:lorenzo":
            sz_opt = "lorenzo"
            compressor_id = "sz3"
        elif compressor_id == "sz:regression":
            sz_opt = "regression"
            compressor_id = "sz3"  

        compressor = libpressio.PressioCompressor.from_config({
            # configure which compressor to use
            "compressor_id": "pressio",
            # configure the set of metrics to be gathered
            "early_config": {
                "pressio:compressor": compressor_id,
                "pressio:metric": "composite",
                "composite:plugins": ["time", "size", "error_stat"]
            },
            "compressor_config": make_config(compressor_id, bound, boundmode, data_class.dtype, sz_opt)                    
            })


        # run compressor to determine metrics
        try:
            comp_data = compressor.encode(input_data)
            decomp_data = compressor.decode(comp_data, decomp_data)
        except:
            print(f"ERROR: {compressor_id} failed on {data_class.filename}")
        #necessary to find binary ssim, writes two binary finles
        if "error_stat:ssim" in data_class.compress_metrics_needed:
            input_filename = "input_data_"+str(os.path.splitext(data_class.filename)[0])+'.in'
            full_original_path = slice_data.custom_binary_slice(input_data, input_filename, 
                                        data_class.dataset_directory, data_class.temp_folder)
            
            decomp_dataset_name = "comp_data_"+str(os.path.splitext(data_class.filename)[0])
            decomp_filename = decomp_dataset_name+'_'+compressor_id+'_'+str(bound)+'.out'
            full_decomp_path = slice_data.custom_binary_slice(decomp_data, decomp_filename, 
                                        data_class.dataset_directory, data_class.temp_folder)

        libpressio_metrics = compressor.get_metrics()

        metrics = {}
        #parese the metrics only grabbing what we need
        metrics.update({"info:compressor": compressor_id, 
                        "info:bound": bound,
                        "info:bound_mode": boundmode,
                        "info:quantized": data_class.quantized,
                        "info:quantized_mode": data_class.quantized_mode})

        if compressor_id == "sz":
            if sz_opt=="high":
                metrics.update({"sz:quantization_intervals":1E6})
                metrics.update({"sz:predictor_mode":"default"})
            else  : 
                metrics.update({"sz:quantization_intervals":"default"})
                metrics.update({"sz:predictor_mode":"default"})
        elif compressor_id=="sz3":
            metrics.update({"sz:quantization_intervals":"default"})
            metrics.update({"sz:predictor_mode":sz_opt})
        else:
            metrics.update({"sz:quantization_intervals":None})
            metrics.update({"sz:predictor_mode":None})

        if "error_stat:ssim" in data_class.compress_metrics_needed:
            metrics.update({"error_stat:ssim": get_qcat_ssim(data_class, full_original_path, full_decomp_path)})
            os.remove(full_original_path)
            os.remove(full_decomp_path)
        if "error_stat:open_cv_ssim" in data_class.compress_metrics_needed:
            metrics.update({"error_stat:open_cv_ssim": get_open_cv_ssim(data_class, decomp_data)})
        if "stat:entropy" in data_class.compress_metrics_needed:
            metrics.update({'stat:entropy':independent_metrics.get('stat:entropy')})
        if "stat:quantized_entropy" in data_class.compress_metrics_needed:
            metrics.update({'stat:quantized_entropy':independent_metrics.get('stat:quantized_entropy')})
        if "stat:quantized_rel_entropy" in data_class.compress_metrics_needed:
            metrics.update({'stat:quantized_rel_entropy':independent_metrics.get('stat:quantized_rel_entropy')})
    
        for key in data_class.compress_metrics_needed:
            val = libpressio_metrics.get(key)
            if val:
                metrics.update({key:val})

        data_class.set_compression_measurements(f"{compressor_id}_bound_{bound}_{comp_count}", metrics)
        comp_count += 1


'''
@type functon
quantizes the data and stores in the data class
inputs: data_class              : the class of data inputted that will store the metrics generated
no return
'''
def quantize(data_class, bound, boundmode):
    decomp_data = data_class.data
    quan = "linear_quantizer"

    compressor = libpressio.PressioCompressor.from_config({
        # configure which compressor to use
        "compressor_id": "pressio",
         "early_config": {
            "pressio:compressor": "linear_quantizer",
            "pressio:metric": "composite",
            "composite:plugins": ["time", "size", "error_stat"]
            },
        "compressor_config": make_config(quan, bound, boundmode, data_class.dtype)                    
        })
    comp_data = compressor.encode(decomp_data)
    decomp_data = compressor.decode(comp_data, decomp_data)
    data_class.set_quantized(bound, boundmode)
    data_class.set_data(decomp_data.reshape(data_class.dimensions))


'''
@type function
inputs: d                      : numpy array of data
returns: entropy of the given dataset
'''
def entropy(d):
    """returns the per-symbol entropy"""
    _, counts = np.unique(d, return_counts=True)
    prob = counts/d.size
    return -(prob * np.log2(prob)).sum()

'''​
@type function
inputs: d                      : numpy array of data
returns: entropy of the given dataset
'''
def quantized_entropy(d, eps=1e-6, return_quants=False):
    """returns the quantized by the error bound"""
    quant = np.round((d - d.min())/eps)
    if return_quants:
        return entropy(quant), quant
    else:
        return entropy(quant)

'''
@type function
inputs: d                      : numpy array of data
returns: entropy of the given dataset
'''
def quantized_rel_entropy(d, eps=1e-6, return_quants=False):
    assert np.all(d > 0)
    return quantized_entropy(np.log2(d), eps=eps, return_quants=return_quants)
