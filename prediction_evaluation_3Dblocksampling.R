
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

upper_count = 32
block_counts = 10:upper_count


global_buffers <- 288
block_sizes <- c(4, 6, 8, 12, 16)

# error_bnds <- c(1e-2, 1e-3, 1e-4, 1e-5)
error_bnds <- c(1e-3)


# error_modes <- c('pressio:abs', 'pressio:rel')
error_modes <- c('pressio:abs')

compressors <- c('sz', 'zfp')
# compressors <- c('tthresh', 'bit_grooming', 'digit_rounding')

success <- FALSE 
m_key <- c()
m_data <- c()
for (block_size in block_sizes) { 
  ### data is the upper block
  data <- read_data(upper_count, block_size)
  for (block_count in block_counts){
    print(paste("Peforming model on ", block_count, "blocks"))
    ### limit amount of data grabbed based on block_count*global_buffers
    ### we put this here to limit to reduce the occurances of the locality calculation
    limit <- block_count*global_buffers
    data_lim <- select_data(data, limit, compressors, error_bnds, error_modes)
    ### peform locality calculation based on the data grabbed
    data_loc <- compute_loc(data_lim)
    ### dependent on compression scheme
    for (comp in compressors) {
      for (error_bnd in error_bnds){ 
        for (error_mode in error_modes){
          predictors <- extract_cr_predictors(data_loc, error_mode, error_bnd, comp, comp_thresh)
          unique_des <- paste0("size", block_size, "_count", block_count, "_", comp, "_", error_bnd, "_", error_mode)
          m_key <- paste0(comp, error_bnd, error_mode);
 
          tryCatch(expr = {
            ### perform the regression
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
  plotcolors <- colorRampPalette(c("red","blue"))(6)

  ### split up by unique keys
  for (v in ls(m_data)) {
    hash_df <- m_data[[v]]
    hash_comp <- hash_df[[1]]$comp
    hash_error_bnd <- hash_df[[1]]$error_bnd
    hash_error_mode <- hash_df[[1]]$error_mod
   
    ### hash_* lists contain content for each unique block size obtained by the key
    hash_mapes <- c()
    hash_count <- c()
    hash_sizes <- c()
    for (d in hash_df) {
      hash_mapes <- append(hash_mapes, d$mape)
      hash_count <- append(hash_count, d$block_count)
      hash_sizes <- append(hash_sizes, d$block_size)
    }

    ### sizes_cnt is the amount of block sizes ran per block size
    sizes_cnt <- length(hash_sizes) / length(block_sizes)

    prev_end <- 0
    ### plot for each block size
    ### mape vs block_count
    for (j in 1:length(block_sizes)) {
      des <- paste0(hash_sizes[prev_end+1], "_", hash_comp, "_", hash_error_bnd, "_", hash_error_mode)
      png(file=paste0("mape_size", des, ".png"), width=600, height=350)

      end <- j*sizes_cnt
      x1 <- hash_count[(prev_end+1):end]
      y1 <- hash_mapes[(prev_end+1):end]

      plot(x1, y1, xlab = "count", ylab = "mapes", 
         main = paste0("mape vs count on block size ", des), col = plotcolors[1])
      abline(lm(y1 ~ x1), col = plotcolors[1])
      prev_end <- end
      dev.off()
    }
    

    ### FOR COMBINING THE GRAPHS IF WANTED
    # des <- paste0(hash_comp, "_", hash_error_bnd, "_", hash_error_mode)
    # png(file=paste0("mape_count_", des, ".png"), width=600, height=350)
    
    ### first plot point
    # x1 <- hash_count[1:sizes_cnt]
    # y1 <- hash_mapes[1:sizes_cnt]
    # plot(x1, y1, xlab = "count", ylab = "mapes", 
    #      main = paste0("mape vs count ", des), col = plotcolors[1])
    # abline(lm(y1 ~ x1), col = plotcolors[1])
    # prev_end <- sizes_cnt 
    # ### remaining plot points
    # for (j in 2:(sizes_cnt+1)) {
    #   end <- j*sizes_cnt
    #   x1 <- hash_count[(prev_end+1):end]
    #   y1 <- hash_mapes[(prev_end+1):end]

    #   points(x1, y1, col = plotcolors[j+1])
    #   abline(lm(y1 ~ x1), col = plotcolors[j+1])
    #   prev_end <- end
    # }
    
    ### the heat map can be added here using a combo technique


  }
}
