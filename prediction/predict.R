source('cr_predict.R')
source('data.R')

corr_predict <- function(app,blocksizes,blockcounts,compressors,errorbounds,errormode,sample,model,buffers,thresh,kf,exclude=NA,outofsample=FALSE) {
  real <- c()
  pred <- c()
  mape <- c()
  blocksize <- c()
  blockcount <- c()
  compressor <- c()
  errorbound <- c()
  lengths <- c()
  uppererr <- c()
  lowererr <- c()
  quartilerange <- c()
  folds <- c()
  coefficient <- c()
  df_reg <- data.frame()
  components <- c()
  
  for (comp in compressors) {
    for (bs in blocksizes) {
      data <- read_data(app,comp,bs,exclude)
      print(paste("testing",comp,"with block size", bs))
      for (bc in blockcounts) {
        
        data_lim <- select_data(data, bc, buffers, comp, errorbounds, sample)
        if (!nrow(data_lim)) { next }
        data_loc <- compute_loc(data_lim)
        #
        ## dependent on compression scheme
        for (eb in errorbounds) {
          predictors <- extract_cr_predictors(data_loc,errormode,eb,comp,thresh)
          if (!nrow(predictors)) { next }
          if (app == "hurricane") {
            predictors$app <- gsub("f[[:digit:]]+.bin","",predictors$file)
          } else {
            predictors$app <- app 
          }
          #
          des <- paste0(app,"_", comp,"_size", bs, "_count", bc, "_", formatC(eb, format='e',digits=0))
          tryCatch(expr = {
            res <- predict_cr(predictors,model,2,outofsample)
            res_pt <- cbind(res$ytest, res$pred)
            
            real <- c(real, res$ytest)
            pred <- c(pred, res$pred)
            mape <- c(mape, res$res_cv[2,3])
            quartilerange <- c(quartilerange, res$res_cv[3,3] - res$res_cv[1,3])
            lowererr <- c(lowererr, res$res_cv[1,3])
            uppererr <- c(uppererr, res$res_cv[3,3])
            blocksize <- c(blocksize, bs)
            blockcount <- c(blockcount, bc)
            compressor <- c(compressor, comp)
            errorbound <- c(errorbound, eb)
            lengths <- c(lengths, length(res$ytest))
            folds <- c(folds, res$folds)
            coefficient <- c(coefficient, res$coef)
            df_reg <- rbind(df_reg,res$df_reg)
            components <- c(components,res$ncomps)
            
          }, error = function(e){ print(paste(des, "::", e))}
          )
        }
      } 
    }
  }
  
  files <- unique(data$info.filename)
  
  #store all relevant trial results
  #formatC(error_bnds, format='e', digits=0)
  fdf <- cbind(blocksize,blockcount,
               compressor,errorbound,rep(errormode,length(errorbound)),
               lengths,
               mape,quartilerange,
               lowererr,uppererr)
  fdf <- as.data.frame(fdf)
  #
  fdf$blocksize <- sapply(fdf$blocksize, as.numeric)
  fdf$blockcount <- sapply(fdf$blockcount, as.numeric)
  fdf$errorbound <- sapply(fdf$errorbound, as.numeric)
  formatC(fdf$errorbound, format='e', digits=0)
  #
  fdf$lengths <- sapply(fdf$lengths, as.numeric)
  fdf$mape <- sapply(fdf$mape, as.numeric)
  fdf$quartilerange <- sapply(fdf$quartilerange, as.numeric)
  fdf$uppererr <- sapply(fdf$uppererr, as.numeric)
  fdf$lowererr <- sapply(fdf$lowererr, as.numeric)
  #
  fdf <- cbind(rep(app,nrow(fdf)),fdf)
  fdf <- cbind(fdf,rep(str_to_lower(sample),nrow(fdf)))
  fdf <- cbind(fdf,rep(str_to_lower(model),nrow(fdf)))
  #
  colnames(fdf) <- c("app",
                     "blocksize","blockcount",
                     "compressor","errorbound","errormode",
                     "lengths",
                     "mape","quartilerange","lowererr","uppererr",
                     "samplemethod","model")
  return (list(fdf=fdf,real=real,pred=pred,coefficient=coefficient,folds=folds,components=components,files=files,df_reg=df_reg))
}

