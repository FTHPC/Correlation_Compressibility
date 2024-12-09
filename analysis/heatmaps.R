#
suppressPackageStartupMessages({
  library('plyr') #this needs to go before dplyr
  library('dplyr')
  library('fields')
  library('viridis')
  library('rhdf5')
  library('reshape2')
  library('tidyverse')
  library("lattice")
  library('stringr')
  library('gtools')
  library('gridExtra')
  library('RColorBrewer')
  library('ggpubr')
  library('ggh4x')
  library('car')
  library('patchwork')
  library('plotly')
  library('ggeffects')
  library('grid')
  library('hrbrthemes')
  hrbrthemes::import_roboto_condensed()
  hrbrthemes::import_public_sans()
  hrbrthemes::import_tinyhand()
  library('ggfittext')
  library('svglite')
})


################################################
################################################
makeSingleHeatmap <- function(fdf,lim=100) {
  if (fdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  ht=3; wdth=8;
  
  des <- paste0('img/heatmap/',fdf$app[1],"_heatmap_",fdf$compressor[1],"_", fdf$samplemethod[1], "_",fdf$model,".pdf")

  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    #facet_grid(~compressor) +
    labs(title=NULL,x="Block count", y="Block size",fill="MAPE") +
    theme(axis.title = element_text(size=15),strip.text.x = element_text(size=10),strip.text.y = element_text(size=10)) +
    theme(axis.text.x = element_text(size=10),axis.text.y = element_text(size=10)) +
    theme(legend.title=element_text(size=15), legend.text=element_text(size=11))
    theme_ipsum()
  pdf(des,
      height=ht,
      width=wdth)
  print(plt)
  dev.off()
}

makeDoubleHeatmapBySample <- function(fdf,lim=100) {
  if (fdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  fdf$samplemethod[fdf$samplemethod == "stride"] <- "Uniform k-Stride"
  fdf$samplemethod[fdf$samplemethod == "uniform"] <- "Random"
  ht=6; wdth=8;
  
  fdf$samplemethod <- as.factor(fdf$samplemethod)
  levels(fdf$samplemethod) <- c("Uniform k-Stride","Random")
  
  des <- paste0('img/heatmap/',fdf$app[1],"_heatmap_",fdf$compressor[1], "_",fdf$model,".pdf")
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    facet_wrap(~samplemethod,ncol=1) +
    labs(title=NULL,x="Block count", y="Block size",fill="MAPE") +
    theme(axis.title = element_text(size=15),strip.text.x = element_text(size=10),strip.text.y = element_text(size=10)) +
    theme(axis.text.x = element_text(size=10),axis.text.y = element_text(size=10)) +
    theme(legend.title=element_text(size=15), legend.text=element_text(size=11))
  theme_ipsum()
  pdf(des,
      height=ht,
      width=wdth)
  print(plt)
  dev.off()
}

makeHeatmapByCompressor <- function(fdf,lim=100) {
  if (fdf$samplemethod == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  
  for(comp in unique(fdf$compressor)) {
    dat <- fdf %>% filter(compressor == comp)
    if(!nrow(dat)) { next }
    
    des <- paste0('img/heatmap/',fdf$app[1],"_heatmap_", comp, "_", fdf$samplemethod[1], "_",fdf$model)
    dat$app <- sub("_", " ", dat$app)
    title <- paste(fdf$app[1], comp, "compression", fdf$model[1], 'regression modeling with',sample, "sampling")
    
    if (length(unique(dat$errorbound)) == 2) { width = 1725; height = 500 } 
    else { width = 1625; height = 300 }
    
    plt <- ggplot(dat,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
      geom_tile() + 
      geom_text(aes(label=round(mape,1)),size=2.0,check_overlap=TRUE) +
      scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
      coord_equal() +
      facet_grid(~formatC(errorbound,format='e',digits=0)) +
      labs(title=title,x="Block count",y="Block size") +
      theme(plot.title = element_text(size=30)) +
      theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
      theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
      theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
    png(file=paste0(des, ".png"), width=length(unique(dat$errorbound)) * width,height=length(unique(dat$errorbound)) * height,res=300 )  
    
    print(plt)
    dev.off()
  }
}

makeHeatmapByEB <- function(fdf,fill=1,lim=100) {
  if (fdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  
  for(eb in unique(fdf$errorbound)) {
    dat <- fdf %>% filter(errorbound == eb) %>% dplyr::select(app,blocksize,blockcount,compressor,mape) 
    if(!nrow(dat)) { next }
    
    des <- paste0('img/heatmap/',fdf$app[1],"_heatmap_", formatC(eb, format='e',digits=0), "_", fdf$samplemethod[1], "_",fdf$model)
    dat$app <- sub("_", " ", dat$app)
    title <- paste(fdf$app[1], fdf$model[1], 'regression modeling with',sample, "sampling,",formatC(eb, format='e',digits=0))
    
    if (length(unique(dat$compressor)) == 1) { wdth=1625; res=100 } 
    else if (length(unique(dat$compressor)) == 2) { wdth=1625; res=200 } 
    else { wdth=1200; res=200 }
    ht=800
    
    if (fill) {
      plt <- ggplot(dat,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
        geom_tile() + 
        geom_text(aes(label=round(mape,1)),size=2.0,check_overlap=TRUE) +
        scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
        coord_equal() +
        facet_grid(~compressor) +
        labs(title=title,x="Block count",y="Block size") +
        theme(plot.title = element_text(size=30)) +
        theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
        theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
        theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
      png(file=paste0(des, "_filled.png"), width=length(unique(dat$compressor)) * wdth,height= ht,res=res ) 
    } else {
      plt <- ggplot(dat,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
        geom_tile() + 
        scale_fill_continuous(high = "#CA0020", low = "#4DAC26") +
        coord_equal() +
        facet_grid(~compressor) +
        labs(title=title,x="Block count",y="Block size") +
        theme(plot.title = element_text(size=30)) +
        theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
        theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
        theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
      png(file=paste0(des, ".png"), width=length(unique(dat$compressor)) * wdth,height=ht,res=res ) 
    }
    print(plt)
    dev.off()
  }
}

makeHeatmapByEB_allEB <- function(fdf,fill=1,lim=100,oos=FALSE,allEB=FALSE,insmp=FALSE) {
  #fdf <- subset(fdf, compressor != tthresh)
  if (fdf$samplemethod[1] == "stride") { sample <- "uniform k-stride" } 
  else { sample <- "random" }
  
  res=200
  wdth=975
  ht=400
  
  fpath <- paste0('img/heatmap/',fdf$app[1],"_heatmap_allErrors_", fdf$samplemethod[1], "_", fdf$model[1])
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], fdf$model[1], 'regression modeling with',sample)
  if (oos) {
    fpath <- paste0(fpath,"_oos")
    title <- paste(title, "out of sample")
  } else if (insmp) {
    fpath <- paste0(fpath,"_insmp")
    title <- paste(title, "in sample")
  }
  title <- paste(title, "sampling")
  if (allEB) {
    fpath <- paste0(fpath,"_allEB")
    title <- paste(title, "all error bounds")
    wdth=975
    ht=600
  }

  if (fill) {
    plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
      geom_tile() + 
      geom_text(aes(label=round(mape,1)),size=2.5,check_overlap=TRUE) +
      scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
      coord_equal() +
      ggh4x::facet_grid2(vars(formatC(errorbound,format='e',digits=0)),vars(compressor)) +
      #labs(x="Block Count",y="Block size",fill="MAPE") +
      labs(title=title,x="Block Count",y="Block size",fill="MAPE") +
      theme(plot.title = element_text(size=25)) +
      theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
      theme(axis.text.x = element_text(size=12),axis.text.y = element_text(size=12)) +
      theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
    png(file=paste0(fpath, ".png"), width=wdth*length(unique(fdf$compressor)),height=ht*length(unique(fdf$errorbound)),res=res ) 
    #png(file=paste0(des, "_filled.png"), width=wdth,height=ht,res=res ) 
  } else {
    plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
      geom_tile() + 
      scale_fill_continuous(high = "#CA0020", low = "#4DAC26",limits=c(0,lim)) +
      coord_equal() +
      ggh4x::facet_grid2(vars(compressor),vars(formatC(errorbound,format='e',digits=0))) +
      labs(x="Block Count",y="Block Size",fill="") +
      theme(plot.title = element_text(size=25)) +
      theme(axis.title = element_text(size=20),strip.text.x = element_text(size=17.5),strip.text.y = element_text(size=20)) +
      theme(axis.text.x = element_text(size=13),axis.text.y = element_text(size=13)) +
      theme(legend.title=element_text(size=20), legend.text=element_text(size=13.5))
      #theme(legend.title="none")
    png(file=paste0(fpath, ".png"), width=wdth*length(unique(fdf$compressor)),height=ht*length(unique(fdf$errorbound)),res=res ) 
  }
  print(plt)
  dev.off()
  #}
}


makeHeatmapByEB_allEB_IQR <- function(fdf,fill=1,lim=100,oos=FALSE,allEB=FALSE,insmp=FALSE) {
  if (fdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  #print(fdf$app)
  
  res=200
  wdth=975
  ht=400
  
  fpath <- paste0('img/heatmap/',fdf$app[1],"_heatmap_allErrors_", fdf$samplemethod[1], "_", fdf$model[1])
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], fdf$model[1], 'regression modeling with',sample)
  if (oos) {
    fpath <- paste0(fpath,"_oos")
    title <- paste(title, "out of sample sampling")
  } else if (insmp) {
    fpath <- paste0(fpath,"_insmp")
    title <- paste(title, "in sample sampling")
  } else { title <- paste(title, "sampling") }
  if (allEB) {
    fpath <- paste0(fpath,"_allEB_IQR")
    title <- paste(title, "all error bounds")
    wdth=975
    ht=600
  } else { fpath <- paste0(fpath,"_IQR") }
  
  title <- paste(title, "with quantile ranges")
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(quartilerange,1)),size=2.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    ggh4x::facet_grid2(vars(formatC(errorbound,format='e',digits=0)),vars(compressor)) +
    #labs(x="Block Count",y="Block size",fill="MAPE") +
    labs(title=title,x="Block Count",y="Block size",fill="MAPE") +
    theme(plot.title = element_text(size=25)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=12),axis.text.y = element_text(size=12)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
  png(file=paste0(fpath, ".png"), width=wdth*length(unique(fdf$compressor)),height=ht*length(unique(fdf$errorbound)),res=res ) 
  #png(file=paste0(des, "_filled.png"), width=wdth,height=ht,res=res ) 

  print(plt)
  dev.off()
  #}
}


makeHeatmapByEBAndComp_allModels <- function(fdf,comp,lim=100) {
  des <- paste0('img/heatmap/',fdf$app[1], "_",comp,"_heatmap_allModels")  
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], comp, "compressor prediction accuracy across all models and error bounds")
  res=200
  wdth=1625
  ht=650
  if (length(unique(fdf$errorbound)) == 1) {
    ht <- 1100
  } 
  if (length(unique(fdf$errorbound)) == 2) { ht <- 700 }
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    ggh4x::facet_grid2(vars(formatC(errorbound,format='e',digits=0)),vars(as.factor(modelsample))) +
    labs(title=title,x="Block count",y="Block size") +
    theme(plot.title = element_text(size=30)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15), strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
  
  #theme_ipsum()
  png(file=paste0(des, "_filled.png"), width=length(unique(fdf$modelsample)) * wdth,height=length(unique(fdf$errorbound)) * ht,res=res ) 

  print(plt)
  dev.off()
  #}
}

getHeatmapByEBAndComp_allModels <- function(fdf_sl,fdf_ul,fdf_sf,fdf_uf,comp,lim=NA){
  fdf_sl$modelsample <- as.factor("uniform linear")
  fdf_ul$modelsample <- as.factor("random linear")
  fdf_sf$modelsample <- as.factor("uniform mixed")
  fdf_uf$modelsample <- as.factor("random mixed")
  fdf <- rbind(fdf_sl,fdf_ul,fdf_sf,fdf_uf)
  
  levels(fdf$modelsample) <- c("uniform linear","random linear","uniform mixed","random mixed")
  
  #for (comp in unique(fdf$compressor)) {
  tmpdf <- fdf %>% filter(compressor == comp)
  if (is.na(lim)) {
    if(mean(tmpdf$mape) < 5) {
      lim <- 5
    } else if (mean(tmpdf$mape) < 15) {
      lim <- 15
    } else if (mean(tmpdf$mape) < 25) {
      lim <- 25
    } else { lim <- 100 }
  }
  makeHeatmapByEBAndComp_allModels(tmpdf,comp,lim)
  #}
}
runGetHeatmapByEBAndComp_allModels <- function(fdf_sl,fdf_ul,fdf_sf,fdf_uf,limits){
  l <- 1
  for (comp in unique(fdf_sl$compressor)) {
    limit <- limits[l]
    getHeatmapByEBAndComp_allModels(fdf_sl,fdf_ul,fdf_sf,fdf_uf,comp,limit)
    l <- l + 1
  }
}


makeHeatmapSingleEBAndComp_allModels <- function(fdf,comp,lim=100) {
  des <- paste0('img/heatmap/',fdf$app[1], "_",comp,"_heatmap_allModels_allEB")

  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], comp, "compressor prediction accuracy across all models using all error bounds")
  res=200
  wdth=1625
  ht=1100

  #if (length(unique(fdf$errorbound)) == 2) { ht <- 700 }
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    facet_wrap(~modelsample,nrow=1) +
    labs(title=title,x="Block count",y="Block size") +
    theme(plot.title = element_text(size=30)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15), strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
  
  #theme_ipsum()
  png(file=paste0(des, "_filled.png"), width=length(unique(fdf$modelsample)) * wdth,height=ht,res=res ) 
  
  print(plt)
  dev.off()
  #}
}

