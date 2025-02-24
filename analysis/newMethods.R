makeFDFOtherMethods <- function(df, app) {
  fdf <- data.frame()
  
  for (mthd in unique(df$method)) {
    tmpdf <- df %>% filter(method == mthd)
    print(mthd)
    #print(unique(tmpdf$blocksize))
    #if(mthd == "khan2023_sz3") {
    #  print(paste("HELLO FROM METHOD", mthd))
    #  print(unique(tmpdf$blockcount))  
    #}
    #print(unique(tmpdf$blockcount))
    #print(unique(tmpdf$sampleratio))
    for (comp in unique(tmpdf$compressor)) {
      for (bs in unique(tmpdf$blocksize)) {
        for (bc in unique(tmpdf$blockcount)) {
          for (sr in unique(tmpdf$sampleratio)) {
            for (eb in unique(tmpdf$errorbound)) {
              newdf <- tmpdf %>% filter(compressor == comp) %>% filter(blocksize == bs) %>% filter(blockcount == bc) %>% filter(sampleratio == sr) %>% filter(errorbound == eb)
              mape <- median(newdf$relErr)
              if(mthd == "khan2023_sz3") {
                #print(newdf)
              }
              #if ((bs == 5) || (bc == 0)) { print(paste(app, bs, bc, comp, eb, mape, max(newdf$relErr), min(newdf$relErr), method)) }
              fdf <- rbind(fdf, c(app, bs, bc, sr, comp, eb, mape, min(newdf$relErr), max(newdf$relErr), mthd))
            }
          }
        }
      }
    }
  }
  colnames(fdf) <- c("app", "blocksize", "blockcount", "sampleratio", "compressor", "errorbound", "mape", "lowererr", "uppererr", "method")
  fdf$blocksize <- as.integer(fdf$blocksize)
  fdf$blockcount <- as.integer(fdf$blockcount)
  fdf$sampleratio <- as.numeric(fdf$sampleratio)
  fdf$errorbound <- as.numeric(fdf$errorbound)
  fdf$mape <- as.numeric(fdf$mape)
  fdf$lowererr <- as.numeric(fdf$lowererr)
  fdf$uppererr <- as.numeric(fdf$uppererr)
  
  return(fdf)
}

getStep48FDF <- function() {
  Step48 <- read.csv('step48.csv')
  hurricane_fields <- c("P","QSNOW","QGRAUP","QRAIN","QVAPOR","V","PRECIP","CLOUD","U","QICE","W","TC","QCLOUD")
  
  Step48$field = Step48$field + 1
  colnames(Step48)
  Step48$X <- NULL
  colnames(Step48)
  colnames(Step48) <- c("compressor","pred","method","fieldID","errorbound","blocksize","blockcount", "sampleratio", "filename")
  Step48$filename <- NULL
  Step48$field <- hurricane_fields[Step48$fieldID]
  
  hurricane_step48 <- unique(hurricane_global %>% filter(timestep == 48)) %>% filter(compressor != "tthresh")
  hurricane48 <- hurricane_step48[c("field","compressor","errorbound","real")]
  Step48 <- merge(x=Step48,y=hurricane48,by=c("field","compressor","errorbound"))
  
  Step48$blocksize <- as.integer(Step48$blocksize)
  Step48$blockcount <- as.integer(Step48$blockcount)
  Step48$errorbound <- as.numeric(Step48$errorbound)
  Step48$sampleratio <- as.numeric(Step48$sampleratio)
  Step48$sampleratio <- (Step48$sampleratio) * 100
  
  Step48$relErr <- abs((Step48$pred - Step48$real)/Step48$real) * 100
  
  Step48 <- Step48 %>% filter(real <= 200)
  priorStep48FDF <- makeFDFOtherMethods(Step48, "hurricane_step48")
  
  #newMethods["mape"][sapply(newMethods["mape"], is.infinite)] <- NA
  #newMethods <- na.omit(newMethods)
  
  tao_step48 <- priorStep48FDF %>% filter(method == "tao2019")
  sian_step48 <- priorStep48FDF %>% filter(method == "sian2022")
  khan_sz3_step48 <- priorStep48FDF %>% filter(method == "khan2023_sz3")
  khan_zfp_step48 <- priorStep48FDF %>% filter(method == "khan2023_zfp")
  
  return(priorStep48FDF)
}

