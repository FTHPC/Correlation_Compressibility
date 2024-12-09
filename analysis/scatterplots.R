#
suppressPackageStartupMessages({
  library('plyr') #this needs to go before dplyr
  library('dplyr')
  library('fields')
  library('pals')
  library('viridis')
  library('reshape2')
  library('tidyverse')
  library('stringr')
  library('gtools')
  library('gridExtra')
  library('RColorBrewer')
  library('ggpubr')
  library('ggh4x')
  library('patchwork')
  library('plotly')
  library('ggeffects')
  library('grid')
})


################################################
################################################
makeRealVsPredScatterplots_singleConfig <- function(pred_df,bs,eb) {
  tmpdf <- pred_df %>% filter(blocksize == bs) %>% filter(errorbound == eb)
  ggplot(tmpdf,aes(x=log(real),y=log(pred))) +
    geom_point(alpha=0.5) +
    facet_grid2(vars(compressor), vars(blocksize), 
                scales = "free", independent = "y", space = "free_x") +
    ggtitle(paste(pred_df$app[1], pred_df$samplemethod[1],pred_df$model[1]), 'block size',bs,eb) +
    geom_abline(slope=1)
  
  #dev.off()
}

makeRealVsPredScatterplots_byBCBS_CompressorandField <- function(pred_df,compressor,ylim=0,allEB=0,log=0) {
  if (pred_df$samplemethod[1] == "uniform") {sampling <- "random"} 
  else {sampling <- "uniform"}
  
  dir <- paste0('img/scatter/',pred_df$app[1], '_',pred_df$samplemethod[1],'_',pred_df$model[1])
  title <- paste(pred_df$app[1], compressor, pred_df$model[1], 'regression modeling with', sampling,'sampling')
  
  if(allEB) { dir <- paste0(dir,"_allEB"); title <- paste(title,'with error bounds as parameter') }
  if(log) {
    pred_df$real <- log(pred_df$real)
    pred_df$pred <- log(pred_df$pred)
    title <- paste0(title, ', log of real vs pred')
    dir <- paste0(dir,'_log')
  }
  if(ylim) { dir <- paste0(dir,"_ylim") }
  dir <- paste0(dir, '_', compressor, "_bcbs_byfield_scatter.png")
  #pdf(file=dir)
  
  if (ylim) {
    plt <- ggplot(pred_df,aes(x=real,y=pred)) +
      geom_point(aes(color=as.factor(formatC(errorbound,format='e',digits=0)),shape=as.factor(field)),alpha=0.75) +
      scale_shape_manual(values=seq(0,length(unique(pred_df$field)))) +
      facet_grid2(vars(blocksize), vars(blockcount), scales = "free_y") +
      ggtitle(title) +
      lims(y=c(0,ylim)) +
      labs(color="Error bound",shape="Field") +
      geom_abline(slope=1) +
      theme(plot.title = element_text(size=15)) +
      theme(axis.title = element_text(size=10),strip.text.y =element_text(size=5)) +
      theme(axis.text.x = element_text(size=5),axis.text.y = element_text(size=5)) +
      theme(legend.title=element_text(size=8),legend.text=element_text(size=5))
    png(file=dir, width=5000,height=1650,res=300)
  } else {
    plt <- ggplot(pred_df,aes(x=real,y=pred)) +
      geom_point(aes(color=as.factor(formatC(errorbound,format='e',digits=0)),shape=as.factor(field)),alpha=0.75) +
      scale_shape_manual(values=seq(0,length(unique(pred_df$field)))) +
      facet_grid2(vars(blocksize), vars(blockcount), scales = "free_y") +
      ggtitle(title) +
      labs(color="Error bound",shape="Field") +
      geom_abline(slope=1) +
      theme(plot.title = element_text(size=15)) +
      theme(axis.title = element_text(size=10),strip.text.y =element_text(size=5)) +
      theme(axis.text.x = element_text(size=5),axis.text.y = element_text(size=5)) +
      theme(legend.title=element_text(size=8),legend.text=element_text(size=5))
    png(file=dir,width=5000,height=1650,res=300)
  }
  
  #ggsave(dir,dpi=320)
  print(plt)
  dev.off()
}

