

### extract data 

extract_cr_predictors <- function(data, error_mode, error_bnd, comp_thresh=200){
  data_orig <- filter(data, info.bound_type == error_mode)
  data0 <- filter(data_orig, info.error_bound==error_bnd)
  ###
  if (error_mode == 'pressio:abs'){
    compressor0 <- c("zfp", "mgard", "bit_grooming","digit_rounding") }
  if (error_mode == 'pressio:rel'){
    compressor0 <- c("zfp", "mgard") }
  ###
  list_df_cr <- NULL
  for(i in 1:length(compressor0)){
    vx_compressor <- filter(data0, info.compressor == compressor0[i])
    indsz <- which(as.numeric(vx_compressor$size.compression_ratio)<=comp_thresh)

    ## local per block stats
    # qentropy
    qent0 <- as.numeric(vx_compressor$stat.qentropy)[indsz]
    qent0[qent0==0] <- 1e-8
    qent <- qent0
    # svd
    vargm <- as.numeric(vx_compressor$stat.n99[indsz])
    # std
    std <- as.numeric(vx_compressor$error_stat.value_std[indsz])
    std[is.na(std)] <- 1e-8
    vrgstd0 <- vargm/std
    vrgstd <- log(vrgstd0)
    # compression ratio local
    cr <- as.numeric(vx_compressor$size.compression_ratio)[indsz]

    ## global stats
    # compression raio global
    cr_global <- as.numeric(vx_compressor$global.compression_ratio)[indsz]
    # global std
    std_global <- as.numeric(vx_compressor$global.value_std[indsz])
    std_global[is.na(std_global)] <- 1e-8

    # distances
    x <- as.numeric(vx_compressor$block.loc1[indsz])
    y <- as.numeric(vx_compressor$block.loc2[indsz])
    z <- as.numeric(vx_compressor$block.loc3[indsz])
    loc0 <- cbind(x,y,z)
    # loc <- dist(loc0)
    loc <- x


    df <- data.frame(cr, qent, vrgstd, vargm, std, cr_global, std_global, loc)
    indqna <- which(is.na(qent))
    if (length(indqna)>1) {df <- df[-indqna,]}
    list_df_cr[[compressor0[i]]] <- df  }
  ###
  vx_compressor <- filter(data0, info.compressor == 'sz')
  indsz <- which(as.numeric(vx_compressor$size.compression_ratio)<=comp_thresh)
  #indsz <- which(is.na(vx_compressor$sz.constant_flag[indsz]))
  #
  qent0 <- as.numeric(vx_compressor$stat.qentropy)[indsz]
  qent0[qent0==0] <- 1e-8
  qent <- qent0
  #
  vargm <- as.numeric(vx_compressor$stat.n99)[indsz]
  std <- as.numeric(vx_compressor$error_stat.value_std)[indsz]
  std[is.na(std)] <- 1e-8
  vrgstd0 <- vargm/std
  vrgstd <- log(vrgstd0)
  #
  cr <- as.numeric(vx_compressor$size.compression_ratio)[indsz]
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df <- df[-indqna,]}
  #
  reg_per <- as.numeric(vx_compressor$sz.regression_blocks)[indsz]
  reg_per[is.na(reg_per)] <- 0
  lor_per <- as.numeric(vx_compressor$sz.lorenzo_blocks)[indsz]
  lor_per[is.na(lor_per)] <- 0
  reg_per <- round(100*reg_per/max(reg_per,lor_per),2)

  

  ## global stats
  # compression raio global
  cr_global <- as.numeric(vx_compressor$global.compression_ratio)[indsz]
  # global std
  std_global <- as.numeric(vx_compressor$global.value_std[indsz])
  std_global[is.na(std_global)] <- 1e-8

  # distances
  x <- as.numeric(vx_compressor$block.loc1[indsz])
  y <- as.numeric(vx_compressor$block.loc2[indsz])
  z <- as.numeric(vx_compressor$block.loc3[indsz])
  loc0 <- cbind(x,y,z)
  loc <- x
  
  df <- data.frame(cr, qent, vrgstd, vargm, std, reg_per, cr_global, std_global, loc) 
  #
  list_df_cr[['sz']] <- df
  compressors <- c(compressor0, 'sz2')

  
  return(list(df=list_df_cr, compressors=compressors, mode=error_mode, bound=error_bnd))
}



