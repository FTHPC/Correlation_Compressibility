


#### DO NOT USE ####
timingBoxplotByFileAndBS_forCompressor <- function(tdf,lflag=0) {
  des <- paste0(tdf$app[1],"_timing_boxplotByEB")
  if (lflag) {
    p <- ggplot(data=tdf,aes(x=as.factor(errorbound),y=log10(mape),fill=model)) +
      geom_boxplot(notch=TRUE) +
      ggh4x::facet_grid2(~compressor) +
      coord_flip() +
      labs(title=paste(tdf$app[1], tdf$samplemethod, "sampling"),x="Error Bound", y = "log(mape)")
    des <- paste0(des, "_log") 
    png(file=paste0(des, ".png"),width=100*length(unique(tdf$compressor)) + 100, height=150*length(unique(tdf$compressor)))
  } else {
    p <- ggplot(data=tdf,aes(x=as.factor(errorbound),y=mape,fill=model)) +
      geom_boxplot(notch=TRUE) +
      ggh4x::facet_grid2(~compressor) +
      coord_flip() +
      labs(title=paste(tdf$app[1], tdf$samplemethod, "sampling"),x="Error Bound", y = "mape")
    png(file=paste0(des, ".png"),width=100*length(unique(tdf$compressor)) + 100, height=150*length(unique(tdf$compressor)))
  }
  print(p)
  dev.off()
}





getTimingForCompressorAndEB_byFile <- function(tmdf,comp,eb,tm_conv=1e-6) {
  by_file <- tmdf %>% filter(compressor == comp) %>% filter(errorbound == eb) %>% group_by(filename)
  tm_local <- by_file %>% summarise("tm_global" = mean(globaltime)*tm_conv, 
                                    "stdv_global" = sd(globaltime)*tm_conv, 
                                    "tm_local" = mean(localtime)*tm_conv, 
                                    "stdv_local" = sd(localtime)*tm_conv)
  return(tm_local)
}

getTimingForCompressorsAndEB_byFile <- function(tmdf,tm_conv=1e-6) {
  tm_local <- c()
  for (comp in unique(tmdf$compressor)) {
    for (eb in unique(tmdf$errorbound)) {
      by_file <- tmdf %>% filter(compressor == comp) %>% filter(errorbound == eb) %>% group_by(filename)
      tmpdf <- by_file %>% summarise("comp" = comp, "error_bnd" = eb,
                                     "tm_global" = mean(globaltime)*tm_conv, "stdv_global" = sd(globaltime)*tm_conv, 
                                     "tm_local" = mean(localtime)*tm_conv, "stdv_local" = sd(localtime)*tm_conv)
      tm_local <- rbind (tm_local, tmpdf)
    }
  }
  formatC(tm_local$error_bnd, format='e', digits=0)
  return(tm_local)
}

getTimingForCompressorsAndBS_byFile <- function(tmdf,tm_conv=1e-6) {
  tm_local <- c()
  for (comp in unique(tmdf$compressor)) {
    for (bs in unique(tmdf$blocksize)) {
      by_file <- tmdf %>% filter(compressor == comp) %>% filter(blocksize == bs) %>% group_by(filename)
      tmpdf <- by_file %>% summarise("comp" = comp,
                                     "blocksize" = bs,
                                     "tm_global" = mean(globaltime)*tm_conv,
                                     "stdv_global" = sd(globaltime)*tm_conv,
                                     "min_global" = min(globaltime)*tm_conv,
                                     "max_global" = max(globaltime)*tm_conv,
                                     "cv_global" = (sd(globaltime)) / (mean(globaltime)) * 100, #coefficient of variation
                                     "range_global" = (max(globaltime) - min(globaltime))*tm_conv,
                                     "tm_local" = mean(localtime)*tm_conv,
                                     "stdv_local" = sd(localtime)*tm_conv,
                                     "min_local" = min(localtime)*tm_conv,
                                     "max_local" = max(localtime)*tm_conv,
                                     "cv_local" = (sd(localtime)) / (mean(localtime)) * 100,
                                     "range_local" = (max(localtime) - min(localtime))*tm_conv)
      tm_local <- rbind (tm_local, tmpdf)
    }
  }
  #formatC(tm_local$error_bnd, format='e', digits=0)
  return(tm_local)
}




aggregateTiming <- function(tdf) {
  allCompTiming <- getTimingForCompressors(tdf)
  #print(allCompTiming)
  compTimingsByFile <- c()
  l = 1
  for (comp in unique(tdf$compressor)) {
    #print(comp)
    compTimingsByFile[[l]] <- getTimingForCompressor_byFile(tdf,comp)
    l = l+1
  }
  byFileCompBS <- getTimingForCompressorsAndBS_byFile(tdf)
  return(list(allCompTiming = allCompTiming, compTimingsByFile = compTimingsByFile, byFileCompBS = byFileCompBS))
}








getTimingHistogramByCompErrbndBlkSize_allFiles <- function(tdf,comp,eb,bs,tm_conv=1e-06) {
  tmpdf <- tdf %>% filter(compressor == comp) %>% 
    filter(errorbound == eb) %>% 
    filter(blocksize == bs)
  return(ggplot(tmpdf, aes(x=localtime*1e-06, fill = as.factor(filename))) +
           geom_histogram(color='#e9ecef',alpha=0.65, position='identity') +
           labs(title=paste0(comp, ", bs=", bs, ", eb=", eb),
                x="Sample Time (ms)",
                color="File"))
}