getStep48RawResults <- function() {
  Step48 <- read.csv('step48_timing.csv')
  hurricane_fields <- c("P","QSNOW","QGRAUP","QRAIN","QVAPOR","V","PRECIP","CLOUD","U","QICE","W","TC","QCLOUD")
  
  Step48$field = Step48$field + 1
  colnames(Step48)
  Step48$X <- NULL
  colnames(Step48)
  colnames(Step48) <- c("compressor","pred","method","fieldID","errorbound","blocksize","blockcount","sampleratio", "filename", "metric_name")
  Step48 <- Step48 %>% filter(metric_name == "/pressio/time:time:begin_compress")
  Step48$filename <- NULL
  Step48$field <- hurricane_fields[Step48$fieldID]
  
  hurricane_step48 <- unique(hurricane_global %>% filter(timestep == 48)) %>% filter(compressor != "tthresh")
  hurricane48 <- hurricane_step48[c("field","compressor","errorbound","real")]
  Step48 <- merge(x=Step48,y=hurricane48,by=c("field","compressor","errorbound"))
  
  Step48$blocksize <- as.integer(Step48$blocksize)
  Step48$blockcount <- as.integer(Step48$blockcount)
  Step48$errorbound <- as.numeric(Step48$errorbound)
  Step48$sampleratio <- as.numeric(Step48$sampleratio)
  Step48$sampleratio <- (Step48$sampleratio) * 100
  #Step48$sampleratio <- round(Step48$sampleratio, digits=2)
  
  Step48 <- Step48 %>% filter(real <= 200)
  Step48$relErr <- abs((Step48$pred - Step48$real)/Step48$real) * 100
  
  return(Step48)
}

getCloudFDF <- function() {
  
  Cloud <- read.csv('cloud.csv')
  cloud_fields <- c(42,	45,	39,	37,	30,	05,	02,	13,	14,	21,	26,	28,	03,	04,	31,	36,	44,	38,	43,	29,	27,	20,	15,	12,	23,	24,	11,	16,	18,	09,	07,	35,	32,	40,	47,	19,	17,	10,	25,	22,	46,	41,	33,	48,	34,	01,	06,	08)
  #cloud_fields <- paste0("CLOUDf", cloud_fields)
  
  Cloud$field = Cloud$field + 1
  colnames(Cloud)
  Cloud$X <- NULL
  colnames(Cloud)
  colnames(Cloud) <- c("compressor","pred","method","fieldID","errorbound","blocksize","blockcount", "sampleratio", "filename")
  
  Cloud$filename <- NULL
  Cloud$field <- cloud_fields[Cloud$fieldID]
  
  
  hurricane_cloud <- unique(hurricane_global %>% filter(field == "CLOUD")) %>% filter(compressor != "tthresh")
  hurricaneCloud <- hurricane_cloud[c("timestep","compressor","errorbound","real")]
  colnames(hurricaneCloud) <- c("field","compressor","errorbound","real")
  Cloud <- merge(x=Cloud,y=hurricaneCloud,by=c("field","compressor","errorbound"))
  
  Cloud$field <- paste0("CLOUD", Cloud$field)
  
  Cloud$blocksize <- as.integer(Cloud$blocksize)
  Cloud$blockcount <- as.integer(Cloud$blockcount)
  Cloud$errorbound <- as.numeric(Cloud$errorbound)
  Cloud$sampleratio <- as.numeric(Cloud$sampleratio)
  Cloud$sampleratio <- (Cloud$sampleratio) * 100
  
  Cloud <- Cloud %>% filter(real <= 200)
  Cloud$relErr <- abs((Cloud$pred - Cloud$real)/Cloud$real) * 100
  
  priorCloudFDF <- makeFDFOtherMethods(Cloud, "hurricane_cloud")
  
  priorCloudFDF["mape"][sapply(priorCloudFDF["mape"], is.infinite)] <- NA
  priorCloudFDF <- na.omit(priorCloudFDF)
  
  tao_cloud <- priorCloudFDF %>% filter(method == "tao2019")
  sian_cloud <- priorCloudFDF %>% filter(method == "sian2022")
  khan_sz3_cloud <- priorCloudFDF %>% filter(method == "khan2023_sz3")
  khan_zfp_cloud <- priorCloudFDF %>% filter(method == "khan2023_zfp")
  
  return(priorCloudFDF)
}

