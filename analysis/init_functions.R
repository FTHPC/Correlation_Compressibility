

############################################################################################################################
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
############################################################################################################################
### read data
getGlobalCRs <-function(app,exclude=NA){
  #
  name <- paste0("outputs/",app,"*block_size32.csv")
  filenames <- Sys.glob(name)
  #
  if (!is.na(exclude)) { filenames <- grep(exclude, filenames, invert=TRUE, value = TRUE) }
  #
  fdf <- c()
  for (filename in filenames) {
    print(filename)
    data <- read.csv(filename)
    data <- as.data.frame(subset(data,block.number == 1))
    #
    tmpdf <- data %>% dplyr::select(info.filename,info.compressor,info.bound_type,info.error_bound,global.compression_ratio)
    fdf <- rbind(fdf,tmpdf)
  }
  appcol <- rep(app, length(nrow(fdf)))
  fields <- gsub('f[0-9]+.bin','',fdf$info.filename)
  timesteps <- as.numeric(gsub('\\D','',fdf$info.filename))
  fdf$info.filename <- NULL
  fdf <- cbind(appcol,fields,timesteps,fdf)
  colnames(fdf) <- c('app','field','timestep','compressor','boundtype','errorbound','globalCR')
  rownames(fdf) <- NULL
  #
  fdf$errorbound <- as.numeric(fdf$errorbound)
  fdf$globalCR <- as.numeric(fdf$globalCR)
  #
  fdf <- fdf[with(fdf,order(compressor,field,timestep,errorbound)),]
  
  return(fdf)
}

############################################################################################################################
getFDF <- function(app,samplemethod,model,oos=FALSE,allEB=FALSE) {
  #
  fdfpath <- paste0('rawdata_analysis/fdf/', app, '_', samplemethod,'_',model)
  if(oos) { fdfpath <- paste0(fdfpath,'_outofsample') } 
  if (allEB) { fdfpath <- paste0(fdf_path,'_allEB') }
  fdfpath <- paste0(fdfpath,'_fdf.csv')
  #
  fdf <- read_csv(fdfpath, col_names = TRUE,show_col_types = FALSE)
  fdf["mape"][sapply(fdf["mape"], is.infinite)] <- NA
  fdf <- na.omit(fdf)
  #
  levels(fdf$errorbound) <- c(1e-2,1e-3,1e-4,1e-5)
  #
  return (fdf)
}

getDF_reg <- function(app,samplemethod,model,oos=FALSE,allEB=FALSE,insmp=FALSE) {
  #
  fdfpath <- paste0('rawdata_analysis/', app, '/', app, '_', samplemethod,'_',model)
  if(oos) { fdfpath <- paste0(fdfpath,'_outofsample') }
  if(insmp) { fdfpath <- paste0(fdfpath,'_insample') }
  if (allEB) { fdfpath <- paste0(fdfpath,'_allEB') }
  fdfpath <- paste0(fdfpath,'_df_reg.csv')
  #
  fdf <- read_csv(fdfpath, col_names = TRUE,show_col_types = FALSE)
  #fdf["mape"][sapply(fdf["mape"], is.infinite)] <- NA
  #fdf <- na.omit(fdf)
  #
  #levels(fdf$errorbound) <- c(1e-2,1e-3,1e-4,1e-5)
  #
  return (fdf)
}

getFDF_allApps <- function(exclude) {
  name <- paste0('rawdata_analysis/fdf/*.csv')
  fdf <- c()
  filenames <- Sys.glob(name)
  if (!is.na(exclude)) {
    filenames <- grep(exclude, filenames, invert=TRUE, value = TRUE)  
  }
  for(file in filenames) {
    data <- read.csv(file)
    data <- as.data.frame(data)
    data["mape"][sapply(data["mape"], is.infinite)] <- NA
    data <- na.omit(data)
    fdf <- rbind(fdf,data)
  }
  return (fdf)
}