getHeatmapSingleEBAndComp_allModels <- function(fdf,comp,lim=NA){
  
  #for (comp in unique(fdf$compressor)) {
  tmpdf <- fdf %>% filter(compressor == comp)
  if (is.na(lim)) {
    if(mean(tmpdf$mape) < 5) {
      lim <- 5
    } else if (mean(tmpdf$mape) < 15) {
      lim <- 15
    } else if (mean(tmpdf$mape) < 25) {
      lim <- 25
    } else { lim <- 100 }
  }
  makeHeatmapSingleEBAndComp_allModels(tmpdf,comp,lim)
  #}
}

runGetHeatmapSingleEBAndComp_allModels <- function(app,limits){
  fdf <- getFDF_allConfigs_allEB(app)
  l <- 1
  for (comp in unique(fdf$compressor)) {
    limit <- limits[l]
    getHeatmapSingleEBAndComp_allModels(fdf,comp,limit)
    l <- l + 1
  }
}

makeHeatmapByEachEBAndComp_allModels <- function(fdf,comp,lim=100) {
  des <- paste0('img/heatmap/',fdf$app[1], "_",comp,"_heatmap_allModels_allEBTrials")  
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], comp, "compressor prediction accuracy across all models and all error bound trials")
  res=200
  wdth=1625
  ht=650
  if (length(unique(fdf$errorbound)) == 1) {
    ht <- 1100
  } 
  if (length(unique(fdf$errorbound)) == 2) { ht <- 700 }
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    ggh4x::facet_grid2(vars(as.factor(errorbound)),vars(as.factor(modelsample))) +
    labs(title=title,x="Block count",y="Block size") +
    theme(plot.title = element_text(size=30)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15), strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
  
  #theme_ipsum()
  png(file=paste0(des, "_filled.png"), width=length(unique(fdf$modelsample)) * wdth,height=length(unique(fdf$errorbound)) * ht,res=res ) 
  
  print(plt)
  dev.off()
  #}
}
getHeatmapByEachEBAndComp_allModels <- function(fdf,comp,lim=NA){
  
  #for (comp in unique(fdf$compressor)) {
  tmpdf <- fdf %>% filter(compressor == comp)
  if (is.na(lim)) {
    if(mean(tmpdf$mape) < 5) {
      lim <- 5
    } else if (mean(tmpdf$mape) < 15) {
      lim <- 15
    } else if (mean(tmpdf$mape) < 25) {
      lim <- 25
    } else { lim <- 100 }
  }
  makeHeatmapByEachEBAndComp_allModels(tmpdf,comp,lim)
  #}
}
runGetHeatmapByEachEBAndComp_allModels <- function(app,limits){
  fdf <- getFDF_allConfigs(app,TRUE)
  l <- 1
  for (comp in unique(fdf$compressor)) {
    limit <- limits[l]
    print(paste(comp,limit))
    getHeatmapByEachEBAndComp_allModels(fdf,comp,limit)
    l <- l + 1
  }
}