getCloudRawResults <- function() {
  Cloud <- read.csv('cloud.csv')
  cloud_fields <- c(42,	45,	39,	37,	30,	05,	02,	13,	14,	21,	26,	28,	03,	04,	31,	36,	44,	38,	43,	29,	27,	20,	15,	12,	23,	24,	11,	16,	18,	09,	07,	35,	32,	40,	47,	19,	17,	10,	25,	22,	46,	41,	33,	48,	34,	01,	06,	08)
  #cloud_fields <- paste0("CLOUDf", cloud_fields)
  
  Cloud$field = Cloud$field + 1
  colnames(Cloud)
  Cloud$X <- NULL
  colnames(Cloud)
  colnames(Cloud) <- c("compressor","pred","method","fieldID","errorbound","blocksize","blockcount", "sampleratio", "filename")
  Cloud$filename <- NULL
  Cloud$field <- cloud_fields[Cloud$fieldID]
  
  hurricane_cloud <- unique(hurricane_global %>% filter(field == "CLOUD")) %>% filter(compressor != "tthresh")
  hurricaneCloud <- hurricane_cloud[c("timestep","compressor","errorbound","real")]
  colnames(hurricaneCloud) <- c("field","compressor","errorbound","real")
  Cloud <- merge(x=Cloud,y=hurricaneCloud,by=c("field","compressor","errorbound"))
  
  Cloud$field <- paste0("CLOUD", Cloud$field)
  
  Cloud$blocksize <- as.integer(Cloud$blocksize)
  Cloud$blockcount <- as.integer(Cloud$blockcount)
  Cloud$errorbound <- as.numeric(Cloud$errorbound)
  Cloud$sampleratio <- as.numeric(Cloud$sampleratio)
  Cloud$sampleratio <- (Cloud$sampleratio) * 100
  
  Cloud <- Cloud %>% filter(real <= 200)
  Cloud$relErr <- abs((Cloud$pred - Cloud$real)/Cloud$real) * 100
  
  return(Cloud)
}

priorScatterByEB <- function(df, app,iqr=0) {
  if(df$sampleratio[1] != 0) { #khan_zfp
    xval = "sampleratio"; xlab = "Sample ratio (%)"; 
    ht=4; wdth=10; 
    df$sampleratio <- round(df$sampleratio, digits=2) 
  } 
  else if(df$blocksize[1] == 0) { xval = "blockcount"; xlab = "Stride"; ht=3; wdth=6 } # khan_sz3
  else { xval = "blocksize"; xlab = "Block size"; ht=2; wdth=4} #sian
  
  if(df$sampleratio[1] == 0) {
    df[[xval]] <- as.factor(df[[xval]])  
  }
  df$iqr <- df$uppererr - df$lowererr
  df$iqr <- round(df$iqr,digits=2)
  
  des <- paste0('img/priorwork/',df$method[1],"_",df$compressor[1], "_") 
  if(iqr) { des <- paste0(des, "IQR_"); ht=4; wdth=15 }
  des <- paste0(des, app, "_scatter.pdf")
  
  #des <- paste0('img/priorwork/',df$method,"_",df$compressor[1], "_", app, "_scatter.pdf")
  plt <- ggplot(df, aes((.data[[xval]]),mape,color=(factor(formatC(errorbound,format='e',digits=0))))) + 
    geom_point(size=2.0) + 
    labs(color="Error bound") + 
    labs(x = xlab) 
    #geom_text(aes(label=iqr), vjust=-.75)
  if(iqr) {
    plt <- plt + geom_errorbar(aes(group = xval, ymax = uppererr, ymin = lowererr),width=0.25)
  }
  
  pdf(des,
      height=ht,
      width=wdth)
  print(plt)
  dev.off()
}

library(ggpubr)
priorBarByEB <- function(df, app, iqr=0) {
  #if(df$sampleratio[1] != 0) { xval = "sampleratio"; xlab = "Sample ratio (%)"; ht=3; wdth=10}
  if(df$blocksize[1] == 0) { xval = "blockcount"; xlab = "Stride"; ht=3; wdth=10 } 
  else { xval = "blocksize"; xlab = "Block size"; ht=3; wdth=10}
  
  df[[xval]] <- as.factor(df[[xval]])
  df$errorbound <- as.factor(formatC(df$errorbound,format='e',digits=0))
  df$iqr <- df$uppererr - df$lowererr
  df$iqr <- round(df$iqr,digits=2)
  
  des <- paste0('img/priorwork/',df$method[1],"_",df$compressor[1], "_") 
  if(iqr) { des <- paste0(des, "IQR_") }
  des <- paste0(des, app, "_bar.pdf")
  
  plt <- ggplot(df, aes(x=.data[[xval]], y=mape, fill=errorbound)) +
    geom_bar(position=position_dodge(), stat="identity", colour='black') +
    geom_errorbar(aes(ymin=lowererr, ymax=uppererr), width=.2,position=position_dodge(.9)) +
    labs(fill="Error bound") +
    xlab(xlab) +
    ylab("MAPE") +
    ggtitle(paste(df$method[1], "prediction error and IQR for", app, "data"))
    #labs(yval="MAPE")
    
  pdf(des,
      height=ht,
      width=wdth)
  print(plt)
  dev.off()
}

