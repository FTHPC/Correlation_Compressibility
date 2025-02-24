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


crChangesByFileAndTimestep <- function(fdf,compressor,thresh=0) {
  if(thresh) { dir <- paste0('img/lineplot/',fdf$app[1],'_',fdf$compressor[1],'_filtered_lineplot.pdf') } 
  else {dir <- paste0('img/lineplot/',fdf$app[1],'_',fdf$compressor[1],'_lineplot.pdf') }
  
  
  title <- paste(fdf$app[1], fdf$compressor[1], 'compression ratios by timestep')
  if(thresh) { title <- paste0(title, ', filtered')}
  
  #timesteps <- unique(fdf$timestep)

  #print(timesteps)
    
  pdf(file=dir)

  p <- ggplot(fdf,aes(x=factor(timestep),y=real,color=as.factor(formatC(errorbound,format='e',digits=0)))) +
    geom_point() +
    geom_line() +
    #xlab(as.factor(fdf$timestep)) +
    facet_grid(field~.,scales="free_y") +
    labs(title=title,x="Global CR", y="Time step", color='error bound') +
    theme(plot.title = element_text(size=15)) +
    theme(axis.title = element_text(size=10),strip.text.y =element_text(size=5)) +
    theme(axis.text.x = element_text(size=5),axis.text.y = element_text(size=5)) +
    theme(legend.title=element_text(size=8),legend.text=element_text(size=5))

  ggsave(dir,dpi=320)
  #dev.off()
}

runCRByFileAndTimestep <- function(fdf,thresh=0) {
  if(thresh) { fdf <- fdf %>% filter(real < thresh) }
  
  for (comp in unique(fdf$compressor)) {
    tmpdf <- fdf %>% filter(compressor == comp)
    crChangesByFileAndTimestep(tmpdf, comp, thresh)
  }
}


clearDevs <- function() {
  for (i in dev.list()[1]:dev.list()[length(dev.list())]) { dev.off() }
}





