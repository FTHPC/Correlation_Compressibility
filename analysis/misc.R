```{css zoom-lib-src, echo = FALSE}
script src = "https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"
```

```{js zoom-jquery, echo = FALSE}
$(document).ready(function() {
  $('body').prepend('<div class=\"zoomDiv\"><img src=\"\" class=\"zoomImg\"></div>');
  // onClick function for all plots (img's)
    $('img:not(.zoomImg)').click(function() {
      $('.zoomImg').attr('src', $(this).attr('src')).css({width: '100%'});
      $('.zoomDiv').css({opacity: '1', width: 'auto', border: '1px solid white', borderRadius: '5px', position: 'fixed', top: '50%', left: '50%', marginRight: '-50%', transform: 'translate(-50%, -50%)', boxShadow: '0px 0px 50px #888888', zIndex: '50', overflow: 'auto', maxHeight: '100%'});
    });
    // onClick function for zoomImg
    $('img.zoomImg').click(function() {
      $('.zoomDiv').css({opacity: '0', width: '0%'}); 
    });
  });
```




dat <- fdf %>% filter(errorbound == eb) %>% 
               filter(compressor == comp) %>%
               select(blocksize,blockcount,mape) %>%
               mutate(
                 blockcount = factor(blockcount,levels=unique(blockcount)),
                 blocksize = factor(blocksize)
               )
library(ggpubr)

- local({
  i <- i
  p1 <- ggplot(data2, aes(x = data2[[i]])) +
    geom_histogram(fill = "lightgreen") +
    xlab(colnames(data2)[i])
  print(p1)
})



hurricane_step48 <- rbind(hurricane_step48_stride_linear_fdf,hurricane_step48_stride_mixed_fdf,
                          hurricane_step48_uniform_linear_fdf,hurricane_step48_uniform_mixed_fdf)

hurricane_cloud <- rbind(hurricane_CLOUD_stride_linear_fdf,hurricane_CLOUD_stride_mixed_fdf,
                         hurricane_CLOUD_uniform_linear_fdf,hurricane_CLOUD_uniform_mixed_fdf)

hurricane_precip <- rbind(hurricane_PRECIP_stride_linear_fdf,hurricane_PRECIP_stride_mixed_fdf,
                          hurricane_PRECIP_uniform_linear_fdf,hurricane_PRECIP_uniform_mixed_fdf)

miranda <- rbind(Miranda_stride_linear_fdf,Miranda_stride_mixed_fdf,
                 Miranda_uniform_linear_fdf,Miranda_uniform_mixed_fdf)

qmcpack <- rbind(qmcpack_stride_linear_fdf,qmcpack_stride_mixed_fdf,
                 qmcpack_uniform_linear_fdf,qmcpack_uniform_mixed_fdf)


scale <- rbind(SCALE_stride_linear_fdf,SCALE_stride_mixed_fdf,
                 SCALE_uniform_linear_fdf,SCALE_uniform_mixed_fdf)


combined_df <- rbind(hurricane_step48,hurricane_cloud,hurricane_precip,miranda,qmcpack,scale)

library(ggbreak)




library(tidymodels)

tmpdf <- hurricane_cloud %>%
  mutate(
    log_mape = log(mape)
  )

tmp_fit <- linear_reg() %>%
  fit(log_mape ~ blocksize, data = tmpdf)

tmp_aug <- augment(tmp_fit, new_data = tmpdf) %>%
  mutate(.resid = exp(.resid))

ggplot(tmp_aug, aes(x = blocksize, y = .resid)) + 
  geom_point()





library('plotly')
library('ggeffects')
library('grid')
library('hrbrthemes')
hrbrthemes::import_roboto_condensed()
hrbrthemes::import_public_sans()
hrbrthemes::import_tinyhand()
for (j in 1:1) {
  errormode <- "pressio:abs"
  for(eb in unique(fdf$errorbound)) {
    title <- paste0(fdf$app[1], " ", formatC(eb, format='e',digits=0), " ", errormode, " ", fdf$samplemethod[1], " ", fdf$model[1], " MAPE")
    des <- paste0(fdf$app[1],"_heatmap_", formatC(eb, format='e',digits=0), "_", fdf$samplemethod[1], "_",fdf$model,"_", errormode)
    dat <- fdf %>% filter(errorbound == eb) %>% dplyr::select(blocksize,blockcount,compressor,mape) 
    if(!nrow(dat)) { next }
    
    plt <- ggplot(dat,aes(x=as.factor(blockcount),y=as.factor(blocksize),fill=mape)) +
      geom_tile() + 
      geom_text(aes(label=round(mape,1)),size=2.5) +
      #scale_fill_viridis(discrete=FALSE) +
      scale_fill_continuous(low = "violetred", high = "aquamarine") +
      #scale_fill_distiller(palette = "RdPu") +
      #scale_fill_gradient(low="green",high="red") +
      scale_x_discrete(expand = c(0,0)) + 
      scale_y_discrete(expand = c(0,0)) +
      facet_wrap(~compressor,ncol=length(unique(dat$compressor))) +
      labs(title=title) +
      theme_ipsum()
    png(file=paste0(des, ".png"), width=length(unique(dat$compressor)) * 425,height=length(unique(dat$compressor)) * 60 )#+ 100)  
    print(plt)
    dev.off()
  }
}

