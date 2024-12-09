
#options(scipen=999) #turn off scientific notation
#options(scipen=0) #force scientific notation
#options(scipen=50,digits=4)
#options(scipen=0,digits=7)

#//TODO write test to see when global CR gets
# too high such that it starts impacting
# prediction rates



################################################
################################################
getAccuracyByApp_ByCompressor_fixedBlockSize <- function(fdf, block_size) {
  fdf <- as.data.frame(fdf)
  fdf_block <- fdf %>% filter(blocksize == block_size) %>%
                       group_by(compressor) %>% 
                       dplyr::summarise(medape = mean(mape), 
                                        stdv = sd(mape), 
                                        range = mean(quartilerange), 
                                        lowerr = mean(lowererr), 
                                        uperr = mean(uppererr))
  return(fdf_block)
}
getAccuracyByApp_ByBlockSize <- function(fdf) {
  for (bs in unique(fdf$blocksize)) {
    tmpdf <- fdf %>% filter(samplemethod == samplemethod) %>%
                     filter(model == model)
    res <- getAccuracyByCompressor_fixedBlockSize(tmpdf,bs)
    print(bs)
    print(knitr::kable(res, format="markdown"))
  }
}

#aggregate accuracy by compressor across a fixed column
getAccuracyByCompressor_fixed <- function(fdf, colname, value) {
  fdf_block <- fdf %>% filter(colname == value) %>%
                       group_by(compressor) %>% 
                       dplyr::summarise(medape = mean(mape), 
                                        stdv = sd(mape), 
                                        range = mean(quartilerange), 
                                        lowerr = mean(lowererr), 
                                        uperr = mean(uppererr))
  return(fdf_block)
}

#aggregate accuracy by compressor across a fixed block size
getAccuracyByCompressor_fixedBlockSize <- function(fdf, block_size) {
  fdf_block <- fdf %>% filter(blocksize == block_size) %>%
                       group_by(compressor) %>% 
                       dplyr::summarise(medape = mean(mape), 
                                        stdv = sd(mape), 
                                        range = mean(quartilerange), 
                                        lowerr = mean(lowererr), 
                                        uperr = mean(uppererr))
  return(fdf_block)
}
getAccuracyByBlockSize <- function(fdf) {
  for (bs in unique(fdf$blocksize)) {
    res <- getAccuracyByCompressor_fixedBlockSize(fdf,bs)
    print(knitr::kable(res,format="markdown"))
    print(bs)
  }
}

getAccuracyByCompressor_fixedBlockCount <- function(fdf, block_count) {
  fdf_block <- fdf %>% filter(blockcount == block_count) %>%
                       group_by(compressor) %>% 
                       dplyr::summarise(medape = mean(mape), 
                                        stdv = sd(mape), 
                                        range = mean(quartilerange), 
                                        lowerr = mean(lowererr), 
                                        uperr = mean(uppererr))
  return(fdf_block)
}
getAccuracyByBlockCount <- function(fdf) {
  for (bc in unique(fdf$blockcount)) {
    res <- getAccuracyByCompressor_fixedBlockCount(fdf,bc)
    print(knitr::kable(res,format="markdown"))
    print(bc)
  }
}

getBestConfigsForCompressor <- function(fdf,comp,n=5) {
  tmpdf <- fdf %>% filter(compressor == comp)
  tmpdf <- tmpdf[order(tmpdf$avg_mape),]
  best_bs <- tmpdf$blocksize[1:n]
  best_bc <- tmpdf$blockcount[1:n]
  mapes <- tmpdf$avg_mape[1:n]
  med_mapes <- tmpdf$med_mape[1:n]
  quartilerange <- tmpdf$qrange[1:n]
  
  best_config <- as.data.frame(cbind(rep(comp,n),best_bs,best_bc,mapes,med_mapes,quartilerange))
  colnames(best_config) <- c("compressor","blocksize","blockcount","average mape","median mape","median quantilerange")
  return(best_config)
}
runGetBestConfigsForCompressor <- function(fdf,n) {
  tmpdf <- data.frame()
  for (comp in unique(fdf$compressor)) {
    tmpdf <- getBestConfigsForCompressor(fdf,comp,n)
    print(knitr::kable(tmpdf,format="markdown"))
  }
}
runGetBestConfigsForCompressor_allApps <- function(n=5) {
  tmpdf <- getFDF_allApps('qmcpack')
  tmpdf <- tmpdf %>% filter(model == 'flexmix') %>% filter(compressor != bit_grooming)
  fdf <- tmpdf %>% group_by(blocksize,blockcount,compressor) %>%
                 dplyr::summarise("avg_mape" = mean(mape),
                                  "med_mape" = median(mape),
                                  "qrange" = median(quartilerange))
  runGetBestConfigsForCompressor(fdf,n)
}


filterFDF <- function(fdf,blocksizes,blockcounts) {
  newfdf <- fdf
  
  tmprow <- fdf[1,]
  tmprow$mape <- NA
  tmprow$avgAPE <- NA
  tmprow$lowerror <- NA
  tmprow$upperror <- NA
  tmprow$quantilerange <- NA
  for(comp in unique(fdf$compressor)) {
    for(field in unique(fdf$field)) {
      for(eb in unique(fdf$errorbound)) {
        print(paste(field,eb))
        for(bs in blocksizes) {
          for(bc in blockcounts) {
            if(nrow(fdf %>% filter(compressor == comp) %>% filter(field==field) %>% 
                    filter(errorbound==eb) %>% filter(blocksize==bs) %>% filter(blockcount==bc))) {
              tmprow$compressor <- comp
              tmprow$field <- field
              tmprow$blocksize <- bs
              tmprow$blockcount <- bc
              tmprow$errorbound <- eb
              newfdf <- rbind(newfdf,tmprow)
  } } } } } }
  return (newfdf)
}

recalculateMapeAllPreds <- function(fdf) {
  new_df <- fdf %>% 
    group_by(app,field,blocksize,blockcount,compressor,errorbound,samplemethod,model) %>% 
    mutate("relErr" = abs(real-pred)/real) %>%
    dplyr::summarise("mape" = median(relErr)*100,
                     "avgAPE" = mean(relErr)*100,
                     "lowerror" = quantile(relErr,prob=0.10)*100,
                     "upperror" = quantile(relErr,prob=0.9)*100,
                     "quantilerange" = upperror - lowerror
    )
  
  return(as.data.frame(new_df))
}


