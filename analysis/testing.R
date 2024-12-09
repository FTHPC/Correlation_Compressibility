
library('fields')

### compute loc (Arkas locality metric)
get_loc <-function(data, cutoff, new_way){
  
  start_time <- Sys.time()
  
  df <- data.frame( data$info.filename, 
                    data$block.method, 
                    data$block.loc1,
                    data$block.loc2,
                    data$block.loc3)
  
  df <- df[1:cutoff,]
  #df
  
  df_uni <- unique(df) # exclude repeats
  df_group <- df_uni %>% group_by(df_uni$data.info.filename, df_uni$data.block.method)
  lx <- as.numeric(df_group$data.block.loc1)
  ly <- as.numeric(df_group$data.block.loc2)
  lz <- as.numeric(df_group$data.block.loc3)
  loc0 <- data.frame(lx,ly,lz)

  loc <- c()
  
  distmtx <- rdist(loc0)
  distmtx[distmtx==0] <- 1e-8
  l1norm <- as.matrix(dist(loc0, method='manhattan', upper=TRUE,diag=TRUE))
  
  if (new_way) {
    for (j in 1:nrow(loc0)) {
      loc[j] <- sum(l1norm[,j] / distmtx[,j]) / sum(l1norm[,j])
    }
  }
  else { #old_way
    for (j in 1:nrow(loc0)) {
      numer_sum <- 0
      denom_sum <- 0
      # first point
      Bb <- loc0[j,]
      for (k in 1:nrow(loc0)) {
        if (!identical(loc0[j,],loc0[k,])) {
          # second point
          Bb_prime <- loc0[k,]
          posbb <- abs(Bb$lx - Bb_prime$lx) + abs(Bb$ly - Bb_prime$ly) + abs(Bb$lz - Bb_prime$lz)
          distance <- sqrt((Bb$lx - Bb_prime$lx)^2 + (Bb$ly - Bb_prime$ly)^2 + (Bb$lz - Bb_prime$lz)^2)
          
          distance[distance==0] <- 1e-8 
          numer_sum <- numer_sum +(posbb / distance)
          denom_sum <- denom_sum + posbb
        }
      }
      loc[j] <- numer_sum / denom_sum
    }
  }
  inner <- data.frame(df_uni, loc)
  ### JOIN on column unique identifiers
  df_final <- merge(x = data, y = inner,
                    by.x=c("info.filename","block.method", "block.loc1", "block.loc2", "block.loc3"), 
                    by.y=c("data.info.filename","data.block.method", "data.block.loc1", "data.block.loc2", "data.block.loc3"))
  
  
  end_time <- Sys.time()
  print(end_time - start_time)
  
  return(df_final)
}

#limited <- filter[sample(nrow(filter),limit_count),]

### limits amount of data based on limit_count
sel_dat <- function(data, limit_count, comps, bnds, modes){
  limited_df <- data.frame()
  for (comp in comps) {
    for (error_bnd in bnds){ 
      for (error_mode in modes){
        filtered <- data %>% 
          filter(info.bound_type == error_mode) %>% 
          filter(info.error_bound == error_bnd) %>% 
          filter(info.compressor == comp)
        
        ### limit filtered combination based on block count
        ### NAIVE IMPLEMENTATION (TAKING FIRST N BLOCKS FROM EACH GLOBAL BUFFER)
        ifelse(nrow(filtered) < limit_count, limited <- filtered, limited <- slice_sample(filtered, n=limit_count)) 
        
        ### merge filtered back to df
        limited_df <- rbind(limited_df, limited)
      }
    }
  }
  return(limited_df)
}

### extract data 
extract_cr_pred <- function(data, error_mode, error_bnd, compressor, comp_thresh=200){
  ### grab selection of data based on unqiue combination of mode, bound, and compressor
  vx_compressor <- data_loc %>%
                    filter(info.bound_type == error_mode) %>%
                    filter(info.error_bound == error_bnd) %>%
                    filter(info.compressor == compressor) %>%
                    filter(size.compression_ratio <= comp_thresh)

  indsz <- which(as.numeric(vx_compressor$size.compression_ratio)<=comp_thresh)

  ## local per block stats
  # qentropy
  qent <- as.numeric(vx_compressor$stat.qentropy)
  qent[qent==0] <- 1e-8

  # svd
  vargm <- as.numeric(vx_compressor$stat.n99)
  
  # std
  std <- as.numeric(vx_compressor$error_stat.value_std)
  std[is.na(std)] <- 1e-8
  vrgstd0 <- vargm/std
  vrgstd <- log(vrgstd0)
  
  # compression ratio local
  cr_local <- as.numeric(vx_compressor$size.compression_ratio)
  
  ## global stats
  cr_global <- as.numeric(vx_compressor$global.compression_ratio)
  
  # global std
  std_global <- as.numeric(vx_compressor$global.value_std)
  std_global[is.na(std_global)] <- 1e-8
  
  # distances
  loc <- vx_compressor$loc
  
  #file identfier
  file <- vx_compressor$info.filename
  
  df <- data.frame(cr_local, qent, vrgstd, vargm, std, cr_global, std_global, loc, file)
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df <- df[-indqna,]}
  
  return(df)
}