#library(hrbrthemes)
plt <- ggplot(dat, aes(blockcount,blocksize,fill=mape)) +
  geom_tile() +
  geom_text(aes(label=round(mape,1))) +
  scale_fill_gradient(low="green", high="red")
dev.off()
 # theme_ipsum()
  #scale_fill_gradient(low="green",high="red")




real <- read_csv("rawdata_analysis/hurricane/precip/hurricane_PRECIP_stride_linear_real.csv", 
                                                col_names = FALSE)
pred <- read_csv("rawdata_analysis/hurricane/precip/hurricane_PRECIP_stride_linear_pred.csv", 
                                                col_names = FALSE)
hurricane_PRECIP_stride_linear_predictions <- filterPredictions(hurricane_PRECIP_stride_linear_fdf,real,pred)







#aggregate accuracy by compressor and EB across a fixed block size
getAccuracyByCompressor_withEB <- function(fdf, block_size, error_bnd) {
  fdf_block <- fdf %>% filter(blocksize == block_size) %>% filter(errorbound == error_bnd)
  by_compressor <- fdf_block %>% group_by(compressor)
  df <- by_compressor %>% summarise("mape" = mean(mape), 
                                    "stdv" = sd(mape), 
                                    "range" = mean(quartilerange), 
                                    "lowerr" = mean(lowererr), 
                                    "uperr" = mean(uppererr))
  return(df)
}

#aggregate accuracy by compressor and EB across a fixed block size
getAccuracyByEB_withCompressor <- function(fdf, block_size, comp) {
  fdf_block <- fdf %>% filter(blocksize == block_size) %>% filter(compressor == comp)
  by_eb <- fdf_block %>% group_by(errorbound)
  formatC(by_eb$errorbound, format='e', digits=0)
  df <- by_eb %>% summarise("mape" = mean(mape), 
                                    "stdv" = sd(mape), 
                                    "range" = mean(quartilerange), 
                                    "lowerr" = mean(lowererr), 
                                    "uperr" = mean(uppererr))
  formatC(df$errorbound, format='e', digits=0)
  return(df)
}

getAccuracyByErrBndAndBlockSize <- function(fdf,block_sizes) {
  for (comp in unique(fdf$compressor)) {
    for (bs in unique(fdf$blocksize)) {
      res <- getAccuracyByEB_withCompressor(fdf,bs,comp)
      print(paste0(comp,", ", bs))
      print(res)
    }
  }
}

getAccuracyByBlockCount <- function(fdf) {
  for (bc in unique(fdf$blockcount)) {
    res <- getAccuracyByCompressor_fixedBlockCount(fdf,bc)
    print(bc)
    print(res)
  }
}

getAccuracyByFileAndCompressor_fixedSizes <- function(accdf, bs, bc) {
  tmpdf <- accdf %>% filter(blocksize == bs) %>% filter(blockcount == bc)
  df_sum <- c()
  for (comp in unique(accdf$compressor)) {
    tmp <- tmpdf %>% filter(compressor == comp)
    
    by_file <- tmp %>% group_by(files)
    df <- by_file %>% summarise("comp" = comp,
                                "median_err" = median(abs(relerr)),
                                "mean_err" = mean(abs(relerr)),
                                "stdv_err" = sd(abs(relerr)))
    df_sum <- rbind(df_sum, df)
  }
  return (df_sum)
}

