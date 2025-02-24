rm(list=ls())

#for when you mess up with plyr and dplyr
detachAllPackages <- function() {
  basic.packages <- c("package:stats","package:graphics","package:grDevices",
                      "package:utils","package:datasets","package:methods",
                      "package:base")
  package.list <- search()[ifelse(unlist(gregexpr("package:",search()))==1,TRUE,FALSE)]
  package.list <- setdiff(package.list,basic.packages)
  if (length(package.list)>0) {
    for (package in package.list) {
      detach(package, character.only=TRUE) 
    }
  }
}

detachAllPackages()

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

source('cr_predict.R')
source('data.R')

apps <- c("qmcpack","hurricane_step48","hurricane_CLOUD","hurricane_PRECIP","SCALE-LETKF", "SDRBENCH-Miranda-256x384x384")
var_nms <- c("qmcpack", "hurricane_step48", "hurricane_CLOUD","hurricane_PRECIP", "SCALE-LETKF", "Miranda")
fnames <- c("qmcpack", "hurricane_step48", "CLOUD","PRECIP","SCALE", "Miranda")
buffers <- c(288,13,48,48,11,7)
fprefixes <- c("","","","","SDRBENCH-SCALE-98x1200x1200_climate_", "")

#dims <- c(26, 1800, 3600) #CESM
#dims <- c(100,500,500) #hurricane
#dims <- c(69,69,115) #qmcpack
#dims <- c(98,1200,1200) #SCALE

bit_grooming <- "bit_grooming"
sperr <- "sperr"
sz <- "sz"
sz3 <- "sz3"
zfp <- "zfp"

app_idx <- 2
var_nm <- var_nms[app_idx]
fname <- fnames[app_idx]
app <- apps[app_idx]
global_buffers <- buffers[app_idx]
fprefix <- fprefixes[app_idx]

upper_count = 128
block_counts = seq(from=16, to=128, by=8)
block_sizes <- c(16,20, 24, 28, 32)
#block_sizes <- c(8,9,10,11,12,13,14,15,16,17,18,19,20,24,28,32)
error_bnds <- c(1e-2, 1e-3, 1e-4, 1e-5)

samplemethods <- c("STRIDE","UNIFORM")
samplemethod <- "STRIDE"; smplmthd <- str_to_lower(samplemethod)

modeltypes <- c("LINEAR","MIXED")
modeltype <- "MIXED"; mdltype <- str_to_lower(modeltype)

error_modes <- c('pressio:abs')

#compressors <- c('bit_grooming', 'digit_rounding', 'fpzip', 'mgard', 'sz', 'sz3', 'tthresh', 'zfp')
compressors <- c('bit_grooming','sperr', 'sz', 'sz3','tthresh', 'zfp')

kf <- 5

#pkgs <- (.packages())
#if ('plyr' %in% pkgs) {
#  if ('reshape2' %in% pkgs) {
#    detach('package:reshape2',unload=TRUE)
#  }
#  detach('package:plyr',unload=TRUE)
#  plyrflag <- 1
#}

thresh <- 200