misc_stuff <- function() {
  
  library('reshape2')
  library('tidyverse')
  library("lattice")
  
  hm_title <- paste0(comp, " ", error_bnd, " ", error_mode)
  
  tmpdf <- cbind(res_blockcount,res_blocksize)
  tmpdf <- expand.grid(X=res_blocksize,Y=res_blockcount)
  tmpdf$res_mape <- res_mape
  levelplot(res_mape ~ X * Y, data=tmpdf)
  
  tmpdf <- cbind(res_blockcount,res_blocksize,res_mape)
  tmpdf <- as.data.frame(tmpdf)
  tmpdf <- dcast(tmpdf,res_blockcount ~ res_blocksize, value.var="res_mape")
  row.names(tmpdf) <- tmpdf$res_blockcount
  tmpdf[1] <- NULL
  levelplot(as.matrix(tmpdf))
  
  tmpdf <-as.matrix(tmpdf)
  heatmap(as.matrix(tmpdf), Rowv=NA, Colv=NA,scale="row",xlab="block size", ylab="block count", main=hm_title, cex.main=1)
  legend(x="bottomright", legend=c("min", "avg", "max"), fill=heat.colors(3))
  
  ggp <- ggplot(as.data.frame(tmpdf), aes(res_blockcount, res_blocksize)) + geom_tile(aes(fill = res_mape))
  ggp + scale_fill_gradient(low = "green", high = "black")
  
  #library('plotly')

}






tmpdf <- cbind(filtered_df$res_blockcount,filtered_df$res_blocksize)
tmpdf <- expand.grid(X=res_blocksize,Y=res_blockcount)
colnames(tmpdf) <- c("res_blockcount", "res_blocksize")
tmpdf$res_mape <- filtered_df$res_mape
levelplot(res_mape ~ X * Y, data=tmpdf)



tmpdf <- cbind(filtered_df$res_blockcount,filtered_df$res_blocksize, filtered_df$res_mape)
tmpdf <- as.data.frame(tmpdf)
colnames(tmpdf) <- c("res_blockcount", "res_blocksize", "res_mape")
tmpdf <- tmpdf %>% arrange(block_count)
heatmap(as.matrix(tmpdf), Rowv=NA, Colv=NA,scale="row",xlab="block size", ylab="block count", main=hm_title, cex.main=1)
legend(x="bottomright", legend=c("min", "avg", "max"), fill=heat.colors(3))

ggp <- ggplot(as.data.frame(tmpdf), aes(res_blockcount, res_blocksize)) + geom_tile(aes(fill = res_mape))
ggp #+ scale_fill_gradient(low = "green", high = "black")

#library('plotly')



#plot(exp(cr_pred), exp(cr_real), xlab="predicted CR", ylab="actual CR", pch=16,
#     main=paste(compressor, error_mode, "eb:", error_bnd, "bc:", block_count, "bs:", block_size, sep=" ")); abline(lm(exp(cr_real)~exp(cr_pred)))

#df_par(mfrow=c(1,1))
#plot(cr_pred, cr_real, xlab="log(predicted CR)", ylab="log(actual CR)", pch=16,
#     main=paste(compressor, error_mode, "eb:", error_bnd, "bc:", block_count, "bs:", block_size, sep=" ")); abline(lm(cr_real~cr_pred))
#plot(exp(cr_pred), exp(cr_real), xlab="predicted CR", ylab="actual CR", pch=16,
#     main=paste(compressor, error_mode, "eb:", error_bnd, "bc:", block_count, "bs:", block_size, sep=" ")); abline(lm(exp(cr_real)~exp(cr_pred)))
#plot(exp(fitvals),stndres, xlab="fitted values", ylab="standardized residuals", col=stndres_colors, pch=16, 
#     main=paste(compressor, error_mode, error_bnd, "bc:", block_count, "bs:", block_size, sep=" ")); abline(0,0);
#qqPlot(stndres)


#plot(exp(mi$fitted.values),rstandard(mi), xlab="fitted values", ylab="standardized residuals", pch=16, main=paste(compressor, error_mode, error_bnd, "bc:", block_count, "bs:", block_size, sep=" ")); abline(0,0);








