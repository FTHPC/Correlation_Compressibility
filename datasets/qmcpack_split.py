# split einspline_288_115_69_69.pre.f32 (4D) into 288 3D datasets
import numpy as np
import pandas as pd

def main():

    input_file_full = '/home/dkrasow/compression/datasets/qmcpack/einspline_288_115_69_69.pre.f32'
    Vx = np.fromfile(input_file_full, dtype = np.float32).reshape((288,115,69,69))
    
    for i in range(0, 288):
        filename = "obital_" + str(i) + ".f32"
        Vx[i].reshape((115, 69, 69)).tofile(filename)



if __name__ == "__main__":
    main()