makeHeatmapByEachEBAndComp_mixedModels <- function(fdf,comp,lim=100) {
  des <- paste0('img/heatmap/',fdf$app[1], "_",comp,"_heatmap_mixedModels_allEBTrials")  
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], comp, "compressor prediction accuracy across all models and all error bound trials")
  res=200
  wdth=1625
  ht=650
  if (length(unique(fdf$errorbound)) == 1) {
    ht <- 1100
  } 
  if (length(unique(fdf$errorbound)) == 2) { ht <- 700 }
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    ggh4x::facet_grid2(vars(as.factor(modelsample)),vars(formatC(errorbound,format='e',digits=0))) +
    labs(title=title,x="Block count",y="Block size") +
    theme(plot.title = element_text(size=30)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15), strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
  
  #theme_ipsum()
  png(file=paste0(des, "_filled.png"), height=length(unique(fdf$modelsample)) * ht ,width=length(unique(fdf$errorbound)) * wdth,res=res ) 
  
  print(plt)
  dev.off()
  #}
}
getHeatmapByEachEBAndComp_mixedModels <- function(fdf,comp,lim=NA){
  
  #for (comp in unique(fdf$compressor)) {
  tmpdf <- fdf %>% filter(compressor == comp)
  if (is.na(lim)) {
    if(mean(tmpdf$mape) < 5) {
      lim <- 5
    } else if (mean(tmpdf$mape) < 15) {
      lim <- 15
    } else if (mean(tmpdf$mape) < 25) {
      lim <- 25
    } else { lim <- 100 }
  }
  makeHeatmapByEachEBAndComp_mixedModels(tmpdf,comp,lim)
  #}
}
runGetHeatmapByEachEBAndComp_mixedModels <- function(app,limits,oos=FALSE){
  fdf <- getFDF_mixedModels(app,oos=oos)
  #print(head(fdf))
  l <- 1
  for (comp in unique(fdf$compressor)) {
    limit <- limits[l]
    print(paste(comp,limit))
    getHeatmapByEachEBAndComp_mixedModels(fdf,comp,limit)
    l <- l + 1
  }
}



