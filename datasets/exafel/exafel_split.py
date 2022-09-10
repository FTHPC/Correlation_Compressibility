import numpy as np

def main():

    input_file_full = '/home/dkrasow/compression/datasets/qmcpack/smd-cxif5315-r129-dark.u16'
    Vx = np.fromfile(input_file_full, dtype = np.uintc).reshape((288,115,69,69))
    
    for i in range(0, 288):
        filename = "event_" + str(i) + ".f32"
        Vx[i].astype('uintc').tofile(filename)



if __name__ == "__main__":
    main()

