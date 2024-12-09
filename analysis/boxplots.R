#
suppressPackageStartupMessages({
  library('plyr') #this needs to go before dplyr
  library('dplyr')
  library('fields')
  library('viridis')
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
})

################################################
################################################
getBoxplotByApp_forCompressor <- function(fdf) {
  for(samp in unique(fdf$samplemethod)) {
    tmpdf <- fdf %>% filter(samplemethod == samp)
    boxplotByModelAndBS_forCompressor(tmpdf)
    boxplotByModelAndBC_forCompressor(tmpdf)
  }
}
getBoxplotByAppEB_forCompressor <- function(fdf) {
  for(samp in unique(fdf$samplemethod)) {
    tmpdf <- fdf %>% filter(samplemethod == samp)
    boxplotByModelAndEB_forCompressor(tmpdf)
  }
  for(mod in unique(fdf$model)) {
    tmpdf <- fdf %>% filter(model == mod)
    boxplotBySamplemethodAndEB_forCompressor(tmpdf)
  }
}

boxplotBCAndComp_forBS <- function(fdf,ylim=0) {
  if (fdf$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  
  if (ylim) {
    p <- ggplot(data=fdf,aes(x=as.factor(blocksize),y=mape,color=blocksize)) +
      geom_boxplot(notch=FALSE) +
      ggh4x::facet_grid2(vars(compressor),vars(blockcount))+
      theme(legend.position = "none") +
      lims(y=c(0,ylim)) +
      labs(title=paste(fdf$app[1], fdf$model, "regression modeling with",sampling,"sampling"),x="Block Size", y = "MAPE")
    des <- paste0('img/boxplot/',fdf$app[1],"_",fdf$samplemethod[1],'_', fdf$model[1], "_boxplotByBS_ylim",ylim)
    png(file=paste0(des, ".png"),width=200*length(unique(fdf$blockcount)) + 200, height=200*length(unique(fdf$compressor)) + 200,res=200)
  } else {
    p <- ggplot(data=fdf,aes(x=as.factor(blocksize),y=mape,color=blocksize)) +
      geom_boxplot(notch=FALSE) +
      ggh4x::facet_grid2(vars(compressor),vars(blockcount))+
      theme(legend.position = "none") +
      labs(title=paste(fdf$app[1], fdf$model, "regression modeling with",sampling,"sampling"),x="Block Size", y = "MAPE")
    des <- paste0('img/boxplot/',fdf$app[1],"_",fdf$samplemethod[1],'_', fdf$model[1], "_boxplotByBS")
    png(file=paste0(des, ".png"),width=200*length(unique(fdf$blockcount)) + 200, height=200*length(unique(fdf$compressor)) + 200,res=200)
  }
  
  print(p)
  dev.off()
}

boxplotBCAndComp_forBS_singleEB <- function(fdf,eb,ylim=0) {
  if (fdf$samplemethod[1] == "uniform") { sampling <- "random" }
  else { sampling <- "uniform" }
  
  fdf <- fdf %>% filter(errorbound == eb)
  
  if (ylim) {
    p <- ggplot(data=fdf,aes(x=as.factor(blocksize),y=mape,color=blocksize)) +
      geom_boxplot(notch=FALSE) +
      ggh4x::facet_grid2(vars(compressor),vars(blockcount))+
      theme(legend.position = "none") +
      lims(y=c(0,ylim)) +
      labs(title=paste(fdf$app[1], fdf$model, "regression modeling with",sampling,"sampling,", formatC(eb,format='e',digits=0)),x="Block Size", y = "MAPE")
    des <- paste0('img/boxplot/',fdf$app[1],"_",fdf$samplemethod[1],'_', fdf$model[1], "_",formatC(eb,format='e',digits=0), "_boxplotByBS_ylim",ylim)
    png(file=paste0(des, ".png"),width=200*length(unique(fdf$blockcount)) + 200, height=200*length(unique(fdf$compressor)) + 200,res=200)
  } else {
    p <- ggplot(data=fdf,aes(x=as.factor(blocksize),y=mape,color=blocksize)) +
      geom_boxplot(notch=FALSE) +
      ggh4x::facet_grid2(vars(compressor),vars(blockcount))+
      theme(legend.position = "none") +
      labs(title=paste(fdf$app[1], fdf$model, "regression modeling with",sampling,"sampling,", formatC(eb,format='e',digits=0)),x="Block Size", y = "MAPE")
    des <- paste0('img/boxplot/',fdf$app[1],"_",fdf$samplemethod[1],'_', fdf$model[1],"_",formatC(eb,format='e',digits=0), "_boxplotByBS")
    png(file=paste0(des, ".png"),width=200*length(unique(fdf$blockcount)) + 200, height=200*length(unique(fdf$compressor)) + 200,res=200)
  }
  
  print(p)
  dev.off()
}

getBoxplotAndComp_BSAndEB <- function(fdf) {
  for (eb in unique(fdf$errorbound)) {
    boxplotBCAndComp_forBS_singleEB(fdf,eb)
  }
}

boxplotBySamplemethodAndBS_forCompressor <- function(fdf) {
  if (fdf$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  
  p <- ggplot(data=fdf,aes(x=as.factor(blocksize),y=mape,fill=samplemethod)) +
    geom_boxplot(notch=TRUE) +
    ggh4x::facet_grid2(~compressor)+#,scales = "free_y",independent="y") +
    labs(title=paste(fdf$app[1], "with", fdf$model, "regression modeling"), x="Block Size", y = "MAPE")
  
  des <- paste0(fdf$app[1],"_", fdf$model[1], "_boxplotByBS")
  png(file=paste0(des, ".png"),width=200*length(unique(fdf$compressor)) + 100, height=250)
  
  print(p)
  dev.off()
}

boxplotBySamplemethodAndBC_forCompressor <- function(fdf) {
  p <- ggplot(data=fdf,aes(x=as.factor(blockcount),y=mape,fill=samplemethod)) +
    geom_boxplot(notch=TRUE) +
    ggh4x::facet_grid2(~compressor) +
    coord_flip() +
    labs(title=paste(fdf$app[1], "with", fdf$model, "regression modeling"),x="Block Count", y = "MAPE")
  
  des <- paste0(fdf$app[1],"_", fdf$model[1], "_boxplotByBC")
  png(file=paste0(des, ".png"),width=100*length(unique(fdf$compressor)) + 100, height=150*length(unique(fdf$compressor)))
  
  print(p)
  dev.off()
}

boxplotByModelAndBS_forCompressor <- function(fdf) {
  p <- ggplot(data=fdf,aes(x=as.factor(blocksize),y=mape,fill=model)) +
    geom_boxplot(notch=TRUE) +
    ggh4x::facet_grid2(~compressor) +
    labs(title=paste(fdf$app[1], fdf$samplemethod, "sampling"),x="Block Size", y = "MAPE")
  
  des <- paste0(fdf$app[1],"_", fdf$samplemethod[1], "_boxplotByBS")
  png(file=paste0(des, ".png"),width=200*length(unique(fdf$compressor)) + 100, height=250)
  
  print(p)
  dev.off()
}

boxplotByModelAndBC_forCompressor <- function(fdf) {
  p <- ggplot(data=fdf,aes(x=as.factor(blockcount),y=mape,fill=model)) +
    geom_boxplot(notch=TRUE) +
    ggh4x::facet_grid2(~compressor) +
    coord_flip() +
    labs(title=paste(fdf$app[1], fdf$samplemethod, "sampling"),x="Block Count", y = "MAPE")
  
  des <- paste0(fdf$app[1],"_", fdf$samplemethod[1], "_boxplotByBC")
  png(file=paste0(des, ".png"),width=100*length(unique(fdf$compressor)) + 100, height=150*length(unique(fdf$compressor)))

  print(p)
  dev.off()
}

boxplotBySamplemethodAndEB_forCompressor <- function(fdf) {
  p <- ggplot(data=fdf,aes(x=as.factor(errorbound),y=mape,fill=samplemethod)) +
    geom_boxplot(notch=TRUE) +
    ggh4x::facet_grid2(~compressor) +
    labs(title=paste(fdf$app[1], "with", fdf$model, "regression modeling"),x="Error Bound", y = "MAPE")
  
  des <- paste0(fdf$app[1],"_", fdf$model[1], "_boxplotByEB")
  png(file=paste0(des, ".png"),width=200*length(unique(fdf$compressor)) + 100, height=250,res=200)

  print(p)
  dev.off()
}

boxplotByModelAndEB_forCompressor <- function(fdf) {
  if (fdf$samplemethod[1] == "uniform") { sampling <- "random" } 
  else { sampling <- "uniform" }
  
  p <- ggplot(data=fdf,aes(x=as.factor(formatC(errorbound, format='e',digits=0)),y=mape,fill=model)) +
    geom_boxplot(notch=FALSE) +
    ggh4x::facet_grid2(~compressor) +
    theme(legend.position = "none") +
    #coord_flip() +
    labs(title=paste(fdf$app[1], fdf$model[1], "modeling with", sampling, "sampling"),x="Error Bound", y = "MAPE")
  
  des <- paste0('img/boxplot/',fdf$app[1],"_",fdf$samplemethod[1],'_', fdf$model[1], "_boxplotByEB")
  png(file=paste0(des, ".png"),width=300*length(unique(fdf$compressor)) + 350, height=150*length(unique(fdf$compressor)),res=200)
  
  print(p)
  dev.off()
}
