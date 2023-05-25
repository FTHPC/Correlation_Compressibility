
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


var_nm <- "qmcpack 3D_block"

# block_counts = c(16)
block_counts = c(50)


#block_sizes <- c(4, 6, 8, 12, 16, 32)
block_sizes <- c(16)

# error_bnds <- c(1e-2, 1e-3, 1e-4, 1e-5)
error_bnds <- c(1e-3)


error_modes <- c('pressio:abs', 'pressio:rel')
# error_modes <- c('pressio:abs')

compressors <- c('sz')
# compressors <- c('tthresh', 'bit_grooming', 'digit_rounding')


for (block_size in block_sizes) { 
  for (block_count in block_counts){

    data <- read_data(block_count, block_size)
    data_loc <- compute_loc(data)
    ## dependent on compression scheme
    for (comp in compressors) {
      for (error_bnd in error_bnds){ 
        for (error_mode in error_modes){
          predictors <- extract_cr_predictors(data_loc, error_mode, error_bnd, comp, comp_thresh)
          ### perform the regression and print its prediction assessment 
          unique_des <- paste0("size", block_size, "_count", block_count, "_", comp, "_", error_bnd, "_", error_mode)
          tryCatch(expr = {
      
            res <- cr_blocking_model(predictors, kf=8)

            png(file=paste0(unique_des, ".png"),
            width=600, height=350)
            plot(res$ytest, res$pred, xlab = "actual CR", ylab = "pred CR", main = unique_des)
            abline(a=0, b=1, col="red") 
            dev.off()

            
        
            # print(res$res_cv[,3])
            # res_mape <- which(res$res_cv$Quantile==0.5)
            # df_mape <- res$res_cv[res_mape,]
           
            # print(df_mape)
            # print(res$ytest)

            # png(file=paste0("mape_", unique_des, ".png"),
            # width=600, height=350)
            # plot(res$ytest, df_mape, xlab = "actual log(CR)", ylab = "pred log(CR)", main = unique_des)
            # # abline(lm(pred ~ ytest, data = res), col = "red")
            # dev.off()
            
            
            }, error = function(e){ print(paste(unique_des, "::", e))}
          )
        }
      }
    }
  }
}