makeHeatmapByComp_mixedModels <- function(fdf,comp,lim=100) {
  des <- paste0('img/heatmap/',fdf$app[1], "_",comp,"_heatmap_mixedModels")  
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste0(fdf$app[1], "\n", comp, " prediction accuracy")
  res=200
  wdth=725
  ht=425
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=2.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    facet_grid(modelsample ~ .) +
    #ggh4x::facet_grid2(vars(formatC(errorbound,format='e',digits=0)),vars(as.factor(modelsample))) +
    #labs(title=title,x="Block count",y="Block size") +
    labs(x="Block count",y="Block size") +
    theme(plot.title = element_text(size=23)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15), strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=10),axis.text.y = element_text(size=10)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=13))
  
  #theme_ipsum()
  png(file=paste0(des, "_filled.png"), width=length(unique(fdf$modelsample)) * wdth,height=length(unique(fdf$modelsample)) * ht,res=res ) 
  
  print(plt)
  dev.off()
  #}
}
getHeatmapByComp_mixedModels <- function(fdf,comp,lim=NA){
  #print(comp)
  #for (comp in unique(fdf$compressor)) {
  tmpdf <- fdf %>% filter(compressor == comp)
  if (is.na(lim)) {
    if(mean(tmpdf$mape) < 5) {
      lim <- 5
    } else if (mean(tmpdf$mape) < 15) {
      lim <- 15
    } else if (mean(tmpdf$mape) < 25) {
      lim <- 25
    } else { lim <- 100 }
  }
  makeHeatmapByComp_mixedModels(tmpdf,comp,lim)
  #}
}
runGetHeatmapByComp_mixedModels <- function(app,limits){
  fdf <- getFDF_mixedConfigs(app)
  l <- 1
  for (comp in unique(fdf$compressor)) {
    limit <- limits[l]
    getHeatmapByComp_mixedModels(fdf,comp,limit)
    l <- l + 1
  }
}


