
rm(list=ls())
suppressPackageStartupMessages({
  library('dplyr')
  library('fields')
  library('pals')
  library('mgcv')
  library('glmnet')
  library('viridis')
  library('rhdf5')
  library('rTensor')
})
set.seed(1234)
comp_thresh <- 200

source('functions_paper.R')

### loading data (David, you need to input your filename here)
filenames <- Sys.glob("/home/dkrasow/compression/outputs/*.csv")
error_bnds <- c(1e-2, 1e-3, 1e-4, 1e-5)
#error_modes <- c('pressio:abs', 'pressio:rel')
error_modes <- c('pressio:abs')
compressors <- c('sz')
#compressors <- c('sz', 'zfp', 'mgard')

for (filename in filenames) { 
  print(filename)
  gaussian <- 0
  var_nm <- "Miranda 3D_block"
  data <- read.csv(filename)
  data <- as.data.frame(data)
  for (comp in compressors) {
    for (error_bnd in error_bnds){ 
      for (error_mode in error_modes){

        list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=0, sz3=FALSE, comp_thresh=comp_thresh, quant=0, qbins=0, dim3D=TRUE)

        ### perform the regression and print its prediction assessment 
        df <- list_df$df[[comp]]
        tryCatch(expr = {res_gam_mir_sz <- cr_regression_gam(df, kf=8, graph=0, fig_nm='fig1', data_nm=var_nm,compressor_nm=comp, error_mode, error_bnd)},
                 error = function(e){ print(paste("Cannot fit model", e))})
      }
    }
  }
}
