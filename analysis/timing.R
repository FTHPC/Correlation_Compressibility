#set.seed(1234)
#putting this in a function so I can source the file
misc <- function(){
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
}

run <- function() {
  timing16 <- read_data_timing("SCALE",16)
  timing20 <- read_data_timing("SCALE",20)
  timing24 <- read_data_timing("SCALE",24)
  timing28 <- read_data_timing("SCALE",28)
  timing32 <- read_data_timing("SCALE",32)
}

### read data
read_data_timing <-function(app, blocksize){
  name <- paste0("outputs/*",app,"*blocks128", "_block_size", blocksize, ".csv")
  #print(name)
  filenames <- Sys.glob(name)
  
  tdf <- c()
  for (filename in filenames) {
    #print(filename)
    data <- read.csv(filename)
    data <- as.data.frame(data)
    #
    tdf <- rbind(tdf,data)
  }
  
  tdf <- as.data.frame(tdf)
  tdf <- tdf[c("info.filename", "info.compressor", "info.error_bound", "block.dim1",
                 "global.compression_ratio", "global.time_compress", "block.total_count",
                 "block.number", "size.compression_ratio", "nanotime.compress")]
  apps <-rep(app,nrow(tdf))
  tdf <- cbind(apps,tdf)
  names(tdf)[names(tdf) == 'info.compressor'] <- 'compressor'
  names(tdf)[names(tdf) == 'info.filename'] <- 'filename'
  names(tdf)[names(tdf) == 'block.total_count'] <- 'totalblocks'
  names(tdf)[names(tdf) == 'block.number'] <- 'blocknum'
  names(tdf)[names(tdf) == 'block.dim1'] <- 'blocksize'
  names(tdf)[names(tdf) == 'info.error_bound'] <- 'errorbound'
  names(tdf)[names(tdf) == 'global.compression_ratio'] <- 'cr_global'
  names(tdf)[names(tdf) == 'global.time_compress'] <- 'globaltime'
  names(tdf)[names(tdf) == 'nanotime.compress'] <- 'localtime'
  names(tdf)[names(tdf) == 'size.compression_ratio'] <- 'cr_local'

  tdf$blocksize <- as.numeric(tdf$blocksize)
  tdf$errorbound <- as.numeric(tdf$errorbound)
  tdf$cr_global <- as.numeric(tdf$cr_global)
  tdf$globaltime <- as.numeric(tdf$globaltime)
  tdf$localtime <- as.numeric(tdf$localtime)
  tdf$cr_local <- as.numeric(tdf$cr_local)
  tdf$blocknum <- as.numeric(tdf$blocknum)
  tdf$totalblocks <- as.numeric(tdf$totalblocks)
  tdf$filename <- sub("\\-.*","",tdf$filename)
  
  tdf <- cbind(rep(app, nrow(tdf)),tdf)
  
  return(tdf)
}

getData <-function(app,blocksizes) {
  tdf <- c()
  for (bs in blocksizes) {
    tdf <- rbind(tdf, read_data_timing(app, bs))
  }
  tdf <- tdf[complete.cases(tdf), ]
  return(tdf)
}


