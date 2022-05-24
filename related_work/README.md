# Related Work: Estimating the compressibility of SZ

Example of calling the estimate code

```bash
./gauss.py gauss.txt 97104
```

Alternatively, one can run for a specific 3D dataset provided by a filename
```bash 
python klasky.py --filename [FILENAME] --dtype [DTYPE] -o [OUTPUT].csv -d [DIM0] -d [DIM1] -d [DIM2] 
```

Then use the results from the output with the formula from the paper

Used with Permission from authors.  Code adopted from:

T. Lu et al., “Understanding and Modeling Lossy Compression Schemes on HPC Scientific Data,” in 2018 IEEE International Parallel and Distributed Processing Symposium (IPDPS), Vancouver, BC, May 2018, pp. 348–357. doi: 10.1109/IPDPS.2018.00044.

Changes:

+ Converted to Python-3 using 2to3.py
