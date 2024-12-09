

init_figures <- function() {
  var_nms <- c("hurricane_CLOUD","hurricane_PRECIP", "hurricane_step48","Miranda", "qmcpack", "SCALE")
  nbuffers <- c(48,48,13,7,288,11)
  #
  appdf <- as.data.frame(cbind(var_nms,as.integer(nbuffers)))
  colnames(appdf) <- c("app","buffers")
  #
  bit_grooming <- "bit_grooming"
  sperr <- "sperr"
  sz <- "sz"
  sz3 <- "sz3"
  tthresh <- "tthresh"
  zfp <- "zfp"
  return (appdf)
}
#
suppressPackageStartupMessages({
  library('plyr') #this needs to go before dplyr
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
  library('RColorBrewer')
  library('ggpubr')
})



reshape_df <- function(filtered_df,colname) {
  tmpdf <- cbind(filtered_df$blockcount,filtered_df$blocksize,filtered_df[colname])
  tmpdf <- as.data.frame(tmpdf)
  colnames(tmpdf) <- c("blockcount", "blocksize", "mape")
  tmpdf <- tmpdf %>% arrange(blockcount,blocksize)
  tmpdf <- reshape2::dcast(tmpdf,blockcount ~ blocksize, value.var="mape")
  row.names(tmpdf) <- tmpdf$blockcount
  tmpdf[1] <- NULL
  tmpdf <- tmpdf[order(as.numeric(row.names(tmpdf))), ]
  tmpdf <- tmpdf %>% select(mixedsort(names(.)))
  return (as.matrix(tmpdf))
}

#############################################################################################
#make heatmap (block size vs count with MAPE) for single configuration by (comp, error bound)
#no titles or labels only axis markers
#############################################################################################
heatmap_individual <- function(df,col_range,des){
  my.col <- rev(colorRampPalette(brewer.pal(9, "Greens"))(64))#(range))
  tmpdf <- reshape_df(df,"mape")
  png(file=paste0(des, ".png"),width=600, height=350)
  plot <- levelplot(tmpdf,xlab="",cexrow=0.6,ylab="",cexcol=0.6,col.regions = my.col,at=col_range)
  print(plot)
  dev.off()
}

getHeatmapAll <- function(fdf, compressors,error_bnds, error_modes, var_nm, smplmthd) {
  range <- diff(range(fdf$mape))
  col_range <- round(seq(min(fdf$mape),max(fdf$mape)),0)
  for (comp in compressors) {
    for (error_bnd in error_bnds){
      for (error_mode in error_modes){
        unique_des <- paste0(fname,"_heatmap_", comp, "_", formatC(error_bnd, format='e',digits=0), "_", smplmthd, "_", error_mode)
        filtered_df <- fdf %>% 
          filter(compressor == comp) %>% 
          filter(errorbound == error_bnd) %>%
          filter(errormode == error_mode)
        heatmap_individual(filtered_df,range, col_range, unique_des)
      }
    }
  }
}

heatmap_individual_withTitle <- function(df,range,des,comp,eb,error_mode,var_nm,smplmthd,quant=0){
  my.col <- rev(colorRampPalette(brewer.pal(9, "Greens"))(64))
  tmpdf <- reshape_df(df,"mape")
  quartile <- reshape_df(df,"quartilerange")
  png(file=paste0(des, ".png"),width=900, height=500)
  
  indx <- which(tmpdf > 200)
  tmpdf[tmpdf > 200] <- NA
  quartile[indx] <- NA
  
  plot.new()
  if (quant) {
    plot <- levelplot(tmpdf,xlab="block count",ylab="block size",main=comp,col.regions = my.col, at=range,
                      panel=function(x,y,z,...,subscripts=subscripts) {
                        arg <- list(...)
                        panel.levelplot(x=x,y=y,z=z,...,subscripts=subscripts)
                        #qq <- as.character(round((quartile),1))
                        qq <- as.character(round((tmpdf),1))
                        qq[indx] <- "x"
                        qq[is.na(qq)] <- ""
                        panel.text(x[subscripts],y[subscripts],labels=formatC(qq[subscripts],format='e',digits=1),cex=.65,font=1)
                      })
  } else {
    plot <- levelplot(tmpdf,xlab="block count",cexrow=0.6,ylab="block size",main=comp,cexcol=0.6,col.regions = my.col,at=range)
  }
  mtext(paste0(var_nm, " ", formatC(eb, format='e',digits=0), " ", error_mode, "_", df$samplemethod,"_",df$model, " MAPE"), line=2.5, font=2, cex=2)
  
  print(plot)
  dev.off()
}