run_makeRealVsPredScatterplots_byBCBS_CompressorandField <- function(pred_df,ylim=0,allEB=0,log=0) {
  for (comp in unique(pred_df$compressor)) {
    tmpdf <- pred_df %>% filter(compressor == comp)
    makeRealVsPredScatterplots_byBCBS_CompressorandField(tmpdf,comp,ylim,allEB,log)
  }
}

makeRealVsPredScatterplots_byBCBS <- function(pred_df,ylim=0,allEB=0,log=0) {
  if (pred_df$samplemethod[1] == "uniform") {sampling <- "random"} 
  else {sampling <- "uniform"}
  
  dir <- paste0('img/scatter/',pred_df$app[1], '_',pred_df$samplemethod[1],'_',pred_df$model[1])
  title <- paste(pred_df$app[1],pred_df$model[1], 'regression modeling with', sampling,'sampling')
  
  if(allEB) { dir <- paste0(dir,"_allEB"); title <- paste(title,'with error bounds as parameter') }
  if(log) {
    pred_df$real <- log(pred_df$real)
    pred_df$pred <- log(pred_df$pred)
    title <- paste0(title, ', log of real vs pred')
    dir <- paste0(dir,'_log')
  }
  if(ylim) { dir <- paste0(dir,"_ylim") }
  dir <- paste0(dir, "_bcbs_scatter.png")
  
  if (ylim) {
    plt <- ggplot(pred_df,aes(x=real,y=pred,colour=as.factor(blocksize))) +
           geom_point(alpha=0.4) +
           facet_grid2(vars(compressor), vars(blockcount), space = "free_x") +
           ggtitle(title) +
           lims(y=c(0,ylim)) +
           labs(color="Block size") +
           geom_abline(slope=1)
    png(file=dir, width=5000,height=1650,res=300)
  } else {
    plt <- ggplot(pred_df,aes(x=real,y=pred,colour=as.factor(blocksize))) +
           geom_point(alpha=0.4) +
           facet_grid2(vars(compressor), vars(blockcount), space = "free_x") +
           ggtitle(title) +
           labs(color="Block size") +
           geom_abline(slope=1)
    png(file=dir,width=5000,height=1650,res=300)
  }
  
  print(plt)
  dev.off()
}

