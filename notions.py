#!/usr/bin/env python
import matplotlib.pyplot as plt
import h5py
import numpy as np
import libpressio

# plt.rcParams.update({
#     "text.usetex": True,
#     "font.family": "serif",
# })


file1 = h5py.File("/home/dkrasow/compression/datasets/notions/sample_gp_K1028_a1_Sample1.h5")
a1 = file1["Z"]

file2 = h5py.File("/home/dkrasow/compression/datasets/notions/sample_gp_K1028_a01_Sample1.h5")
a01 =  file2["Z"]

file3 = h5py.File("/home/dkrasow/compression/datasets/notions/sample_gp_K1028_a005_Sample1.h5")
a005 = file3["Z"]


def get_cr(dset, error_bound):
    comp = libpressio.PressioCompressor.from_config( {"compressor_id": "sz", "compressor_config": {"pressio:abs": error_bound, "pressio:metric": "size"}})
    out = np.array(dset)
    indata = np.array(dset)
    z = comp.encode(indata)
    comp.decode(z, out)
    return comp.get_metrics()["size:compression_ratio"]



CONFIGS = {
        "a1": a1,
        "a01": a01,
        "a005": a005,
}
NAMES = {
        "a1": "correlation  a = 1",
        "a01": "correlation  a = 0.1",
        "a005": "correlation  a = 0.05"
}
for name, f in CONFIGS.items():
    plt.imshow(f)
    plt.title(NAMES[name])
    plt.savefig(name + ".png")
    for eb in [1e-2, 1e-5]:
        print(NAMES[name], f"{eb:.0e}", f"{get_cr(f, eb):.1f}", sep="& ", end="\\\\\n")