getAccuracyByFileCompressorBS <- function(accdf, bs) {
  tmpdf <- accdf %>% filter(blocksize == bs)
  df_sum <- c()
  for (comp in unique(accdf$compressor)) {
    tmp <- tmpdf %>% filter(compressor == comp)
    
    by_file <- tmp %>% group_by(files)
    df <- by_file %>% summarise("comp" = comp,
                                "median_err" = median(abs(relerr)),
                                "mean_err" = mean(abs(relerr)),
                                "stdv_err" = sd(abs(relerr)))
    df_sum <- rbind(df_sum, df)
  }
  return (df_sum)
}

accuracyByFileCompressorBS <- function(accdf) {
  for (bs in unique(accdf$blocksize)) {
    res <- getAccuracyByFileCompressorBS(accdf,bs)
    print(res)
  }
}


getAccuracyByFileCompressorEB <- function(accdf, eb) {
  tmpdf <- accdf %>% filter(errorbound == eb)
  df_sum <- c()
  for (comp in unique(accdf$compressor)) {
    tmp <- tmpdf %>% filter(compressor == comp)
    
    by_file <- tmp %>% group_by(files)
    df <- by_file %>% summarise("comp" = comp,
                                "median_err" = median(abs(relerr)),
                                "mean_err" = mean(abs(relerr)),
                                "stdv_err" = sd(abs(relerr)))
    df_sum <- rbind(df_sum, df)
  }
  return (df_sum)
}

accuracyByFileCompressorEB <- function(accdf) {
  for (eb in unique(accdf$errorbound)) {
    res <- getAccuracyByFileCompressorEB(accdf,eb)
    print(res)
  }
}



boxplotByFile <- function(accdf, comp) {
  boxplot(abs(rel_err) ~ files,data=accdf)
}

boxplotMAPEByCompressorAndBS <- function(df,bs) {
  tmpdf <- df %>% filter(blocksize == bs)
  boxplot(mape ~ compressor,data=tmpdf)
}

boxplotMAPEByCompressorAndBSEB <- function(df,bs,eb) {
  tmpdf <- df %>% filter(blocksize == bs) %>% filter(errorbound == eb)
  boxplot(mape ~ compressor,data=tmpdf)
  title(paste(bs, eb))
}

getBoxplotMAPEByCompBSEB <- function(df) {
  for (eb in unique(df$errorbound)) {
    for (bs in unique(df$blocksize)) {
      boxplotMAPEByCompressorAndBSEB(df,bs,eb)
    }
  }
}

boxplotMAPEByCompressorAndBCEB <- function(df,bc,eb) {
  tmpdf <- df %>% filter(blockcount == bc) %>% filter(errorbound == eb)
  boxplot(mape ~ compressor,data=tmpdf)
  title(paste(bs, eb))
}

getBoxplotMAPEByCompBCEB <- function(df) {
  for (eb in unique(df$errorbound)) {
    for (bc in unique(df$blockcount)) {
      boxplotMAPEByCompressorAndBCEB(df,bs,eb)
    }
  }
}
boxplotByBS_allCompressors <- function(fdf) {
  ggplot(data=fdf,aes(x=as.factor(blocksize),y=mape,fill=samplemethod)) +
    geom_boxplot(notch=TRUE) +
    ggh4x::facet_grid2(~compressor,scales = "free_y",independent="y")
}


boxplotMAPE_CompressorAndBSBC <- function(df,comp) {
  tmpdf <- df %>% filter(compressor == comp)
  ggplot(tmpdf,aes(mape)) +
    geom_boxplot() + 
    facet_grid(vars(blocksize),vars(blockcount))
  #title(comp)
}

boxplotMAPE_AllCompressorAndBS <- function(df) {
  #tmpdf <- df %>% filter(compressor == comp)
  ggplot(df,aes(x=as.factor(df$blocksize),y=df$mape)) +
    geom_boxplot() + 
    facet_grid(cols=vars(compressor),scales = "free",independent="y")
  #title(comp)
}

boxplotMAPE_CompressorAndBS <- function(df,comp) {
  tmpdf <- df %>% filter(compressor == comp)
  boxplot(mape ~ blocksize,data=tmpdf)
  title(comp)
}

boxplotMAPE_CompressorAndBSEB <- function(df,comp,eb) {
  tmpdf <- df %>% filter(compressor == comp) %>% filter(errorbound == eb)
  if (nrow(tmpdf)) {
    des <- paste0(df$app[1],"_boxplot_bybs_", comp,"_", formatC(eb, format='e',digits=0), "_", df$samplemethod[1], "_",df$model[1],"_", df$errormode)
    png(file=paste0(des, ".png"),width=900, height=500)
    b <- boxplot(mape ~ blocksize,data=tmpdf)
    title(paste0(comp," ",eb))
    print(b)
    dev.off()
  }
}

