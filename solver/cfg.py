# global variables/settings

X = "config:bound"
Y = "size:compression_ratio"
Z = "error_stat:psnr"

appdir = '/project/jonccal/fthpc/alpoulo/datasets/hurricane'
compresshome = '/project/jonccal/fthpc/alpoulo/repositories/Correlation_Compressibility'
solvedir = compresshome + '/solver'
resultsdir = solvedir + '/output/'
fields = ['CLOUD', 'PRECIP', 'P', 'QCLOUD', 'QGRAUP', 'QICE', 'QRAIN', 'QSNOW', 'QVAPOR', 'TC', 'U', 'V', 'W']

cr_max = 1000