makeHeatmapByComp_linearModels <- function(fdf,comp,lim=100) {
  
  des <- paste0('img/heatmap/',fdf$app[1], "_",comp,"_heatmap_linearModels")  
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste0(fdf$app[1], "\n", comp, " prediction accuracy")
  res=200
  wdth=1290
  ht=1035
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    #geom_text(aes(label=round(mape,1)),size=2.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    facet_grid(modelsample ~ .) +
    #ggh4x::facet_grid2(vars(formatC(errorbound,format='e',digits=0)),vars(as.factor(modelsample))) +
    #labs(title=title,x="Block count",y="Block size") +
    labs(x="",y="") +
    labs(fill="") +
    #theme(plot.title = element_text(size=23)) +
    theme(axis.title = element_text(size=25),strip.text.x = element_text(size=13.5), strip.text.y = element_text(size=13.5)) +
    theme(axis.text.x = element_text(size=10),axis.text.y = element_text(size=10)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=11.5))
  
  #theme_ipsum()
  png(file=paste0(des, "_filled.png"), width=wdth,height=ht,res=res ) 
  
  print(plt)
  dev.off()
  #}
}

getHeatmapByComp_linearModels <- function(fdf,comp,lim=NA){
  #print(comp)
  #for (comp in unique(fdf$compressor)) {
  tmpdf <- fdf %>% filter(compressor == comp)
  #print(max(fdf$mape))
  if (is.na(lim)) {
    if(mean(tmpdf$mape) < 5) {
      lim <- 5
    } else if (mean(tmpdf$mape) < 15) {
      lim <- 15
    } else if (mean(tmpdf$mape) < 25) {
      lim <- 25
    } else { lim <- 100 }
  }
  makeHeatmapByComp_linearModels(tmpdf,comp,lim)
  #}
}
runGetHeatmapByComp_linearModels <- function(app,limits){
  fdf <- getFDF_linearModels(app)
  fdf <- fdf %>% filter(errorbound == 1e-4)
  l <- 1
  for (comp in unique(fdf$compressor)) {
    limit <- limits[l]
    #print(paste(comp,limit))
    getHeatmapByComp_linearModels(fdf,comp,limit)
    l <- l + 1
  }
}