###  evaluation metrics

RelMAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMeanAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMaxAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }



### prediction functions


cr_blocking_model <- function(df, kf=8, data_nm, compressor_nm, error_mode, error_bnd, block_count=block_count, block_size=block_size, print_stats=1){
  indsz <- which(df$cr_global<=comp_thresh)
  df <- df[indsz,]

  qent0 <- df$qent
  qent <- (log(qent0)-min(log(qent0),na.rm=TRUE))/(max(log(qent0),na.rm=TRUE)-min(log(qent0),na.rm=TRUE))
  vrgstd0 <- df$vrgstd
  vrgstd <- ((vrgstd0)-min((vrgstd0),na.rm=TRUE))/(max((vrgstd0),na.rm=TRUE)-min((vrgstd0),na.rm=TRUE))
 
  #local per block 
  std_local0 <- df$std
  std_local <- ((std_local0)-min((std_local0),na.rm=TRUE))/(max((std_local0),na.rm=TRUE)-min((std_local0),na.rm=TRUE))

  cr_local <- log(df$cr)

  loc_inter <- df$loc



  #global stats
  y <- log(df$cr_global) # y values is the global compression ratio
  std_global0 <- df$std_global
  std_global <- ((std_global0)-min((std_global0),na.rm=TRUE))/(max((std_global0),na.rm=TRUE)-min((std_global0),na.rm=TRUE))
  
  

  df_reg <- data.frame(y, std_global, std_local, cr_local, loc_inter)
  indqna <- which(is.na(qent))

  if (length(indqna)>1) {df_reg <- df_reg[-indqna,]}
  if (nrow(df_reg) == 0){
    print(paste("model fails: ", compressor_nm, error_mode, error_bnd))
  }
  
  fold <- floor(runif(nrow(df_reg),1,(kf+1)))
  df_reg$fold <- fold
  cv_cor <- c() ; cv_mape <- c() 
  cv_compression <- c()
  pred_list <- c()
  ytest_list <- c()
  vtest_list <- c()

   for (l in 1:kf){
    test.set <- df_reg[df_reg$fold == l,]
    train.set <- df_reg[df_reg$fold != l,]
    mi <- lm(y~1 + loc_inter*cr_local + std_local*cr_local + loc_inter*std_local*cr_local, data = train.set)
    print(summary(mi))


    predi <- predict(mi, newdata=test.set)
    #
    cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(predi))
    cv_compression[l] <- c(mean(test.set$y), mean(predi))
    cv_cor[l] <- cor(exp(test.set$y),exp(predi))
    #
    pred_list[[l]] <- exp(predi)
    ytest_list[[l]] <- exp(test.set$y) 
    vtest_list[[l]] <- test.set$vrgstd   }

  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) } 
  res_cv <- cbind(probs, stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Quantile', 'Corr','MedAPE')
  if (print_stats == 1){
    csv_res_cv <- cbind(res_cv, block_count, block_size, compressor_nm, error_mode, error_bnd, data_nm, mean(test.set$y), mean(predi))
    colnames(csv_res_cv) <- c('Quantile', 'Corr', 'MedAPE', 'Block_Count', 'Block_Size', 'Compressor', 'Error_mode', 'Error_bound', 'Data_name', 'CR actual', 'CR estimate')
    if (file.exists("apples.csv")) {
      write.table(csv_res_cv, "apples.csv", sep=',', col.names=FALSE, row.names=FALSE, append=TRUE)
    } else {
      write.table(csv_res_cv, "apples.csv", sep=',', col.names=TRUE, row.names=FALSE)
    }
  }
  
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)),res_cv=res_cv))
}