getBoxplotMAPE_CompBSEB <- function(df) {
  for (eb in unique(df$errorbound)) {
    for (comp in unique(df$compressor)) {
      boxplotMAPE_CompressorAndBSEB(df,comp,eb)
    }
  }
}

boxplotMAPE_CompressorAndBCEB <- function(df,comp,eb) {
  tmpdf <- df %>% filter(compressor == comp) %>% filter(errorbound == eb)
  if (nrow(tmpdf)) {
    des <- paste0(df$app[1],"_boxplot_bybc_", comp,"_", formatC(eb, format='e',digits=0), "_", df$samplemethod[1], "_",df$model[1],"_", df$errormode)
    png(file=paste0(des, ".png"),width=900, height=500)
    b <- boxplot(mape ~ blockcount,data=tmpdf)
    title(paste0(comp," ",eb))
    print(b)
    dev.off()
  }
}

getBoxplotMAPE_CompBCEB <- function(df) {
  for (eb in unique(df$errorbound)) {
    for (comp in unique(df$compressor)) {
      boxplotMAPE_CompressorAndBCEB(df,comp,eb)
    }
  }
}


boxplotRelerrByCompressorAndBS <- function(accdf,bs) {
  tmpdf <- accdf %>% filter(blocksize == bs)
  boxplot(relerr ~ compressor,data=tmpdf)
}

boxplotRelerr_CompressorAndBS <- function(accdf,comp) {
  tmpdf <- accdf %>% filter(compressor == comp)
  boxplot(relerr ~ blocksize,data=tmpdf)
}

filteredBoxplotRelerrByCompressorAndBS <- function(accdf,bs,thresh=200) {
  tmpdf <- accdf %>% filter(blocksize == bs) %>% filter(real < thresh)
  boxplot(relerr ~ compressor,data=tmpdf)
}

filteredBoxplotRelerr_CompressorAndBS <- function(accdf,comp,thresh=200) {
  tmpdf <- accdf %>% filter(compressor == comp) %>% filter(real < thresh)
  boxplot(relerr ~ blocksize,data=tmpdf)
}


getAccScatterByCompBS <- function(accdf,comp,bs) {
  tmpdf <- accdf %>% filter(blocksize == bs)
  ggplot(tmpdf, aes(x=pred,y=real)) +
    geom_point(aes(color=compressor)) +
    facet_wrap(~errorbound)
}

getAccScatter <- function(accdf,comp,eb) {
  tmpdf <- accdf %>% filter(compressor == comp) %>% 
    filter(errorbound == eb) %>% 
    #select(blocksize,files,real,pred) %>%
    group_by(files) %>%
    summarise("real"=mean(real),
              "pred"=mean(pred),
              "blocksize"=factor(blocksize)
    )
  
  ggplot(tmpdf, aes(x=pred,y=real)) +
    geom_point() +
    facet_wrap(~blocksize)
}

getAccScatterByCompEB <- function(accdf,comp,eb) {
  tmpdf <- accdf %>% filter(errorbound == eb)
  ggplot(tmpdf, aes(x=pred,y=real)) +
    geom_point(aes(color=as.character(blocksize))) +
    facet_wrap(~compressor)
}

getMapeScatterByCompEB <- function(fdf,comp,eb) {
  tmpdf <- fdf %>% filter(errorbound == eb)
  ggplot(tmpdf, aes(x=factor(blocksize),y=mape)) +
    geom_point(aes(color = compressor))
}

getAccScatterByCompBSEB <- function() {
  
}

scatter_relacc <- function(accdf) {
  
}


#library('ggridges')

plotHistDensityBox <- function(fdf,comp,bs) {
  tmpdf <- fdf %>% filter(compressor == comp) %>% filter(blocksize == bs)
  # Left
  ggplot(tmpdf, aes(x = ,mape)) +
    geom_histogram()
  
  # Middle
  ggplot(tmpdf, aes(x = mape)) +
    geom_density()
  
  # Right
  ggplot(tmpdf, aes(x = mape)) +
    geom_boxplot()
}

getStatPlot <- function(fdf,comp,eb) {
  tmpdf <- fdf %>% filter(compressor == comp) %>% filter(errorbound == eb)
  plt <- ggplot(tmpdf) +
    stat_summary(aes(x=factor(blocksize),y=mape),
                 fun.min=min,
                 fun.max=max,
                 fun=median) +
  labs(title=paste(comp,eb))
  print(plt)
  dev.off()
}
runStatPlot <- function(fdf) {
  for (comp in unique(fdf$compressor)) {
    for (eb in unique(fdf$errorbound)) {
      getStatPlot(fdf,comp,eb)
    }
  }
}

