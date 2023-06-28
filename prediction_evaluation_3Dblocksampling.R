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
  library('reshape2')
  library('tidyverse')
  library("lattice")
  library('stringr')
  library('gtools')
  library('gridExtra')
  library('data.table')
  library('mixreg')
})
#(.packages())
#detach(package:plyr)

set.seed(1234)
comp_thresh <- 200

source('functions_paper.R')

#var_nm <- "qmcpack_3D block"
#app <- "qmcpack"
#global_buffers <- 288

#var_nm <- "hurricane_step48"
#app <- "hurricane_step48"
#global_buffers <- 13

var_nm <- "hurricane_CLOUDall"
app <- "hurricane_CLOUDall"
global_buffers <- 48

upper_count = 128
block_counts = seq(from=16, to=128, by=8)
block_sizes <- c(4, 6, 8, 12, 16, 24, 32)
error_bnds <- c(1e-2, 1e-3, 1e-4, 1e-5)
samplemethod <- "UNIFORM"
smplmthd <- str_to_lower(samplemethod)
modeltype <- "MIXED"
mdltype <- str_to_lower(modeltype)

#error_modes <- c('pressio:abs', 'pressio:rel')
error_modes <- c('pressio:abs')

#compressors <- c('bit_grooming', 'digit_rounding', 'fpzip', 'mgard', 'sz', 'sz3', 'tthresh', 'zfp')
compressors <- c('bit_grooming', 'fpzip', 'sz', 'sz3', 'zfp')

res_real <- c()
res_pred <- c()
res_mape <- c()
res_blocksize <- c()
res_blockcount <- c()
res_compressor <- c()
res_errbnd <- c()
res_errmode <- c()
res_lengths <- c()
res_uppererr <- c()
res_lowererr <- c()
res_quartilerange <- c()

for (block_size in block_sizes) {
  data <- read_data(app,upper_count, block_size)
  for (block_count in block_counts){
    start.time <- Sys.time()
    print(paste("Peforming model on ", block_count, "blocks"))
    
    limit <- block_count*global_buffers
    if (max(data$block.number,na.rm = TRUE) < block_count) {
      break
    }
    data_lim <- select_data(data, block_count, global_buffers, compressors, error_bnds, error_modes,samplemethod)
    
    data_loc <- compute_loc(data_lim)
    ## dependent on compression scheme
    for (comp in compressors) {
      for (error_bnd in error_bnds){ 
        for (error_mode in error_modes){
          predictors <- extract_cr_predictors(data_loc, error_mode, error_bnd, comp, comp_thresh)
          ### perform the regression and print its prediction assessment 
          unique_des <- paste0("size", block_size, "_count", block_count, "_", comp, "_", formatC(error_bnd, format='e',digits=0), "_", error_mode)
          tryCatch(expr = {
      
            res <- cr_blocking_model(predictors, kf=8, modeltype)
            res_pt <- cbind(res$ytest, res$pred)
            
            res_real <- c(res_real, res$ytest)
            res_pred <- c(res_pred, res$pred)
            res_mape <- c(res_mape, res$res_cv[2,3])
            res_quartilerange <- c(res_quartilerange, res$res_cv[3,3] - res$res_cv[1,3])
            res_lowererr <- c(res_lowererr, res$res_cv[1,3])
            res_uppererr <- c(res_uppererr, res$res_cv[3,3])
            res_blocksize <- c(res_blocksize, block_size)
            res_blockcount <- c(res_blockcount, block_count)
            res_compressor <- c(res_compressor, comp)
            res_errbnd <- c(res_errbnd, error_bnd)
            res_errmode <- c(res_errmode, error_mode)
            res_lengths <- c(res_lengths, length(res$ytest))

            }, error = function(e){ print(paste(unique_des, "::", e))}
          )
        }
      }
    }
    end.time <- Sys.time()
    print(paste0("exec time: ", end.time - start.time))
  }
}

#save all relevant trial results (with one data point per configuration) as dataframe
formatC(error_bnds, format='e', digits=0)
fdf <- cbind(res_blocksize,
             res_blockcount,
             res_compressor,
             res_errbnd,
             res_errmode,
             res_lengths,
             res_mape,
             res_quartilerange,
             res_lowererr,
             res_uppererr)
fdf <- as.data.frame(fdf)
fdf$res_mape <- sapply(fdf$res_mape, as.numeric)
fdf$res_quartilerange <- sapply(fdf$res_quartilerange, as.numeric)
fdf$res_uppererr <- sapply(fdf$res_uppererr, as.numeric)
fdf$res_lowererr <- sapply(fdf$res_lowererr, as.numeric)
fdf$res_blocksize <- sapply(fdf$res_blocksize, as.numeric)
fdf$res_blockcount <- sapply(fdf$res_blockcount, as.numeric)
fdf$res_errbnd <- sapply(fdf$res_errbnd, as.numeric)
fdf$res_lengths <- sapply(fdf$res_lengths, as.numeric)
formatC(fdf$res_errbnd, format='e', digits=0)


#write trial results to file
fwrite(fdf, paste0(getwd(),"/",var_nm,"_", smplmthd, "_",mdltype,"_fdf.csv"))
fwrite(list(res_real), paste0(getwd(), "/", var_nm,"_",smplmthd, "_",mdltype,"_real.csv"))
fwrite(list(res_pred), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_pred.csv"))