read_data_timing_compressor <-function(app, comp, blocksize){
  name <- paste0("outputs/*",app, "_", comp,"_blocks128", "_block_size", blocksize, ".csv")
  #print(name)
  filenames <- Sys.glob(name)
  
  tdf <- c()
  for (filename in filenames) {
    print(filename)
    data <- read.csv(filename)
    data <- as.data.frame(data)
    #
    tdf <- rbind(tdf,data)
  }
  
  tdf <- as.data.frame(tdf)
  #print(head(tdf))
  tdf <- tdf[c("info.filename", "info.compressor", "info.error_bound", "block.dim1",
               "global.compression_ratio", "global.time_compress", "block.total_count",
               "block.number", "size.compression_ratio", "nanotime.compress")]
  apps <-rep(app,nrow(tdf))
  tdf <- cbind(apps,tdf)
  names(tdf)[names(tdf) == 'info.compressor'] <- 'compressor'
  names(tdf)[names(tdf) == 'info.filename'] <- 'filename'
  names(tdf)[names(tdf) == 'block.total_count'] <- 'totalblocks'
  names(tdf)[names(tdf) == 'block.number'] <- 'blocknum'
  names(tdf)[names(tdf) == 'block.dim1'] <- 'blocksize'
  names(tdf)[names(tdf) == 'info.error_bound'] <- 'errorbound'
  names(tdf)[names(tdf) == 'global.compression_ratio'] <- 'cr_global'
  names(tdf)[names(tdf) == 'global.time_compress'] <- 'globaltime'
  names(tdf)[names(tdf) == 'nanotime.compress'] <- 'localtime'
  names(tdf)[names(tdf) == 'size.compression_ratio'] <- 'cr_local'
  
  tdf$blocksize <- as.numeric(tdf$blocksize)
  tdf$errorbound <- as.numeric(tdf$errorbound)
  tdf$cr_global <- as.numeric(tdf$cr_global)
  tdf$globaltime <- as.numeric(tdf$globaltime)
  tdf$localtime <- as.numeric(tdf$localtime)
  tdf$cr_local <- as.numeric(tdf$cr_local)
  tdf$blocknum <- as.numeric(tdf$blocknum)
  tdf$totalblocks <- as.numeric(tdf$totalblocks)
  tdf$filename <- sub("\\-.*","",tdf$filename)
  
  tdf <- cbind(rep(app, nrow(tdf)),tdf)
  
  return(tdf)
}

getDataForCompressor <-function(app,comp,blocksizes) {
  tdf <- c()
  for (bs in blocksizes) {
    tdf <- rbind(tdf, read_data_timing_compressor(app, comp, bs))
  }
  tdf <- tdf[complete.cases(tdf), ]
  return(tdf)
}



getTimingForCompressors <- function(tdf,tm_conv=1e-6) {
  tm_conv <- 1e-6
  tm_local <- tdf %>% group_by(compressor) %>% 
                      dplyr::summarise("global" = mean(globaltime)*tm_conv,
                                "stdv_global" = sd(globaltime)*tm_conv,
                                "local" = mean(localtime)*tm_conv,
                                "stdv_local" = sd(localtime)*tm_conv)
  return(tm_local)
}

getTimingForCompressorAndEB <- function(tdf, eb, comp,tm_conv=1e-6) {
  tm_comp <- tdf %>% filter(errorbound == eb) %>% filter(compressor == comp)
  tm_local <- mean(tm_comp$localtime) * tm_conv
  return(tm_local)
}

getTimingForCompressor_byEB <- function(tdf,comp,tm_conv=1e-6) {
  by_eb <- tdf %>% filter(compressor == comp) %>% group_by(errorbound)
  formatC(by_eb$errorbound, format='e', digits=0)
  tm_local <- by_eb %>% dplyr::summarise("tm_global" = mean(globaltime)*tm_conv, 
                                  "stdv_global" = sd(globaltime)*tm_conv, 
                                  "tm_local" = mean(localtime)*tm_conv, 
                                  "stdv_local" = sd(localtime)*tm_conv)
  return(tm_local)
}

getTimingForCompressor_byBS <- function(tdf,comp,tm_conv=1e-6) {
  by_bs <- tdf %>% filter(compressor == comp) %>% group_by(blocksize)
  tm_local <- by_bs %>% dplyr::summarise("tm_global" = mean(globaltime)*tm_conv, 
                                         "stdv_global" = sd(globaltime)*tm_conv,
                                         "med_global" = median(globaltime)*tm_conv,
                                         "min_global" = min(globaltime)*tm_conv,
                                         "max_global" = max(globaltime)*tm_conv,
                                         "local" = mean(localtime)*tm_conv,
                                         "stdv_local" = sd(localtime)*tm_conv,
                                         "med_local" = median(localtime)*tm_conv,
                                         "med_global" = median(localtime)*tm_conv,
                                         "min_local" = min(localtime)*tm_conv,
                                         "max_local" = max(localtime)*tm_conv)
  return(tm_local)
}

getTimingByBlockSizeForCompressor <- function(tdf) {
  for (comp in unique(tdf$compressor)) {
    print(knitr::kable(getTimingForCompressor_byBS(tdf,comp), format = "markdown"))
    print(comp)
  }
}