getBoxPlot <- function(fdf,comp,eb) {
  tmpdf <- fdf %>% filter(compressor == comp) %>% filter(errorbound==eb)
  if (nrow(tmpdf)) {
    plt <- ggplot(tmpdf,aes(x=mape)) + 
      geom_boxplot() +
      labs(title=paste(comp,eb)) +
      facet_wrap(~blocksize)
    print(plt)
  }
}

runBoxPlot <- function(fdf) {
  for (comp in unique(fdf$compressor)) {
    for (eb in unique(fdf$errorbound)) {
      getBoxPlot(fdf,comp,eb)
    }
  }
}

############################################################################################################
############################################################################################################


plotCoefficientsByCompBSBCEB <- function(accdf,comp,bs,bc,eb) {
  tmpdf <- accdf %>% filter(compressor == comp) %>% 
    filter(errorbound == eb)
  coefs <- unlist(tmpdf$coef)
  intIdx <- seq(from=1,to=length(unlist(tmpdf$coef)),by=4)
  intercept <- coefs[intIdx]
  x1 <- coefs[intIdx+1]
  x2 <- coefs[intIdx+2]
  x3 <- coefs[intIdx+3]
  tmp <- as.data.frame(cbind(tmpdf,intercept,x1,x2,x3))
  
  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) } 
  
  relerr <- (abs((tmpdf$pred - tmpdf$real) / tmpdf$real))*100
  stats_quantile(relerr)
  
  plot(tmpdf$real,tmpdf$pred);abline(0,1)
  
  ggplot(tmp, aes(x=blocksize,y=intercept)) +
    geom_point() +
    facet_wrap(~ errorbound)
}





recalculateMAPE <- function(accdf,thresh=200) {
  new_acc <- accdf %>% filter(real < thresh)
  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) } 
  bs_ <- c()
  bc_ <- c()
  comp_ <- c()
  eb_ <- c()
  mape_ <- c()
  meanape_ <- c()
  qr_ <- c()
  lower_ <- c()
  upper_ <- c()
  
  for (bs in unique(new_acc$blocksize)) {
    for (bc in unique(new_acc$blockcount)) {
      for (comp in unique(new_acc$compressor)) {
        for (eb in unique(new_acc$errorbound)) {
          tmpdf <- new_acc %>% filter(blocksize == bs) %>%
            filter(blockcount == bc) %>%
            filter(compressor == comp) %>%
            filter(errorbound == eb)
          
          if (!nrow(tmpdf)) { next }
          
          bs_ <- c(bs_,bs)
          bc_ <- c(bc_,bc)
          comp_ <- c(comp_,comp)
          eb_ <- c(eb_,eb)
          mape_ <- c(mape_, median(tmpdf$relerr))
          meanape_ <- c(meanape_,mean(tmpdf$relerr))
          rng <- stats_quantile(tmpdf$relerr)
          qr_ <- c(qr_, (rng[3]-rng[1]))
          lower_ <- c(lower_,rng[1])
          upper_ <- c(upper_,rng[3])
        }
      }
    }
  }
  new_fdf <- cbind(bs_,bc_,comp_,eb_,mape_,meanape_,qr_,lower_,upper_)
  new_fdf <- as.data.frame(new_fdf)
  colnames(new_fdf) <- c("blocksize","blockcount","compressor","errorbound","mape","meanAPE", "quartilerange","lowererr","uppererr")
  
  new_fdf$mape <- sapply(new_fdf$mape, as.numeric)
  new_fdf$meanAPE <- sapply(new_fdf$meanAPE, as.numeric)
  new_fdf$quartilerange <- sapply(new_fdf$quartilerange, as.numeric)
  new_fdf$uppererr <- sapply(new_fdf$uppererr, as.numeric)
  new_fdf$lowererr <- sapply(new_fdf$lowererr, as.numeric)
  new_fdf$blocksize <- sapply(new_fdf$blocksize, as.numeric)
  new_fdf$blockcount <- sapply(new_fdf$blockcount, as.numeric)
  new_fdf$errorbound <- sapply(new_fdf$errorbound, as.numeric)
  formatC(new_fdf$errorbound, format='e', digits=0)
  
  return (new_fdf)
}