getFDF_allConfigs <- function(app, allEB = FALSE) {
  
  fdf_sl <- getFDF(app,"stride","linear")
  fdf_ul <- getFDF(app,"uniform","linear")
  fdf_sf <- getFDF(app,"stride","flexmix")
  fdf_uf <- getFDF(app,"uniform","flexmix")
  fdf_sl$modelsample <- as.factor("uniform linear")
  fdf_ul$modelsample <- as.factor("random linear")
  fdf_sf$modelsample <- as.factor("uniform mixed")
  fdf_uf$modelsample <- as.factor("random mixed")
  fdf <- rbind(fdf_sl,fdf_ul,fdf_sf,fdf_uf)
  fdf$errorbound <- as.character(formatC(fdf$errorbound,format='e',digits=0))
  
  if (allEB) {
    fdf_sl_eb <- getFDF(app,"stride","linear",allEB=1)
    fdf_ul_eb <- getFDF(app,"uniform","linear",allEB=1)
    fdf_sf_eb <- getFDF(app,"stride","flexmix",allEB=1)
    fdf_uf_eb <- getFDF(app,"uniform","flexmix",allEB=1)
    fdf_sl_eb$modelsample <- as.factor("uniform linear")
    fdf_ul_eb$modelsample <- as.factor("random linear")
    fdf_sf_eb$modelsample <- as.factor("uniform mixed")
    fdf_uf_eb$modelsample <- as.factor("random mixed")
    fdf <- rbind(fdf,fdf_sl_eb,fdf_ul_eb,fdf_sf_eb,fdf_uf_eb)
    
    levels(fdf$errorbound) <- c("all",1e-2,1e-3,1e-4,1e-5)
  }
  levels(fdf$modelsample) <- c("uniform linear","random linear","uniform mixed","random mixed")
  
  return(fdf) 
}

getFDF_allConfigs_allEB <- function(app) {
  
  fdf_sl_eb <- getFDF(app,"stride","linear",allEB=1)
  fdf_ul_eb <- getFDF(app,"uniform","linear",allEB=1)
  fdf_sf_eb <- getFDF(app,"stride","flexmix",allEB=1)
  fdf_uf_eb <- getFDF(app,"uniform","flexmix",allEB=1)
  fdf_sl_eb$modelsample <- as.factor("uniform linear")
  fdf_ul_eb$modelsample <- as.factor("random linear")
  fdf_sf_eb$modelsample <- as.factor("uniform mixed")
  fdf_uf_eb$modelsample <- as.factor("random mixed")
  fdf <- rbind(fdf_sl_eb,fdf_ul_eb,fdf_sf_eb,fdf_uf_eb)
  
  levels(fdf$modelsample) <- c("uniform linear","random linear","uniform mixed","random mixed")
  
  return(fdf) 
}

getFDF_mixedConfigs <- function(app, allEB=FALSE) {
  
  fdf_sf <- getFDF(app,"stride","flexmix")
  fdf_uf <- getFDF(app,"uniform","flexmix")
  fdf_sf$modelsample <- as.factor("uniform mixed")
  fdf_uf$modelsample <- as.factor("random mixed")
  
  fdf <- rbind(fdf_sf, fdf_uf)
  if (allEB) {
    fdf_sfe <- getFDF(app,"stride","flexmix",allEB=1)
    fdf_ufe <- getFDF(app,"uniform","flexmix",allEB=1)
    fdf_sfe$modelsample <- as.factor("uniform mixed")
    fdf_ufe$modelsample <- as.factor("random mixed")
    fdf <- rbind(fdf, fdf_sfe, fdf_ufe)
  }
  fdf <- fdf %>% group_by(app,blocksize,blockcount,compressor,modelsample) %>%
    dplyr::summarise("mape" = mean(mape,na.rm=TRUE))
  
  levels(fdf$modelsample) <- c("uniform mixed","random mixed")
  
  return(fdf) 
}