getTimingForCompressor_byBSEB <- function(tdf,comp,tm_conv=1e-6) {
  by_bs <- tdf %>% filter(compressor == comp) %>% group_by(blocksize,errorbound)
  tm_local <- by_bs %>% dplyr::summarise("tm_global" = mean(globaltime)*tm_conv, 
                                         "stdv_global" = sd(globaltime)*tm_conv, 
                                         "tm_local" = mean(localtime)*tm_conv, 
                                         "stdv_local" = sd(localtime)*tm_conv)
  return(tm_local)
}

getTimingByBlockSizeAndEBForCompressor <- function(tdf) {
  for (comp in unique(tdf$compressor)) {
    print(knitr::kable(getTimingForCompressor_byBSEB(tdf,comp), format = "markdown"))
    print(comp)
  }
}

saveTimng <- function(tdf) {
  fwrite(tdf, paste0(getwd(),"/rawdata_analysis/timing/",var_nm,"_tdf.csv"))
}

getTimingForCompressor_byFileAndBS <- function(tdf,comp,tm_conv=1e-6) {
  by_file <- tdf %>% filter(compressor == comp) %>% group_by(filename,blocksize)
  tm_local <- by_file %>% dplyr::summarise("avg_global" = mean(globaltime)*tm_conv, 
                                    "stdv_global" = sd(globaltime)*tm_conv,
                                    "min_global" = min(globaltime)*tm_conv,
                                    "max_global" = max(globaltime)*tm_conv,
                                    "median_global" = median(globaltime)*tm_conv,
                                    "avg_local" = mean(localtime)*tm_conv, 
                                    "stdv_local" = sd(localtime)*tm_conv,                                    
                                    "min_local" = min(localtime)*tm_conv,
                                    "max_local" = max(localtime)*tm_conv,
                                    "median_local" = median(localtime)*tm_conv)
  return(tm_local)
}

getTimingByFileAndBlocksizeForCompressor <- function(tdf) {
  for (comp in unique(tdf$compressor)) {
    print(knitr::kable(getTimingForCompressor_byFileAndBS(tdf,comp),format="markdown"))
    print(comp)
  }
}

getTimingForCompressor_byFile <- function(tdf,comp,tm_conv=1e-6) {
  by_file <- tdf %>% filter(compressor == comp) %>% group_by(filename)
  tm_local <- by_file %>% dplyr::summarise("avg_global" = mean(globaltime)*tm_conv, 
                                           "stdv_global" = sd(globaltime)*tm_conv,
                                           "median_global" = median(globaltime)*tm_conv,
                                           "min_global" = min(globaltime)*tm_conv,
                                           "max_global" = max(globaltime)*tm_conv,
                                           "avg_local" = mean(localtime)*tm_conv, 
                                           "stdv_local" = sd(localtime)*tm_conv,                                    
                                           "median_local" = median(localtime)*tm_conv,
                                           "min_local" = min(localtime)*tm_conv,
                                           "max_local" = max(localtime)*tm_conv)
                                           
  return(tm_local)
}

getTimingByFileAndCompressor <- function(tdf) {
  for (comp in unique(tdf$compressor)) {
    print(knitr::kable(getTimingForCompressor_byFile(tdf,comp),format="markdown"))
    print(comp)
  }
}

timingHistogramByBSAndComp_forFileAndLocation <- function(tdf,bs) {
  tmpdf <- tdf %>% filter(blocksize == 32)
  ggplot(tmpdf,aes(x=blocknum,y=cr_local)) + geom_bar(stat="identity")
}



timingBoxplotBSAndComp_forFile <- function(app,tdf,ylim=0) {
  des <- paste0('img/timing/',app,"_timing_boxplotByBS")

  if (ylim) {
    p <- ggplot(data=tdf,aes(x=as.factor(filename),y=(localtime*1e-6),color=blocksize)) +
      geom_boxplot(notch=FALSE) +
      ggh4x::facet_grid2(vars(compressor),vars(blocksize),scales="free_y")+
      theme(legend.position = "none") +
      lims(y=c(0,ylim)) +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) +
      labs(title=paste(app, "sampling timing"),x="Block Size", y = "Time (ms)")
    des <- paste0(des, "_ylim")
    png(file=paste0(des, ".png"),width=200*length(unique(tdf$blocksize)) + 200, height=200*length(unique(tdf$compressor)) + 800,res=200)
  } else {
    p <- ggplot(data=tdf,aes(x=as.factor(filename),y=(localtime*1e-6),color=blocksize)) +
      geom_boxplot(notch=FALSE) +
      ggh4x::facet_grid2(vars(compressor),vars(blocksize),scales="free_y")+
      theme(legend.position = "none") +
      theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust=1)) +
      labs(title=paste(app, "sampling timing"),x="Block Size", y = "Time (ms)")
    png(file=paste0(des, ".png"),width=200*length(unique(tdf$blocksize)) + 200, height=200*length(unique(tdf$compressor)) + 800,res=200)
  }
  print(p)
  dev.off()
}