getHeatmapByPosition_aggregateApps <- function(combined_df,lim=100) {
  #cdf <- combined_df %>% group_by(blocksize,blockcount,compressor,errorbound) %>%
  cdf <- combined_df %>% group_by(blocksize,blockcount,compressor) %>%
    dplyr::summarise("mape" = mean(mape,na.rm=TRUE))
  
  cdf$samplemethod <- combined_df$samplemethod[1]
  cdf$model <- combined_df$model[1]
  
  if (cdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  
  des <- paste0('img/heatmap/combined_heatmap_allErrors_', cdf$samplemethod[1], "_",cdf$model[1])
  title <- paste('Combined', cdf$model[1], 'regression modeling with',sample, "sampling")
  
  res=200
  wdth=1650
  ht=1100
  
  plt <- ggplot(cdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=2.0,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    facet_grid(~compressor) +
    labs(title=title,x="Block count",y="Block size") +
    theme(plot.title = element_text(size=30)) +
    theme(axis.title = element_text(size=25),strip.text.x = element_text(size=20),strip.text.y = element_text(size=20)) +
    theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
    theme(legend.title=element_text(size=25), legend.text=element_text(size=20)) +
    guides(fill = guide_colourbar(barwidth = 1,barheight = 20))
  png(file=paste0(des, "_filled.png"), width=length(unique(cdf$compressor)) * wdth,height= ht,res=res ) 
  
  print(plt)
  dev.off()
}

getHeatmapByPosition_aggregateAppsByEB <- function(combined_df,lim=100) {
  cdf <- combined_df %>% group_by(blocksize,blockcount,compressor,errorbound) %>%
    #cdf <- combined_df %>% group_by(blocksize,blockcount,compressor) %>%
    dplyr::summarise("mape" = mean(mape,na.rm=TRUE))
  
  cdf$samplemethod <- combined_df$samplemethod[1]
  cdf$model <- combined_df$model[1]
  
  if (cdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  
  des <- paste0('img/heatmap/combined_heatmap_byEB_', cdf$samplemethod[1], "_",cdf$model[1])
  title <- paste('Combined', cdf$model[1], 'regression modeling with',sample, "sampling")
  
  res=200
  wdth=1650
  ht=1100
  
  plt <- ggplot(cdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.0,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    ggh4x::facet_grid2(vars(formatC(errorbound,format='e',digits=0)),vars(compressor)) +
    labs(title=title,x="Block count",y="Block size") +
    theme(plot.title = element_text(size=30)) +
    theme(axis.title = element_text(size=25),strip.text.x = element_text(size=20),strip.text.y = element_text(size=20)) +
    theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
    theme(legend.title=element_text(size=25), legend.text=element_text(size=20)) +
    guides(fill = guide_colourbar(barwidth = 1,barheight = 20))
  png(file=paste0(des, "_filled.png"), width=length(unique(cdf$compressor)) * wdth,height= length(unique(cdf$errorbound)) * ht,res=res ) 
  
  print(plt)
  dev.off()
  
}

getHeatmapByPosition_aggregateAppsAllData <- function(combined_df,lim=100) {
  cdf <- combined_df %>% group_by(blocksize,blockcount,compressor) %>%
    dplyr::summarise("mape" = mean(mape,na.rm=TRUE))
  
  des <- paste0('img/heatmap/combined_heatmap_allErrors_allModels')
  title <- paste('Combined modeling, sampling, and error bound by compressor')
  
  res=200
  wdth=1650
  ht=1100
  
  plt <- ggplot(cdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    geom_text(aes(label=round(mape,1)),size=3.5,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    facet_grid(~compressor) +
    labs(title=title,x="Block count",y="Block size") +
    theme(plot.title = element_text(size=30)) +
    theme(axis.title = element_text(size=25),strip.text.x = element_text(size=20),strip.text.y = element_text(size=20)) +
    theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
    theme(legend.title=element_text(size=25), legend.text=element_text(size=18)) +
    guides(fill = guide_colourbar(barwidth = 1,barheight = 5))
  png(file=paste0(des, "_filled.png"), width=length(unique(cdf$compressor)) * wdth,height=ht,res=res ) 
  
  print(plt)
  dev.off()
}


makeHeatmapForSampleSize <- function(app, dims, blocksizes, blockcounts,lim=100) {
  total_size <- dims[1] * dims[2] * dims[3]
  cnames <- c("blocksize","blockcount","samplesize")
  sample_sizes <- data.frame(matrix(ncol = length(cnames),nrow=1))
  colnames(sample_sizes) <- cnames
  
  for (bs in blocksizes) {
    for (bc in blockcounts) {
      samplesize <- ((bs*bs*bs*bc) / total_size) * 100
      if (samplesize > 100) { samplesize <- NA }
      sample_sizes <- rbind(sample_sizes, c(bs,bc,samplesize)) 
    }
  }
  sample_sizes <- na.omit(sample_sizes)
  
  ht=4; wdth=11
  des <- paste0('img/heatmap/',app,'_samplesizes.pdf')
  app <- sub("_", " ", app)
  title <- paste(app, "% data sampled by block count and block size" )
  
  plt <- ggplot(sample_sizes,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=samplesize)) +
    geom_tile() + 
    geom_text(aes(label=round(samplesize,1)),size=6,check_overlap=TRUE) +
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    #labs(title=title) +
    labs(x="Block count",y="Block size") +
    labs(fill="% sampled") +
    #theme(plot.title = element_text(size=25)) +
    #theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15), strip.text.y = element_text(size=15)) +
    theme(axis.title = element_text(size=25),strip.text.x = element_text(size=20), strip.text.y = element_text(size=20)) +
    theme(axis.text.x = element_text(size=20),axis.text.y = element_text(size=20)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=20))
  pdf(file=des, width=wdth,height=ht) 
  
  print(plt)
  dev.off()
  
}

makeHeatmapByField_allEB_averages <- function(fdf,compressor,fill=1,lim=100,oos=FALSE,allEB=FALSE,insmp=FALSE) {
  
  #print(lim)
  fdf <- na.omit(fdf)
  
  if (fdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  
  res=200
  wdth=1000 * length(unique(fdf$errorbound))
  ht=350 * length(unique(fdf$field))
  
  fpath <- paste0('img/heatmap/',fdf$app[1],"_avgAPE_heatmap_allFields_", compressor, '_', fdf$samplemethod[1], "_", fdf$model[1])
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], compressor, 'AAPE for', fdf$model[1], 'regression modeling with',sample)
  if (oos) {
    fpath <- paste0(fpath,"_oos")
    title <- paste(title, "out of sample")
  } else if (insmp) {
    fpath <- paste0(fpath,"_insmp")
    title <- paste(title, "in sample")
  }
  title <- paste(title, "sampling")
  if (allEB) {
    fpath <- paste0(fpath,"_allEB")
    title <- paste(title, "all error bounds")
  }
  
  #print(head(fdf))
  
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=avgAPE)) +
    geom_tile() + 
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    geom_text(aes(label=round(avgAPE,1)),size=2.5,check_overlap=TRUE) +
    ggh4x::facet_grid2(vars(field),vars(formatC(errorbound,format='e',digits=0))) +
    labs(title=title,x="Error bound",y="Field",fill="AAPE") +
    theme(plot.title = element_text(size=25)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=12),axis.text.y = element_text(size=12)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=16)) +
    guides(fill = guide_colourbar(barwidth = 1,barheight = 20))
  
  png(file=paste0(fpath, ".png"), width=wdth,height=ht,res=res ) 
  
  print(plt)
  dev.off()
}
runMakeHeatmapByField_allEB_average <- function(fdf,fill=1,lim=100,oos=FALSE,allEB=FALSE,insmp=FALSE) {
  for (comp in unique(fdf$compressor)) {
    print(comp)
    tmpdf <- fdf %>% filter(compressor == comp)
    makeHeatmapByField_allEB_averages(tmpdf,comp,fill,lim,oos,allEB,insmp)
  }
}


  

