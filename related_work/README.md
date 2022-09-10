# Related Work: Estimating the compressibility of SZ

Example of calling the estimate code

```bash
./gauss.py gauss.txt 97104
```

Alternatively, one can provide the following arguments to run a specified dataset using the method in the paper below.
```bash 
python ipdps2018.py --filename [FILENAME] --dtype [DTYPE] -o [OUTPUT].csv -d [DIM0] -d [DIM1] -d [DIM2] 
```

Then use the results from the output with the formula from the paper

Used with Permission from authors.  Code adopted from:

T. Lu et al., “Understanding and Modeling Lossy Compression Schemes on HPC Scientific Data,” in 2018 IEEE International Parallel and Distributed Processing Symposium (IPDPS), Vancouver, BC, May 2018, pp. 348–357. doi: 10.1109/IPDPS.2018.00044.

Changes:

+ Converted to Python-3 using 2to3.py


# Related Work: Estimating compressibility using a Block Sampling approach

One can provide the following arguments to run a specified dataset using a block sampling approach to estimate compression ratios
```bash 
python tpds2018.py --filename [FILENAME] --dtype [DTYPE] -o [OUTPUT].csv -d [DIM0] -d [DIM1] -d [DIM2] 
```

Code adopted from:

X. Liang, S. Di, D. Tao, S. Li, B. Nicolae, Z. Chen, and F. Cappello, 1040 “Improving performance of data dumping with lossy compression for scientific simulation,” p. 11, 2019

D. Tao, S. Di, X. Liang, Z. Chen, and F. Cappello, “Optimizing lossy compression rate-distortion from automatic online selection between SZ and ZFP,” IEEE Transactions on Parallel and Distributed Systems, vol. 30, no. 8, pp. 1857–1871, 2019.