############################################################################################
############################################################################################

trellis.par.set(panel.background = list(col="azure2"))
trellis.par.set(canonical.theme(color = FALSE))

trellis.device(color = FALSE)


#plot heatmap by error bound with all compressors
heatmap_allCompByEB <- function(fdf,error_bnds, error_mode,quant=0){
  fdf <- as.data.frame(fdf)
  var_nm <- fdf$app
  smplmthd <- fdf$samplemethod
  mdltype <- fdf$model
  for (error_bnd in error_bnds){
    tmpdf <- fdf %>% filter(errorbound == error_bnd)
    my.col <- rev(colorRampPalette(brewer.pal(9, "Greens"))(64))
    fdf_range <- round(seq(min(tmpdf$mape),max(tmpdf$mape)+1),0)
    plts <- list()
    quartiles <- list()
    compressors <- unique(tmpdf$compressor)
    unique_des <- paste0(var_nm,"_heatmap_", formatC(error_bnd, format='e',digits=0), "_", smplmthd, "_",mdltype,"_", error_mode)
    
    if (length(compressors) == 1) {
      heatmap_individual_withTitle(tmpdf,fdf_range,unique_des,compressors,error_bnd,error_mode,var_nm,smplmthd, quant)
      next
    }
    for (comp in compressors) {
      filtered_df <- tmpdf %>% filter(compressor == comp)
      plts[[length(plts)+1]] <- reshape_df(filtered_df,"mape")
      quartiles[[length(quartiles)+1]] <- reshape_df(filtered_df,"quartilerange")
    }
    if (length(compressors == 2)) {
      png(file=paste0(unique_des, ".png"),width=(length(compressors)+1) * 425,height=(length(compressors) +1) * 100 + 100)
    } else {
      png(file=paste0(unique_des, ".png"),width=length(compressors) * 425,height=length(compressors) * 100 + 100)  
    }
    
    ppar <- par(mfrow=c(2,2), oma=c(0,0,8,0))
    plot.new()
    
    idx = 1
    for (row_ in 1:1) {
      for (col_ in 1:length(compressors)) {
        indx <- which(plts[[idx]] > 200)
        plts[[idx]][plts[[idx]] > 200] <- NA
        tmp <- plts[[idx]]
        quartile <- quartiles[[idx]]
        quartile[indx] <- NA
        if (quant != 0){
          lp <- levelplot(plts[[idx]],xlab="block count",ylab="block size",main=compressors[idx],col.regions = my.col, at=fdf_range,
                  panel=function(x,y,z,...,subscripts=subscripts) {
                    arg <- list(...)
                    panel.levelplot(x=x,y=y,z=z,...,subscripts=subscripts)
                    #qq <- as.character(round((quartile),1))
                    qq <- as.character(round((tmp),1))
                    qq[indx] <- "x"
                    qq[is.na(qq)] <- ""
                    panel.text(x[subscripts],y[subscripts],labels=formatC(qq[subscripts],format='e',digits=1),cex=.65,font=1)
                  })
        }
        else {
          lp <- levelplot(plts[[idx]],xlab="block count",ylab="block size",main=compressors[idx],col.regions = my.col,at=fdf_range)
        }
        print(lp, split=c(col_,row_,length(compressors),1),more=TRUE)
        idx = idx + 1
      }
    }
    par(ppar)
    #print(paste0(var_nm," in multi compression"))
    mtext(paste0(var_nm, " ", formatC(error_bnd, format='e',digits=0), " ", error_mode, "_", smplmthd, "_",mdltype, " MAPE"), line=2.5, font=2, cex=2)
    ppar <- par(usr=c(0,1,0,1), # Reset the coordinates
              xpd=NA)   
    dev.off()
  }
}