getFDF_mixedModels <- function(app,oos=FALSE) {
  fdf_sf <- getFDF(app,"stride","flexmix",oos=oos)
  fdf_uf <- getFDF(app,"uniform","flexmix",oos=oos)
  fdf_sf$modelsample <- as.factor("Uniform")
  fdf_uf$modelsample <- as.factor("Random")
  fdf <- rbind(fdf_sf,fdf_uf)
  levels(fdf$modelsample) <- c("Uniform","Random")
  levels(fdf$errorbound) <- c(1e-02,1e-03,1e-04,1e-05)
  
  return(fdf)
}

getFDF_linearModels <- function(app) {
  
  fdf_sl <- getFDF(app,"stride","linear",0)
  fdf_ul <- getFDF(app,"uniform","linear",0)
  fdf_sl$modelsample <- as.factor("Uniform")
  fdf_ul$modelsample <- as.factor("Random")
  fdf <- rbind(fdf_sl,fdf_ul)
  levels(fdf$modelsample) <- c("Uniform","Random")
  
  return(fdf) 
}

############################################################################################################################
filterPredictions <- function(fdf,real,pred) {
  compressors <- c()
  bs <- c()
  bc <- c()
  eb <- c()
  
  for (comp in unique(fdf$compressor)) {
    for (bsize in unique(fdf$blocksize)) {
      for (bcount in unique(fdf$blockcount)) {
        for (errbound in unique(fdf$errorbound)) {
          tmpdf <- fdf %>% filter(blocksize == bsize) %>% 
            filter(blockcount == bcount) %>%
            filter(compressor == comp) %>%
            filter(errorbound == errbound) 
          if(!nrow(tmpdf)) { next }
          compressors <- c(compressors, rep(comp, tmpdf$lengths))
          bs <- c(bs, rep(bsize, tmpdf$lengths))
          bc <- c(bc, rep(bcount, tmpdf$lengths))
          eb <- c(eb, rep(errbound, tmpdf$lengths))
        } 
      }
    }
  }
  pred_df <- as.data.frame(cbind(bs,bc,compressors,eb,real,pred))
  return (pred_df)
}

filterPredictions_allEB <- function(fdf,df_reg,real,pred) {
  compressors <- c()
  bs <- c()
  bc <- c()
  eb <- c()
  
  for (comp in unique(fdf$compressor)) {
    for (bsize in unique(fdf$blocksize)) {
      for (bcount in unique(fdf$blockcount)) {
      
        for (errbound in unique(fdf$errorbound)) {
          tmpdf <- fdf %>% filter(blocksize == bsize) %>% 
            filter(blockcount == bcount) %>%
            filter(compressor == comp) %>%
            filter(errorbound == errbound) 
          if(!nrow(tmpdf)) { next }
          compressors <- c(compressors, rep(comp, tmpdf$lengths))
          bs <- c(bs, rep(bsize, tmpdf$lengths))
          bc <- c(bc, rep(bcount, tmpdf$lengths))
          eb <- c(eb, rep(errbound, tmpdf$lengths))
        } 
      }
    }
  }
  pred_df <- as.data.frame(cbind(bs,bc,compressors,eb,real,pred))
  return (pred_df)
}