library("ggpubr")
timingBarplotByComp <- function(tdf,comp,ylim=0) {
 
  b_sizes <- c(16,24,32)
  b_counts <- c(16,64,80,128)

  global <- tdf %>% filter(compressor == comp) %>% 
    dplyr::summarise(
      "sdlocal" = sd(globaltime) * 1e-6,
      "localtime" = mean(globaltime) * 1e-6)
  global <- as.data.frame(cbind("global",global,"running the compressor",comp))
  colnames(global) <- c("blocksize","sdlocal","localtime","blockcount","compressor")
  
  timing <- tdf %>% filter(compressor == comp) %>% 
    filter(blocksize %in% b_sizes) %>%
    group_by(blocksize) %>%
    dplyr::summarise(
      "sdlocal" = var(localtime),
      "localtime" = mean(localtime)
    )
  timing <- as.data.frame(timing[rep(seq_len(nrow(timing)), each=length(b_counts)),])
  timing$blockcount <- rep(b_counts, length(b_sizes))
  timing$localtime <- as.numeric((timing$localtime * timing$blockcount) * 1e-6)
  timing$sdlocal <- as.numeric(sqrt(timing$sdlocal * timing$blockcount) * 1e-6)
  timing$compressor <- comp
  timing <- rbind(timing,global)
  timing$blocksize <- factor(timing$blocksize, levels=unique(timing$blocksize))
  
  timing$localtime <- round(timing$localtime,digits=2)
  timing$sdlocal <- round(timing$sdlocal,digits=2)
  
  print(timing)
  
  if (ylim) {
    p <- ggbarplot(timing, x = "blockcount", y = "localtime", fill = "blocksize",
                   #palette = "npg",
                   #palette = "aaas",
                   palette = "ucsgb",
                   short.panel.labs=FALSE,
                   panel.labs = list(blocksize=c("bs=16","bs=24","bs=32","global")),
                   ylab="Compression time (ms)",
                   xlab="Block count",
                   label=paste(timing$localtime, "\n±", timing$sdlocal),
                   lab.vjust=-.5,
                   lab.size=2.5,
                   title=paste(comp,"Block Sampling Compression Time")
                   ) +
      geom_errorbar(aes(group = blocksize, ymax = localtime+sdlocal, ymin = localtime-sdlocal),width=0.25)
    p <- facet(p + theme_bw(),facet.by="blocksize",nrow=1,scales="free_x")
    p <- ggpar(p, ylim=c(0,ylim))

    des <- paste0('img/timing/',app,"_",comp, "_timing_barplot_ylim.png")
    png(file=paste0(des, ".png"),width=200*length(unique(timing$blocksize)) + 200, height=200 + 800,res=200)
  } else {
    p <- ggbarplot(timing, x = "blockcount", y = "localtime", fill = "blocksize",   
                   palette = "ucsgb",
                   short.panel.labs=FALSE,
                   panel.labs = list(blocksize=c("bs=16","bs=24","bs=32","global")),
                   ylab="Compression time (ms)",
                   xlab="Block count",
                   #label=paste(timing$localtime, "\n±", timing$sdlocal),
                   label=paste(timing$localtime),
                   lab.size=2.5,
                   lab.vjust=-.5,
                   title=paste(comp,"Block Sampling Compression Time")
                   ) #+
      #geom_errorbar(aes(group = blocksize, ymax = localtime+sdlocal, ymin = localtime-sdlocal),width=0.25)
    p <- facet(p + theme_bw(),facet.by="blocksize",nrow=1,scales="free_x")

    des <- paste0('img/timing/',app,"_",comp, "_timing_barplot.png")
    png(file=des,width=350*length(unique(tdf$blocksize)) + 250, height=750 ,res=200)
  }
  print(p)
  dev.off()
}

