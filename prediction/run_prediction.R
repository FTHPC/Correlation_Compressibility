rm(list=ls())

#for when you mess up with plyr and dplyr in global workspace
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
#
suppressPackageStartupMessages({
  library('dplyr')
  #library(dplyr, warn.conflicts = FALSE)
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
#
set.seed(1234)
source('predict.R')
#
apps <- c("hurricane","hurricane_step48","hurricane_CLOUD","hurricane_P",
          "hurricane_PRECIP","hurricane_QCLOUD","hurricane_QGRAUP","hurricane_QICE",
          "hurricane_QRAIN","hurricane_QSNOW","hurricane_QVAPOR","hurricane_TC",
          "hurricane_U","hurricane_V","hurricane_W","NYX",
          "SDRBENCH-Miranda-256x384x384","SDRBENCH-SCALE","qmcpack")

var_nms <- c("hurricane","hurricane_step48","hurricane_CLOUD","hurricane_P",
          "hurricane_PRECIP","hurricane_QCLOUD","hurricane_QGRAUP","hurricane_QICE",
          "hurricane_QRAIN","hurricane_QSNOW","hurricane_QVAPOR","hurricane_TC",
          "hurricane_U","hurricane_V","hurricane_W","NYX",
          "Miranda","SCALE","qmcpack")

fnames <- c("hurricane_multi","hurricane_step48","CLOUD","P",
             "PRECIP","QCLOUD","QGRAUP","QICE",
             "QRAIN","QSNOW","QVAPOR","TC",
             "U","V","W","NYX",
             "Miranda","SCALE","qmcpack")

nbuffers <- c(240,13,48,48,
              48,48,48,48,
              48,48,48,48,
              48,48,48,6,
              7,11,288)
#
app_idx <- 17
var_nm <- var_nms[app_idx]
fname <- fnames[app_idx]
app <- apps[app_idx]
buffers <- nbuffers[app_idx]
#
if (app_idx == 1) { exclude="hurricane_step48" } else { exclude=NA }
#
bit_grooming <- "bit_grooming"
sperr <- "sperr"
sz <- "sz"
sz3 <- "sz3"
tthresh <- "tthresh"
zfp <- "zfp"
#
compressors <- c(bit_grooming, sperr, sz, sz3,tthresh, zfp)
#compressors <- c(zfp)
#
#blockcounts <- seq(from=16, to=128, by=8)
blockcounts <- 2^seq(from=4,to=7)
#blockcounts <- c(128)
#blocksizes <- c(8,12,16,20,24)
blocksizes <- c(16,20,24,28,32)
#blocksizes <- c(32)
errorbounds <- c(1e-2, 1e-3, 1e-4, 1e-5)
#
#samplemethods <- c("STRIDE","UNIFORM", "SOBOL")
samplemethods <- "SOBOL"; 
#modeltypes <- c("FLEXMIX","LINEAR")
modeltypes <- "FLEXMIX"; 
errormode <- c('pressio:abs')
#
thresh <- 200
#
allEB <- FALSE
outofsample <- FALSE
kf <- 5
#if(allEB) { kf <- 10 } else { kf <- 5 }
  
for (modeltype in modeltypes) {
  for (samplemethod in samplemethods) {
    mdltype <- str_to_lower(modeltype)  
    smplmthd <- str_to_lower(samplemethod)
    
    print(paste("running",app,mdltype,smplmthd,"with outofsample =",outofsample,"and allEB =",allEB))

    if (allEB) {
      res <- corr_predict_allEB(app,blocksizes,blockcounts,
                          compressors,errormode,
                          samplemethod,modeltype,
                          buffers,thresh,kf,exclude,outofsample)
    } else {
      res <- corr_predict(app,blocksizes,blockcounts,
                          compressors,errorbounds,errormode,
                          samplemethod,modeltype,
                          buffers,thresh,kf,exclude,outofsample)
    }
    
    fdf <- res$fdf
    real <- res$real
    pred <- res$pred
    coefficient <- res$coefficient
    components <- res$components
    df_reg <- res$df_reg
    
    if (nrow(fdf)) {
      print(paste("experiment on", app, modeltype, samplemethod, "succeeded!"))
      fdf$app <- rep(var_nm,nrow(fdf))
      ## write trial results to file
      fpath <- paste0("../",var_nm,"_", smplmthd, "_",mdltype)
      if(outofsample) { fpath <- paste0(fpath,"_outofsample") } else { fpath <- paste0(fpath,"_insample") }
      if(allEB) { fpath <- paste0(fpath,"_allEB") }
      #
      fwrite(fdf, paste0(fpath,"_fdf.csv"))
      if(length(list(real))) {
        fwrite(list(real), paste0(fpath,"_real.csv"))
        fwrite(list(pred), paste0(fpath,"_pred.csv"))
      }
      if (length(coefficient)) {
        fwrite(list(unlist(coefficient)), paste0(fpath,"_coef.csv"))
      }
      if (nrow(df_reg)) {
        fwrite(df_reg,paste0(fpath,"_df_reg.csv"))
      }
      if(nrow(components)) {
        fwrite(list(components,paste0(fpath,"_components.csv")))
      }
    } else {
      print(paste("experiment on", app, modeltype, samplemethod, "failed!"))
    }
  }
}