for (j in 1:1) {
  real <- c()
  pred <- c()
  mape <- c()
  blocksize <- c()
  blockcount <- c()
  compressor <- c()
  errorbound <- c()
  errormode <- c()
  lengths <- c()
  uppererr <- c()
  lowererr <- c()
  quartilerange <- c()
  folds <- c()
  coefficient <- c()
  
  for (block_size in block_sizes) {
    data <- read_data(app, block_size)
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
            predictors <- extract_cr_predictors(data_loc, error_mode, error_bnd, comp, thresh)
            
            des <- paste0("size", block_size, "_count", block_count, "_", comp, "_", formatC(error_bnd, format='e',digits=0), "_", error_mode)
            ### perform the regression and save its prediction assessment 
            tryCatch(expr = {
              res <- predict_cr(predictors,modeltype,kf)
              res_pt <- cbind(res$ytest, res$pred)
              
              real <- c(real, res$ytest)
              pred <- c(pred, res$pred)
              mape <- c(mape, res$res_cv[2,3])
              quartilerange <- c(quartilerange, res$res_cv[3,3] - res$res_cv[1,3])
              lowererr <- c(lowererr, res$res_cv[1,3])
              uppererr <- c(uppererr, res$res_cv[3,3])
              blocksize <- c(blocksize, block_size)
              blockcount <- c(blockcount, block_count)
              compressor <- c(compressor, comp)
              errorbound <- c(errorbound, error_bnd)
              errormode <- c(errormode, error_mode)
              lengths <- c(lengths, length(res$ytest))
              folds <- c(folds, res$folds)
              coefficient <- c(coefficient, res$cv_coef)
  
              }, error = function(e){ print(paste(des, "::", e))}
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
  fdf <- cbind(blocksize,
               blockcount,
               compressor,
               errorbound,
               errormode,
               lengths,
               mape,
               quartilerange,
               lowererr,
               uppererr)
  fdf <- cbind(rep(var_nm,nrow(fdf)),fdf)
  fdf <- as.data.frame(fdf)
  fdf$mape <- sapply(fdf$mape, as.numeric)
  fdf$quartilerange <- sapply(fdf$quartilerange, as.numeric)
  fdf$uppererr <- sapply(fdf$uppererr, as.numeric)
  fdf$lowererr <- sapply(fdf$lowererr, as.numeric)
  fdf$blocksize <- sapply(fdf$blocksize, as.numeric)
  fdf$blockcount <- sapply(fdf$blockcount, as.numeric)
  fdf$errorbound <- sapply(fdf$errorbound, as.numeric)
  fdf$lengths <- sapply(fdf$lengths, as.numeric)
  formatC(fdf$errorbound, format='e', digits=0)
  fdf$samplemethod <- rep(smplmthd,nrow(fdf))
  fdf$model <- rep(mdltype,nrow(fdf))

  colnames(fdf) <- c("app", "blocksize","blockcount","compressor","errorbound","errormode","lengths","mape","quartilerange","lowererr","uppererr","samplemethod","model")
}

#if (plyrflag) {
#  library('reshape2')
#  library('plyr')
#}

#write trial results to file
fwrite(fdf, paste0(getwd(),"/",var_nm,"_", smplmthd, "_",mdltype,"_fdf.csv"))
fwrite(list(real), paste0(getwd(), "/", var_nm,"_",smplmthd, "_",mdltype,"_real.csv"))
fwrite(list(pred), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_pred.csv"))
fwrite(list(folds), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_folds.csv"))
fwrite(list(coefficient), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_coef.csv"))
fwrite(list(unique(data$info.filename)), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_files.csv"))

fwrite(list(compressor), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_comps.csv"))
fwrite(list(errorbound), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_errbnds.csv"))
fwrite(list(blocksize), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_blocksizes.csv"))
fwrite(list(blockcount), paste0(getwd(), "/", var_nm,"_", smplmthd,"_",mdltype,"_blockcounts.csv"))


tmpcoef <- coefficient

getAccuracyByFile <- function(fnames,real,pred,folds,coefficient,compressor,errorbound,blocksize,blockcount) {
  for (j in 1:1) {
    inds <- seq(from=1, to=length(real), by=length(unique(data$info.filename)))
    coef_inds <- seq(from=1, to=length(coefficient), by=4)
    acc_by_file <- c()
    trains <- c()
    files <- sort(unique(data$info.filename))
    stride <- length(files) - 1
    cidx <- 1
    max_fold <- max(folds)
    for (ind in inds) {
      fold <- folds[ind:(ind+stride)]
      tmp <- as.data.frame(cbind(files,fold))
      colnames(tmp) <- c('files','fold')
      tmp <- tmp[order(tmp$fold,decreasing=FALSE),]
      tmp['real'] <- real[ind:(ind+stride)]
      tmp['pred'] <- pred[ind:(ind+stride)]
      
      train <- c()
      coef <- c()
      for (fld in 1:max_fold) {
        trn <- tmp[tmp$fold != fld,'files']
        repl <- nrow(tmp[tmp$fold == fld,])
        if (!repl) {
          cidx <- cidx + 4
          next
        }
        coefs <- coefficient[cidx:(cidx+3)]
        for (i in 1:repl) {
          train[[length(train)+1]] <- list(sort(trn))
          coef[[length(coef)+1]] <- list(coefs)
        }
        cidx <- cidx + 4
      }
      tmp <- cbind(tmp, I(train))
      tmp <- cbind(tmp, I(coef))
      tmp <- tmp[order(tmp$files),]
      acc_by_file <- rbind(acc_by_file, tmp)
    }
    compressor <- rep(compressor, each=length(files))
    errorbound <- rep(errorbound,each=length(files))
    blocksize <- rep(blocksize,each=length(files))
    blockcount <- rep(blockcount, each=length(files))
    
    acc_by_file <- cbind(compressor,blocksize,blockcount,errorbound,acc_by_file)
  }
  #return (acc_by_file)
  #fwrite(acc_by_file, paste0(getwd(),"/",var_nm,"_", smplmthd, "_",mdltype,"_acc.csv"))
}


acc_by_file$relerr <- (abs(acc_by_file$pred - acc_by_file$real) / acc_by_file$real)*100



tmpdf <- acc_by_file %>% filter(compressor == "sz") %>% filter(errorbound == 1e-3)
tmpdf <- tmpdf  %>% filter(real < 200)