getTimingHistogramByCompBlkSize_allFiles <- function(tdf,comp,bs,tm_conv=1e-06) {
  tmpdf <- tdf %>% filter(compressor == comp) %>% 
    filter(blocksize == bs)
  return(ggplot(tmpdf, aes(x=localtime*1e-06, fill = as.factor(filename))) +
           geom_histogram(color='#e9ecef',alpha=0.65, position='identity') +
           labs(title=paste0(comp, ", bs=", bs),
                x="Sample Time (ms)",
                color="File"))
}


getTimingHistogramByCompFileErrbndBlkSize <- function(tdf,comp,file,eb,bs,tm_conv=1e-06) {
  tmpdf <- tdf %>% filter(compressor == comp) %>% 
    filter(filename == file) %>% 
    filter(errorbound == eb) %>% 
    filter(blocksize == bs)
  histName <- paste0(comp, ", ", file, ", ", "bs=", bs, ", eb=", eb)
  return (hist((tmpdf$localtime)*1e-06,
               main=histName,
               xlab="Sample Time (ms)"
  ))
}

timingBoxPlotByFile <- function(tdf,comp,eb) {
  ebs <- unique(tdf$errorbound)
  comps <- unique(tdf$compressor)
  tmpdf <- tdf %>% filter(compressor == comp) %>% filter(errorbound == eb)
  
  #tmpdf$blocksize <- lapply(tmpdf$blocksize, as.character)
  
  ggplot(tmpdf, aes(x = blocksize, y = localtime*1e-6)) +
    geom_point() +
    #scale_x_discrete() +
    facet_wrap(~ filename)
  
  
}


runTimingHist <- function(tdf) {
  for (file in unique(tdf$filename)) {
    h <- getTimingHistogramByCompFileErrbndBlkSize(tdf, "sz","velocityz.d64",1e-04,32)
  }
  
  for (comp in unique(tdf$compressor)) {
    for (bs in unique(tdf$blocksize)) {
      h <- getTimingHistogramByCompBlkSize_allFiles(tdf, comp,bs)
      print(h)
    }
  }
  
  for (comp in unique(tdf$compressor)) {
    for (eb in unique(tdf$errorbound)) {
      h <- getTimingHistogramByCompErrbndBlkSize_allFiles(tdf, comp, eb, bs)  
      print(h)
    }
  }
}


getSpeedupBarByCompErrbndBlkSize_allFiles <- function(tdf,comp,eb,bs,tm_conv=1e-06) {
  tmpdf <- tdf %>% filter(compressor == comp) %>% 
    filter(errorbound == eb) %>% 
    filter(blocksize == bs)
  
  speedup <- (tmpdf$globaltime / tmpdf$localtime) * tm_conv
  files <- unique(tmpdf$filename)
  
  #NEED TO SUMMARIZE BY FILE
  by_file <- tdf %>% filter(compressor == comp) %>% filter(errorbound == eb) %>% 
    filter(blocksize == bs) %>% group_by(filename)
  tmpdf <- by_file %>% summarise("comp" = comp, "error_bnd" = eb,
                                 "tm_global" = mean(globaltime)*tm_conv, "stdv_global" = sd(globaltime)*tm_conv, 
                                 "tm_local" = mean(localtime)*tm_conv, "stdv_local" = sd(localtime)*tm_conv)
  tm_local <- rbind (tm_local, tmpdf)
  
  ggplot(data=tmpdf, aes(x=files,y=speedup)) + geom_bar(stat="identity")
  
  return(ggplot(tmpdf, aes(x=files,y=speedup)) +
           geom_bar(stat="identity"))
  
  #return(ggplot(tmpdf, aes(x=localtime*1e-06, fill = as.factor(filename))) +
  #         geom_histogram(color='#e9ecef',alpha=0.65, position='identity') +
  #         labs(title=paste0(comp, ", bs=", bs, ", eb=", eb),
  #              x="Sample Time (ms)",
  #              color="File"))
}

getSpeedupHistogramByCompFileErrbndBlkSize <- function(tdf,comp,file,eb,bs,tm_conv=1e-06) {
  tmpdf <- tdf %>% filter(compressor == comp) %>% 
    filter(filename == file) %>% 
    filter(errorbound == eb) %>% 
    filter(blocksize == bs)
  histName <- paste0(comp, ", ", file, ", ", "bs=", bs, ", eb=", eb)
  return (hist((tmpdf$localtime)*1e-06,
               main=histName,
               xlab="Sample Time (ms)"
  ))
}

runSpeedupHist <- function(tdf) {
  for (file in unique(tdf$filename)) {
    h <- getSpeedupHistogramByCompFileErrbndBlkSize(tdf, "sz",file,1e-05,16)
  }
  for (comp in unique(tdf$compressor)) {
    h <- getTimingHistogramByCompErrbndBlkSize_allFiles(tdf, comp, 1e-05, bs)  
    print(h)
  }
}