priorScatterRealVsPred <- function(df,app,ylim=0,log=0) {
  dir <- 'img/priorwork/'
  ht=4; wdth=6
  
  if(df$sampleratio[1] != 0) { xval = "errorbound"; xlab = "Error bound"}
  else if(df$blocksize[1] == 0) { xval = "blockcount"; xlab = "Block count"; } 
  else { xval = "blocksize"; xlab = "Block size"; }
  
  df$errorbound <- as.factor(formatC(df$errorbound,format='e',digits=0))
  if(df$sampleratio[1] == 0) {df[[xval]] <- as.factor(df[[xval]])}
  
  xlab <- "Error bound"
  
  if(log) { 
    #plt <- ggplot(df,aes(x=log(real),y=log(pred),colour=.data[[xval]], shape=errorbound), scales="fixed")
    plt <- ggplot(df,aes(x=log(real),y=log(pred), color=errorbound), scales="fixed")
    des <- paste0('img/priorwork/',df$method[1],"_",df$compressor[1], "_", app, "_realVsPred_log.pdf")
  } else {
    plt <- ggplot(df,aes(x=real,y=pred,colour=.data[[xval]], shape=errorbound), scales="fixed") 
    des <- paste0('img/priorwork/',df$method[1],"_",df$compressor[1], "_", app, "_realVsPred.pdf")
  }
  
  plt <- plt + 
    geom_point(alpha=0.5) +
    ggtitle(paste(df$method[1], "real vs predicted for", app, "data")) +
    labs(color=xlab) +
    labs(shape="Error bound") +
    labs(shape="Error bound") +
    geom_abline(slope=1) 
    #guides(colour=guide_legend(ncol=2))
    #coord_fixed() 
    #facet_wrap(~errorbound,ncol=length(unique(df$errorbound))) +
  
  if (ylim) { plt <- plt + lims(y=c(0,ylim)) }
  
  pdf(des,
      height=ht,
      width=wdth)
  print(plt)
  dev.off()
}

priorScatterRealVsPred_multiMethod <- function(df,app,ylim=0,log=0) {
  dir <- 'img/priorwork/'
  ht=2; wdth=7
  
  xval = "errorbound"; xlab = "Error bound"
  
  df$author <- paste0("(",df$author," et al.)")
  
  df$compressor <- toupper(df$compressor)
  
  df$compressor <- paste(df$compressor, df$author)
  
  df$errorbound <- as.factor(formatC(df$errorbound,format='e',digits=0))
  #if(df$sampleratio[1] == 0) {df[[xval]] <- as.factor(df[[xval]])}
  
  if(log) { 
    plt <- ggplot(df,aes(x=log(real),y=log(pred),colour=.data[[xval]]), scales="fixed")
    des <- paste0('img/priorwork/priormethods_', app, "_realVsPred_log.pdf")
  } else {
    plt <- ggplot(df,aes(x=real,y=pred,colour=.data[[xval]]), scales="fixed") 
    des <- paste0('img/priorwork/priormethods_', app, "_realVsPred.pdf")
  }
  plt <- plt + 
    geom_point(alpha=0.2) +
    facet_wrap(~compressor,ncol=length(unique(df$compressor)), scales="fixed") +
    labs(color="Error bound") +
    #labs(shape="Error bound") +
    #ggtitle(paste(df$method[1], "real vs predicted for", app, "data")) +
    geom_abline(slope=1) +
    #guides(colour=guide_legend(ncol=1))
  #coord_fixed() 
  #facet_wrap(~errorbound,ncol=length(unique(df$errorbound))) +
  
  if (ylim) { plt <- plt + lims(y=c(0,ylim)) }
  
  pdf(des,
      height=ht,
      width=wdth)
  print(plt)
  dev.off()
}