makeRealVsPredScatterplots <- function(pred_df,ylim=0) {
  dir <- 'img/scatter/'
  if (pred_df$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  if (ylim) {
    plt <- ggplot(pred_df,aes(x=log(real),y=log(pred),colour=as.factor(formatC(errorbound,format='e',digits=0)))) +
           geom_point(alpha=0.4) +
           facet_grid2(vars(compressor), vars(blocksize), space = "free_x") +
           ggtitle(paste(pred_df$app[1],pred_df$model[1], 'regression modeling with', sampling,'sampling')) +
           lims(y=c(0,ylim)) +
           labs(color="Error bound") +
           geom_abline(slope=1)
    png(file=paste0(dir,pred_df$app[1], '_',pred_df$samplemethod[1],'_',pred_df$model[1], "_ylim_scatter.png"), 
        width=1500,height=750)
  } else {
    plt <- ggplot(pred_df,aes(x=log(real),y=log(pred),colour=as.factor(formatC(errorbound,format='e',digits=0)))) +
           geom_point(alpha=0.4) +
           facet_grid2(vars(compressor), vars(blocksize), space = "free_x") +
           ggtitle(paste(pred_df$app[1],pred_df$model[1], 'regression modeling with', sampling,'sampling')) +
           labs(color="Error bound") +
           geom_abline(slope=1)
    png(file=paste0(dir,pred_df$app[1], '_',pred_df$samplemethod[1],'_',pred_df$model[1], "_scatter.png"), 
        width=1500,height=750)
  }
  print(plt)
  dev.off()
}

makeRealVsPredScatterplots_singleBC <- function(pred_df) {
  dir <- 'img/scatter/'
  if (pred_df$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  
  #print(pred_df)
  #print(sapply(pred_df,class))
  
  plt <- ggplot(pred_df,aes(x=log(real),y=log(pred),colour=as.factor(blocksize))) +
    geom_point(alpha=0.4) +
    facet_wrap(~blockcount,ncol=length(unique(pred_df$blockcount)), scales="free_x") +
    #facet_grid2(vars(compressor), vars(blockcount), space = "free_x") +
    ggtitle(paste(paste(pred_df$app[1],"\n", pred_df$compressor[1], pred_df$model[1], 'regression with', sampling,'sampling'))) +
    labs(color="Block size") +
    geom_abline(slope=1)
  png(file=paste0(dir,pred_df$app[1], '_', pred_df$compressor[1], "_", pred_df$samplemethod[1],'_',pred_df$model[1], "_bc", pred_df$blockcount[1],"_scatter.png"), 
      width=1450,height=900,res=300)
  
  print(plt)
  dev.off()
}
runMakeRealVsPredScatterplots_singleBC <- function(app,fdf,allEB=0,insmp=0,oos=0) {
  blockcounts <- c(16,24,64,80,128)
  
  if (allEB) { pred_df <- getPredictionsVsReal_allEB(fdf,app,uniform,flexmix,oos=oos,insmp=insmp) } 
  else { pred_df <- getPredictionsVsReal(fdf,app,uniform,flexmix) }
  
  
  for (comp in unique(fdf$compressor)) {
    for (bc in blockcounts) {
      tmpdf <- pred_df %>% filter(compressor == comp) %>% filter(blockcount == bc)
      makeRealVsPredScatterplots_singleBC(tmpdf) 
    }
  }
}

makeRealVsPredScatterplots_multiBC <- function(pred_df) {
  dir <- 'img/scatter/'
  if (pred_df$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  
  #print(pred_df)
  #print(sapply(pred_df,class))
  
  plt <- ggplot(pred_df,aes(x=log(real),y=log(pred),colour=as.factor(blocksize))) +
    geom_point(alpha=0.4) +
    facet_wrap(~blockcount,ncol=length(unique(pred_df$blockcount)), scales="free_x") +
    #facet_grid2(vars(compressor), vars(blockcount), space = "free_x") +
    ggtitle(paste(paste(pred_df$app[1], pred_df$compressor[1], pred_df$model[1], 'regression modeling with', sampling,'sampling'))) +
    labs(color="Block size") +
    geom_abline(slope=1)
  png(file=paste0(dir,pred_df$app[1], '_', pred_df$compressor[1], "_", pred_df$samplemethod[1],'_',pred_df$model[1], "_multibc_scatter.png"), 
      width=3000,height=900,res=300)
  
  print(plt)
  dev.off()
}
runMakeRealVsPredScatterplots_multiBC <- function(app,fdf) {
  blockcounts <- c(16,64,80,128)
  
  pred_df <- getPredictionsVsReal(fdf,app,uniform,flexmix)
  
  for (comp in unique(fdf$compressor)) {
    tmpdf <- pred_df %>% filter(compressor == comp) %>% filter(blockcount %in% blockcounts)
    makeRealVsPredScatterplots_multiBC(tmpdf)
  }
}

makeRealVsPredScatterplots_singleBCByComp <- function(pred_df,insmp=0,oos=0,allEB=0) {
  dir <- 'img/scatter/'
  if (pred_df$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  fname = paste0("img/scatter/", pred_df$app[1], "_", pred_df$samplemethod[1],'_',pred_df$model[1], "_bc", pred_df$blockcount[1])
  if(insmp) { fname <- paste0(fname, "_insmp") }
  if(oos) { fname <- paste0(fname, "_oos") }
  if(allEB) { fname <- paste0(fname, "_allEB") }
  
  fname <- paste0(fname, "_scatter_byEB.pdf")
  #fname <- paste0(fname, "_scatter.pdf")

  pred_df$errorbound <- as.factor(formatC(pred_df$errorbound,format='e',digits=0))
  
  plt <- ggplot(pred_df,aes(x=log(real),y=log(pred),colour=as.factor(errorbound))) +
  #plt <- ggplot(pred_df,aes(x=log(real),y=log(pred),colour=as.factor(blocksize))) +
  #plt <- ggplot(pred_df,aes(x=real,y=pred,colour=as.factor(blocksize))) +
    geom_point(alpha=0.2) +
    facet_wrap(~compressor,ncol=length(unique(pred_df$compressor)), scales="fixed") +
    #facet_grid2(vars(compressor), vars(blockcount), space = "free_x") +
    labs(color="Error bound") +
    lims(y=c(0,6)) +
    geom_abline(slope=1)
  pdf(file=fname,height=2,width=7.5)
  
  print(plt)
  dev.off()
}
runMakeRealVsPredScatterplots_singleBCByComp <- function(app,fdf,insmp=0,oos=0,allEB=0) {
  blockcounts <- c(16, 24, 64, 80, 128)
  
  pred_df <- getPredictionsVsReal(fdf,app,uniform,flexmix,oos,insmp,allEB)

  pred_df <- subset(pred_df, compressor != tthresh)
  pred_df <- subset(pred_df, compressor != bit_grooming)
  
  for (bc in blockcounts) {
    tmpdf <- pred_df %>% filter(blockcount == bc)
    makeRealVsPredScatterplots_singleBCByComp(tmpdf,insmp,oos,allEB) 
  }
}

makeRealVsPredScatterplots_singleBCBSByComp <- function(pred_df,insmp=0,oos=0,allEB=0) {
  dir <- 'img/scatter/'
  if (pred_df$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  fname = paste0("img/scatter/", pred_df$app[1], "_", pred_df$samplemethod[1],'_',pred_df$model[1], "_bc", pred_df$blockcount[1], "_bs", pred_df$blocksize[1])
  if(insmp) { fname <- paste0(fname, "_insmp") }
  if(oos) { fname <- paste0(fname, "_oos") }
  if(allEB) { fname <- paste0(fname, "_allEB") }
  fname <- paste0(fname, "_scatter.pdf")
  
  pred_df$errorbound <- as.factor(formatC(pred_df$errorbound,format='e',digits=0))
  
  plt <- ggplot(pred_df,aes(x=log(real),y=log(pred), color=as.factor(errorbound))) +
    geom_point(alpha=0.2) +
    facet_wrap(~compressor,ncol=length(unique(pred_df$compressor)), scales="fixed") +
    labs(color="Error bound") +
    #lims(y=c(0,200)) +
    geom_abline(slope=1)
  pdf(file=fname,height=2,width=7.5)
  
  print(plt)
  dev.off()
}
runMakeRealVsPredScatterplots_singleBCBSByComp <- function(app,fdf,insmp=0,oos=0,allEB=0) {
  blockcounts <- c(24)
  blocksizes <- c(28)
  pred_df <- getPredictionsVsReal(fdf,app,uniform,flexmix,oos,insmp,allEB)
  pred_df <- subset(pred_df, compressor != tthresh)
  pred_df <- subset(pred_df, compressor != bit_grooming)
  
  pred_df <- pred_df %>% filter(blocksize == blocksizes)
  
  for (bc in blockcounts) {
    tmpdf <- pred_df %>% filter(blockcount == bc)
    makeRealVsPredScatterplots_singleBCBSByComp(tmpdf, insmp, oos, allEB) 
  }
  
}