makeHeatmapByField_allEB <- function(fdf,compressor,fill=1,lim=100,oos=FALSE,allEB=FALSE,insmp=FALSE) {
  
  #print(lim)
  fdf <- na.omit(fdf)
  
  if (fdf$samplemethod[1] == "stride") { sample <- "uniform" } 
  else { sample <- "random" }
  
  res=200
  wdth=1000 * length(unique(fdf$errorbound))
  ht=350 * length(unique(fdf$field))
  
  fpath <- paste0('img/heatmap/',fdf$app[1],"_heatmap_allFields_", compressor, '_', fdf$samplemethod[1], "_", fdf$model[1])
  fdf$app <- sub("_", " ", fdf$app)
  title <- paste(fdf$app[1], compressor, fdf$model[1], 'regression modeling with',sample)
  if (oos) {
    fpath <- paste0(fpath,"_oos")
    title <- paste(title, "out of sample")
  } else if (insmp) {
    fpath <- paste0(fpath,"_insmp")
    title <- paste(title, "in sample")
  }
  title <- paste(title, "sampling")
  if (allEB) {
    fpath <- paste0(fpath,"_allEB")
    title <- paste(title, "all error bounds")
  }
  
  #print(head(fdf))
  
  
  plt <- ggplot(fdf,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
    geom_tile() + 
    scale_fill_gradient(high = "#CA0020", low = "#4DAC26", limits = c(0,lim)) +
    coord_equal() +
    geom_text(aes(label=round(mape,1)),size=2.5,check_overlap=TRUE) +
    ggh4x::facet_grid2(vars(field),vars(formatC(errorbound,format='e',digits=0))) +
    labs(title=title,x="Error bound",y="Field",fill="MAPE") +
    theme(plot.title = element_text(size=25)) +
    theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
    theme(axis.text.x = element_text(size=12),axis.text.y = element_text(size=12)) +
    theme(legend.title=element_text(size=20), legend.text=element_text(size=16)) +
    guides(fill = guide_colourbar(barwidth = 1,barheight = 20))

  png(file=paste0(fpath, ".png"), width=wdth,height=ht,res=res ) 
  
  print(plt)
  dev.off()
}


runMakeHeatmapByField_allEB <- function(fdf,fill=1,lim=100,oos=FALSE,allEB=FALSE,insmp=FALSE) {
  for (comp in unique(fdf$compressor)) {
    print(comp)
    tmpdf <- fdf %>% filter(compressor == comp)
    makeHeatmapByField_allEB(tmpdf,comp,fill,lim,oos,allEB,insmp)
  }
}
  

makeHeatmapByCompressorOtherMethods <- function(fdf,app,lim=100) {
  sample <- fdf$method
  
  for(comp in unique(fdf$compressor)) {
    dat <- fdf %>% filter(compressor == comp)
    if(!nrow(dat)) { next }
    
    des <- paste0('img/priorwork/', fdf$method[1], "_", app[1],"_heatmap_", comp, ".pdf")
    dat$app <- sub("_", " ", dat$app)
    title <- paste(method, "prediction error for", comp, "on",app, "data")
    
    width = 6 * length(unique(fdf$errorbound))
    height = 1.5 * length(unique(fdf$errorbound))

    
    plt <- ggplot(dat,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
      geom_tile() + 
      geom_text(aes(label=round(mape,1)),size=3.0,check_overlap=TRUE) +
      scale_fill_gradient(high = "#CA0020", low = "#4DAC26") +
      coord_equal() +
      facet_grid(~formatC(errorbound,format='e',digits=0)) +
      labs(title=title,x="Block count",y="Block size") +
      theme(plot.title = element_text(size=30)) +
      theme(axis.title = element_text(size=20),strip.text.x = element_text(size=15),strip.text.y = element_text(size=15)) +
      theme(axis.text.x = element_text(size=15),axis.text.y = element_text(size=15)) +
      theme(legend.title=element_text(size=20), legend.text=element_text(size=16))
    
    pdf(des,
        height=height,
        width=width)
    print(plt)
    dev.off()
    
  }
}

  
  