corr_predict_allEB <- function(app,blocksizes,blockcounts,compressors,errormode,sample,model,buffers,thresh,kf,exclude=NA,outofsample=FALSE) {
  real <- c()
  pred <- c()
  mape <- c()
  blocksize <- c()
  blockcount <- c()
  compressor <- c()
  errorbound <- c()
  lengths <- c()
  uppererr <- c()
  lowererr <- c()
  quartilerange <- c()
  folds <- c()
  coefficient <- c()
  components <- c()
  tries <- c()
  
  df_reg <- data.frame()
  
  for (comp in compressors) {
    for (bs in blocksizes) {
      data <- read_data(app,comp,bs,exclude)
      print(paste("testing",comp,"with block size", bs))
      for (bc in blockcounts) {
        
        data_lim <- select_data_allEB(data, bc, buffers, comp, sample)
        if (!nrow(data_lim)) { next }
        data_loc <- compute_loc(data_lim)
        #
        ## dependent on compression scheme
        predictors <- extract_cr_predictors_allEB(data_loc, errormode, comp, thresh)
        if (!nrow(predictors)) { next }
        if (app == "hurricane") {
          predictors$app <- gsub("f[[:digit:]]+.bin","",predictors$file)
        } else {
          predictors$app <- app 
        }
        des <- paste0(app,"_", comp,"_size", bs, "_count", bc)
        tryCatch(expr = {
          res <- predict_cr_allEB(predictors,model,kf,outofsample)
          res_pt <- cbind(res$ytest, res$pred)
          
          real <- c(real, res$ytest)
          pred <- c(pred, res$pred)
          mape <- c(mape, res$res_cv[2,3])
          quartilerange <- c(quartilerange, res$res_cv[3,3] - res$res_cv[1,3])
          lowererr <- c(lowererr, res$res_cv[1,3])
          uppererr <- c(uppererr, res$res_cv[3,3])
          blocksize <- c(blocksize, bs)
          blockcount <- c(blockcount, bc)
          compressor <- c(compressor, comp)
          errorbound <- c(errorbound, "all")
          lengths <- c(lengths, length(res$ytest))
          folds <- c(folds, res$folds)
          coefficient <- c(coefficient, res$coef)
          components <- c(components, res$ncomps)
          tries <- c(tries, res$tries)
          tmpdf <- res$df_reg
          tmpdf <- cbind(tmpdf, rep(comp, nrow(tmpdf)))
          tmpdf <- cbind(tmpdf, rep(bs, nrow(tmpdf)))
          tmpdf <- cbind(tmpdf, rep(bc, nrow(tmpdf)))
          df_reg <- rbind(df_reg,tmpdf)
          
        }, error = function(e){ print(paste(des, "::", e))}
        )
      }
    }
  }
  files <- unique(data$info.filename)
  
  #store all relevant trial results
  #formatC(error_bnds, format='e', digits=0)
  fdf <- cbind(blocksize,blockcount,
               compressor,errorbound,rep(errormode,length(errorbound)),
               lengths,
               mape,quartilerange,
               lowererr,uppererr)
  fdf <- as.data.frame(fdf)
  #
  fdf$blocksize <- sapply(fdf$blocksize, as.numeric)
  fdf$blockcount <- sapply(fdf$blockcount, as.numeric)
  #
  fdf$lengths <- sapply(fdf$lengths, as.numeric)
  fdf$mape <- sapply(fdf$mape, as.numeric)
  fdf$quartilerange <- sapply(fdf$quartilerange, as.numeric)
  fdf$uppererr <- sapply(fdf$uppererr, as.numeric)
  fdf$lowererr <- sapply(fdf$lowererr, as.numeric)
  #
  fdf <- cbind(rep(app,nrow(fdf)),fdf)
  fdf <- cbind(fdf,rep(str_to_lower(sample),nrow(fdf)))
  fdf <- cbind(fdf,rep(str_to_lower(model),nrow(fdf)))
  #
  colnames(fdf) <- c("app",
                     "blocksize","blockcount",
                     "compressor","errorbound","errormode",
                     "lengths",
                     "mape","quartilerange","lowererr","uppererr",
                     "samplemethod","model")
  
  colnames(df_reg) <- c("app","file","x4","x1","x2","x3","y","fold","compressor","blocksize","blockcount")
  
  return (list(fdf=fdf,real=real,pred=pred,coefficient=coefficient,folds=folds,files=files,components=components,df_reg=df_reg))
}




