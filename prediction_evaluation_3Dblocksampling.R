
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

block_counts = c(16, 32, 64)
# block_counts = c(50)


# block_sizes <- c(4, 6, 8, 12, 16)
block_sizes <- c(4, 6, 8, 12)

# error_bnds <- c(1e-2, 1e-3, 1e-4, 1e-5)
error_bnds <- c(1e-3)


# error_modes <- c('pressio:abs', 'pressio:rel')
error_modes <- c('pressio:abs')

compressors <- c('sz')
# compressors <- c('tthresh', 'bit_grooming', 'digit_rounding')

success <- FALSE 
m_key <- c()
m_data <- c()
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
          m_key <- paste0(comp, error_bnd, error_mode);
 
          tryCatch(expr = {
            res <- cr_blocking_model(predictors, kf=8)
            success <- TRUE

            png(file=paste0(unique_des, ".png"),
            width=600, height=350)
            plot(res$ytest, res$pred, xlab = "actual CR", ylab = "pred CR", main = unique_des)
            abline(a=0, b=1, col="red") 
            dev.off()

            
            ### row 2 col 3 signifies MAPE in the 0.5 quantile
            mape <- res$res_cv[2,3]
            m_data[[m_key]] <- append(m_data[[m_key]], list(data.frame(mape, comp, error_bnd, error_mode, block_size, block_count)))

          }, error = function(e){ print(paste(unique_des, "::", e))})
        }
      }
    }
  }
}



if (success == TRUE) {
  plotcolors <- colorRampPalette(c("gold","blue"))(6)

  for (v in ls(m_data)) {
    hash_df <- m_data[[v]]
    hash_comp <- hash_df[[1]]$comp
    hash_error_bnd <- hash_df[[1]]$error_bnd
    hash_error_mode <- hash_df[[1]]$error_mod

    hash_mapes <- c()
    hash_count <- c()
    hash_sizes <- c()
    for (d in hash_df) {
      hash_mapes <- append(hash_mapes, d$mape)
      hash_count <- append(hash_count, d$block_count)
      hash_sizes <- append(hash_sizes, d$block_size)
    }

    des <- paste0(hash_comp, "_", hash_error_bnd, "_", hash_error_mode)
    png(file=paste0("mape_count_", des, ".png"), width=600, height=350)
    
    sizes <- length(hash_sizes) / length(block_sizes)
    x1 <- hash_count[1:sizes]
    y1 <- hash_mapes[1:sizes]
    plot(x1, y1, xlab = "count", ylab = "mapes", 
         main = paste0("mape vs count ", des), col = plotcolors[1])
    abline(lm(y1 ~ x1))
    prev_end <- sizes
    for (j in 2:(sizes+1)) {
      end <- j*sizes
      x1 <- hash_count[(prev_end+1):end]
      y1 <- hash_mapes[(prev_end+1):end]

      points(x1, y1, col = plotcolors[j+1])
      abline(lm(y1 ~ x1))
      prev_end <- end
    }

    dev.off()
    # print(m_data[["zfp0.001pressio:abs"]])


  }
}