############################################################################################################################
getPredictionsVsReal_allEB <- function(fdf,app,samplemethod,model,oos=0,insmp=0) {
  realpath <- paste0('rawdata_analysis/real/', app, '_', samplemethod,'_',model)
  if(oos) { realpath <- paste0(realpath,'_outofsample')}
  if(insmp) { realpath <- paste0(realpath,'_insample')}
  realpath <- paste0(realpath,'_allEB_real.csv')
  real <- read_csv(realpath, col_names = FALSE,show_col_types = FALSE)
  
  predpath <- paste0('rawdata_analysis/pred/', app, '_', samplemethod,'_',model)
  if(oos) { predpath <- paste0(predpath,'_outofsample')}
  if(insmp) { predpath <- paste0(predpath,'_insample')}
  predpath <- paste0(predpath,'_allEB_pred.csv')
  pred <- read_csv(predpath, col_names = FALSE,show_col_types = FALSE)
  
  df_reg <- getDF_reg(app,samplemethod,model,oos,1,insmp)
  
  pred_df <- filterPredictions_allEB(fdf,df_reg,real,pred)
  pred_df <- cbind(rep(app,nrow(pred_df)),rep(samplemethod,nrow(pred_df)),rep(model,nrow(pred_df)) ,pred_df)
  colnames(pred_df) <- c("app","samplemethod","model", "blocksize","blockcount","compressor","errorbound","real","pred")
  return (pred_df)
}

############################################################################################################################
getPredictionsVsReal <- function(fdf,app,samplemethod,model,oos=0,insmp=0,alleb=0) {
  realpath <- paste0('rawdata_analysis/real/', app, '_', samplemethod,'_',model)
  if(oos) { realpath <- paste0(realpath,'_outofsample')}
  if(insmp) { realpath <- paste0(realpath,'_insample')}
  if(alleb) { realpath <- paste0(realpath,'_allEB')}
  realpath <- paste0(realpath,'_real.csv')
  real <- read_csv(realpath, col_names = FALSE,show_col_types = FALSE)
  
  predpath <- paste0('rawdata_analysis/pred/', app, '_', samplemethod,'_',model)
  if(oos) { predpath <- paste0(predpath,'_outofsample')}
  if(insmp) { predpath <- paste0(predpath,'_insample')}
  if(alleb) { predpath <- paste0(predpath,'_allEB')}
  predpath <- paste0(predpath,'_pred.csv')
  pred <- read_csv(predpath, col_names = FALSE,show_col_types = FALSE)
  
  pred_df <- filterPredictions(fdf,real,pred)
  pred_df <- cbind(rep(app,nrow(pred_df)),rep(samplemethod,nrow(pred_df)),rep(model,nrow(pred_df)) ,pred_df)
  colnames(pred_df) <- c("app","samplemethod","model", "blocksize","blockcount","compressor","errorbound","real","pred")
  return (pred_df)
}
############################################################################################################################


getPredictionsByFile <- function(preds,global) {
  #names(global)[names(global)=="globalCR"] <- "real"
  globalCRs <- global %>% filter(real < thresh)
  global$app <- NULL
  global$boundtype <- NULL
  if(preds$errorbound[1] == "all") { preds$errorbound <- NULL }
  
  merged <- merge(global,preds,by=c("compressor","real"))
  
  merged['field'] <- gsub('f[0-9]+.bin','',merged$filename)
  merged['timestep'] <- as.numeric(gsub('\\D','',merged$filename))
  
  merged <- merged[,c(5,3,11,12,6,7,8,9,1,4,2,10)]
  merged <- merged %>% arrange(field,blocksize,blockcount,compressor)
  merged <- merged[with(merged,order(compressor,field,timestep,blocksize,blockcount,errorbound)),]
  merged$filename <- NULL
  
  return (merged)
}

read_all_hurricane_by_field <- function(smpl) {
  fields <- c('CLOUD', 'Pf', 'PRECIP','QCLOUD', 'QGRAUP','QICE','QRAIN','QSNOW','QVAPOR','TC','U','V','W')
  
  combined_fdf <- c()
  
  for(field in fields) {
    appname <- paste0('hurricane_', field)
    combined_fdf <- rbind(combined_fdf, getFDF(appname,smpl,'flexmix',0,0))
  }
  
  return(combined_fdf)
}
#fdfpath <- paste0('rawdata_analysis/fdf/', app, '_', samplemethod,'_',model)
#getFDF <- function(app,samplemethod,model,oos=FALSE,allEB=FALSE) {