runTimingBarplotByComp <- function(tdf) {
  for (comp in unique(tdf$compressor)) {
    timingBarplotByComp(tdf,comp)
  }
}

timingBarplotByCompWithAccuracy <- function(tdf,fdf,comp,app,ylim=0) {
  #b_sizes <- c(16,24,32)
  b_sizes <- c(16,32)
  b_counts <- c(16,64,80,128)
  
  global <- tdf %>% filter(compressor == comp) %>% 
    dplyr::summarise(
      "sdlocal" = sd(globaltime) * 1e-6,
      "localtime" = mean(globaltime) * 1e-6)
  global <- as.data.frame(cbind("All",global,"running the compressor",comp,"N/A"))
  colnames(global) <- c("blocksize","sdlocal","localtime","blockcount","compressor","mape")
  global <- global[,c(1,4,2,3,5,6)]
  
  timing <- tdf %>% filter(compressor == comp) %>% 
    filter(blocksize %in% b_sizes) %>%
    group_by(blocksize) %>%
    dplyr::summarise(
      "sdlocal" = var(localtime),
      "localtime" = mean(localtime)
    )
  accuracy <- fdf %>% filter(compressor == comp) %>% 
    filter(blocksize %in% b_sizes) %>%
    filter(blockcount %in% b_counts) %>%
    dplyr::select("blocksize","blockcount","mape")
  accuracy$mape <- round(accuracy$mape, digits=2)
  
  timing <- as.data.frame(timing[rep(seq_len(nrow(timing)), each=length(b_counts)),])
  timing$blockcount <- rep(b_counts, length(b_sizes))
  timing$localtime <- as.numeric((timing$localtime * timing$blockcount) * 1e-6)
  timing$sdlocal <- as.numeric(sqrt(timing$sdlocal * timing$blockcount) * 1e-6)
  timing$compressor <- comp
  timing$blocksize <- factor(timing$blocksize, levels=unique(timing$blocksize))
  timing$localtime <- round(timing$localtime,digits=2)
  timing$sdlocal <- round(timing$sdlocal,digits=2)
  timing <- merge(x=timing,y=accuracy,by=c('blocksize','blockcount'))
  timing$blocksize <- factor(timing$blocksize, levels=unique(timing$blocksize))
  timing <- timing[order(timing$blocksize,timing$blockcount),]
  timing$blocksize <- paste0("block size = ",timing$blocksize)
  
  #timing <- rbind(timing,global)
  timing$localtime <- round(timing$localtime,digits=1)
  timing$sdlocal <- round(timing$sdlocal,digits=1)
  
  p <- ggbarplot(timing, x = "blockcount", y = "localtime", #fill = "blocksize",   
                 palette = "ucsgb",
                 #short.panel.labs=TRUE,
                 #panel.labs = list(blocksize=c("block sisze=16","24","32")),
                 ylab="Compression time (ms)",
                 xlab="Block count"
                 #label=paste(timing$localtime, "ms /\n", timing$mape),
                 #lab.size=2.5,
                 #lab.vjust=-.25,
                 #lab.angle=90,
                 #title=paste("SPERR Block Sampling Compression Time")
  ) #+
    #geom_text(position = position_dodge(width= 9), aes(y=timing$localtime+0.25, fill=blocksize, label=timing$localtime, hjust=0), angle=90)
    #geom_errorbar(aes(group = blocksize, ymax = localtime+sdlocal, ymin = localtime-sdlocal),width=0.25)
  p <- p + geom_hline(yintercept=global$localtime) #+ geom_text(aes(0,global$localtime,label = "", vjust = -.75, hjust=-.5))
  p <- facet(p + theme_bw(),facet.by="blocksize",nrow=1,scales="free_x")
  p <- ggpar(p, ylim=c(0,5250))
  
  des <- paste0('img/timing/',app,"_",comp, "_timing_barplot.pdf")
  pdf(des,
      height=2.25,
      width=4.0)
  print(p)
  dev.off()
}

runTimingBarplotByCompWithAccuracy <- function(tdf,fdf) {
  for (comp in unique(tdf$compressor)) {
    timingBarplotByCompWithAccuracy(tdf,fdf,comp)
  }
}