############################################################################################
############################################################################################

#library(scales)
#show_col(my.col)

##plot heatmap by compressor with all error bounds
heatmap_allEBByComp <- function(fdf,compressors, error_bnds,error_mode,var_nm,smplmthd,quants=0,errbarNorm=0) {

  for (comp in compressors){
    tmpdf <- fdf %>% filter(compressor == comp)
    if (errbarNorm == 1) {
      my.col <- rev(colorRampPalette(brewer.pal(9, "Greens"))(64))
      fdf_range <- round(seq(min(fdf$mape),max(fdf$mape)+1),0)
    }
    else {
      my.col <- rev(colorRampPalette(brewer.pal(9, "Greens"))(64))
      fdf_range <- round(seq(min(tmpdf$mape),max(tmpdf$mape)+1),0)
    }
    plts <- list()
    quartiles <- list()
    
    unique_des <- paste0(app,"_heatmap_", comp, "_", smplmthd, "_", error_mode)
    for (error_bnd in error_bnds) {
      filtered_df <- fdf %>% 
        filter(compressor == comp) %>% 
        filter(errorbound == error_bnd) #%>%
        #filter(errormode == error_mode)
      
      plts[[length(plts)+1]] <- reshape_df(filtered_df,"mape")
      quartiles[[length(quartiles)+1]] <- reshape_df(filtered_df, "quartilerange")
    }
    
    png(file=paste0(unique_des, ".png"),width=length(error_bnds) * 425,height=length(error_bnds) * 100 + 100)
    ppar <- par(mfrow=c(2,4), oma=c(0,0,6,0))
    plot.new()
    idx = 1
    for (col_ in 1:4) {
      indx <- which(plts[[idx]] > 200)
      plts[[idx]][plts[[idx]] > 200] <- NA
      quartile <- quartiles[[idx]]
      quartile[indx] <- NA
      if (quants != 0) {
        lp <- levelplot(plts[[idx]],xlab="block count",ylab="block size",main=formatC(error_bnds[idx], format='e',digits=0),col.regions = my.col, at=fdf_range,
          panel=function(x,y,z,...,subscripts=subscripts) {
            arg <- list(...)
            panel.levelplot(x=x,y=y,z=z,...,subscripts=subscripts)
            qq <- as.character(round((quartile),1))
            qq[indx] <- "x"
            qq[is.na(qq)] <- ""
            panel.text(x[subscripts],y[subscripts],labels=formatC(qq[subscripts],format='e',digits=1),cex=.65,font=1)
          })
      } 
      else {
        lp <- levelplot(plts[[idx]],xlab="block count",ylab="block size",main=formatC(error_bnds[idx], format='e',digits=0),col.regions = my.col,at=fdf_range)
      }
      print(lp, split=c(col_,1,4,1),more=TRUE)
      idx = idx + 1
    }
    par(ppar)
    mtext(paste0(var_nm, " ", comp, " ", error_mode, " MAPE"), line=1, font=2, cex=2)
    # Reset the coordinates
    ppar <- par(usr=c(0,1,0,1), xpd=NA)   
    dev.off()
  }
}
############################################################################################
############################################################################################


boxPlotByFile <- function(accdf,des) {
  ebs <- unique(accdf$eb_list)
  comps <- unique(accdf$comp_list)
  tmpdf <- accdf %>% filter(comp_list == comp) %>% filter(eb_list == eb) %>% filter(bs_list == bs)
  
  ggplot(tmpdf, aes(x=files,y=abs(rel_err))) +
    geom_boxplot()
  
}





