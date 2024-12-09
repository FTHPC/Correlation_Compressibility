### read data
read_data <-function(app, block_size){
  name <- paste0("outputs/",app,"*blocks128", "_block_size", block_size, "*.csv")
  filename <- Sys.glob(name)
  print(filename)
  
  data <- read.csv(filename)
  data <- as.data.frame(data)
  
  data$size.compression_ratio <- as.numeric(data$size.compression_ratio)
  data$error_stat.value_std <- as.numeric(data$error_stat.value_std)
  data$error_stat.value_std[is.na(data$error_stat.value_std)] <- 1e-8
  data$error_stat.value_std[data$error_stat.value_std == 0] <- 1e-8
  
  data$global.compression_ratio <- as.numeric(data$global.compression_ratio)
  data$global.value_std <- as.numeric(data$global.value_std)
  data$global.value_std[is.na(data$global.value_std)] <- 1e-8
  data$global.value_std[data$global.value_std == 0] <- 1e-8
  data$block.number <- as.integer(data$block.number)
  
  return(data)
}

### limits amount of data based on limit_count
select_data <- function(data, block_count, global_buffers, comps, bnds, modes, samplemode){
  if (samplemode == "STRIDE") {
    return(select_data_stride(data,block_count,global_buffers,comps,bnds,modes))
  }
  if (samplemode == "UNIFORM") {
    return(select_data_uniform(data, block_count, global_buffers,comps,bnds,modes))
  }
}

### selects 'block_count' samples across each buffer at equal intervals
select_data_stride <- function(data, block_count, global_buffers, comps, bnds, modes){
  limited_df <- data.frame()
  for (comp in comps) {
    for (error_bnd in bnds){ 
      for (error_mode in modes){
        filtered <- data %>% 
          filter(info.bound_type == error_mode) %>% 
          filter(info.error_bound == error_bnd) %>% 
          filter(info.compressor == comp)
        
        ### limit filtered combination based on block count
        #filtering out tthresh and digit_rounding
        if (nrow(filtered) == 0) { next }
        if (length(unique(filtered$info.filename)) < global_buffers) { next }
        #make sure 'block_count' blocks are sampled
        if (max(filtered$block.number) < block_count) { next }
        
        #sample each file in the dataset 'block_count' times at equal invervals
        stride <- floor(max(filtered$block.number)/block_count)
        subsample <- seq(from=1, to=max(filtered$block.number), by=stride)
        subsample <- subsample[1:block_count]
        df <- filtered %>% filter(block.number %in% subsample)
        limited_df <- rbind(limited_df, df)
      }
    }
  }
  return(limited_df)
}

### selects 'block_count' samples uniformly across each buffer
select_data_uniform <- function(data, block_count, global_buffers, comps, bnds, modes){
  if (data$block.total_count[1] < block_count) {}
  subsample <- sample(1:data$block.total_count[1],block_count,FALSE)
  limited_df <- data.frame()
  for (comp in comps) {
    for (error_bnd in bnds){ 
      for (error_mode in modes){
        filtered <- data %>% 
          filter(info.bound_type == error_mode) %>% 
          filter(info.error_bound == error_bnd) %>% 
          filter(info.compressor == comp)
        
        ### limit filtered combination based on block count
        #filtering out tthresh and digit_rounding
        if (nrow(filtered) == 0) { 
          errmsg <- paste0(comp,",",error_mode,",",error_bnd, " does not have sufficient data points. skipping.")
          print(errmsg)
          next 
        }
        if (length(unique(filtered$info.filename)) < global_buffers) { 
          errmsg <- paste0(comp,",", error_mode,",",error_bnd," does not have sufficient buffers skipping.")
          print(errmsg)
          next 
        }
        #make sure 'block_count' blocks are sampled
        if (max(filtered$block.number) < block_count) { 
          errmsg <- paste0(comp,",", error_mode, ",", error_bnd," does not have sufficient block samples. skipping.")
          print(errmsg)
          next
        }
        
        #uniformly sample each file in the dataset 'block_count' times
        df <- filtered %>% filter(block.number %in% subsample)
        limited_df <- rbind(limited_df, df)
      }
    }
  }
  return(limited_df)
}

### selects random subsample of data across buffers - not yet implemented 
select_data_random <- function(data, block_count, global_buffers, comps, bnds, modes){
  limited_df <- data.frame()
  for (comp in comps) {
    for (error_bnd in bnds){ 
      for (error_mode in modes){
        filtered <- data %>% 
          filter(info.bound_type == error_mode) %>% 
          filter(info.error_bound == error_bnd) %>% 
          filter(info.compressor == comp)
        
        ### limit filtered combination based on block count
        #probably need better checks than this but should do for now
        if (nrow(filtered) == 0) { next }
        #make sure every file can be sampled
        if (length(unique(filtered$info.filename)) < global_buffers) { next }
        #make sure block_count blocks are sampled
        if (max(filtered$block.number) < block_count) { next }
        
        #randomly sample each file in the dataset block_count times
        ##TODO select subsample
        df <- filtered %>% filter(block.number %in% subsample)
        limited_df <- rbind(limited_df, df)
      }
    }
  }
  return(limited_df)
}

### compute loc (Arkas locality metric)
compute_loc <-function(data){
  #start_time <- Sys.time()
  df <- data.frame( data$info.filename, 
                    data$block.method, 
                    data$block.loc1,
                    data$block.loc2,
                    data$block.loc3)

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
  for (j in 1:nrow(loc0)) {
    loc[j] <- sum(l1norm[,j] / distmtx[,j]) / sum(l1norm[,j])
  }  
  inner <- data.frame(df_uni, loc)  
  ### JOIN on column unique identifiers
  df_final <- merge(x = data, y = inner,
                by.x=c("info.filename","block.method", "block.loc1", "block.loc2", "block.loc3"), 
                by.y=c("data.info.filename","data.block.method", "data.block.loc1", "data.block.loc2", "data.block.loc3"))

  return(df_final)
}

### extract data 
## grab selection of data based on unqiue combination of mode, bound, and compressor
extract_cr_predictors <- function(data, error_mode, error_bnd, comp, thresh=200){
  df <- data %>%
    filter(info.bound_type == error_mode) %>%
    filter(info.error_bound == error_bnd) %>%
    filter(info.compressor == comp) %>%
    filter(global.compression_ratio < thresh)

  ## local per block stats
  cr_local <- df$size.compression_ratio
  std <- df$error_stat.value_std
  
  # global stats
  cr_global <- df$global.compression_ratio
  std_global <- df$global.value_std
  
  # distances
  loc <- df$loc
  
  # file identfier
  file <- df$info.filename

  df <- data.frame(cr_local, std, cr_global, std_global, loc, file)
  return(df)
}

###  evaluation metrics
RelMAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMeanAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMaxAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }


cr_blocking_model <- function(df,modeltype,kf=8){
  if (modeltype == "LINEAR") {
    return (cr_blocking_model_linear(df,kf))
  }
  if (modeltype == "MIXED") {
    return (cr_blocking_model_mixed(df,kf))
  }
}

### prediction functions
cr_blocking_model_linear <- function(df, kf){

  #local per block 
  cr_local <- log(df$cr_local)
  loc_inter <- df$loc

  std_local0 <- df$std
  std_local <- ((std_local0)-min((std_local0),na.rm=TRUE))/(max((std_local0),na.rm=TRUE)-min((std_local0),na.rm=TRUE))

  #global stats
  y <- log(df$cr_global) 

  std_global0 <- df$std_global
  std_global <- ((std_global0)-min((std_global0),na.rm=TRUE))/(max((std_global0),na.rm=TRUE)-min((std_global0),na.rm=TRUE))

  #separate everything by file
  file <- df$file
  df_pregroup <- data.frame(y, std_local, cr_local, loc_inter, file)
  by_file <- df_pregroup %>% group_by(file) 

  df_reg <- by_file %>%   summarise("x1"     = sum(loc_inter*cr_local,            na.rm=TRUE),
                                    "x2"     = sum(std_local*cr_local,            na.rm=TRUE),
                                    "x3"     = sum(loc_inter*std_local*cr_local,  na.rm=TRUE),
                                    "y"      = mean(y,                            na.rm=TRUE))

  
  for (i in 1:1) {
    if (length(df_reg$file) < kf) {
      kf <- length(df_reg$file) %/% 2  
    }
    else { 
      kf <- kf
    }
    fold <- floor(runif(nrow(df_reg),1,(kf+1)))
    #print(fold)
    df_reg$fold <- fold
    cv_cor <- c() 
    cv_mape <- c() 
    cv_compression <- c()
    cv_coef <- c()
    pred_list <- c()
    ytest_list <- c()
    test_files <- c()
    train_files <- c()
  
    for (l in 1:kf){
      test.set <- df_reg[df_reg$fold == l,]
      train.set <- df_reg[df_reg$fold != l,]
      #test_files[[l]] <- test.set$file
      #train_files[[l]] <- train.set$file
  
      ### used if separate by file
      mi <- lm(y~1 + x1 + x2 + x3, data = train.set)
      cv_coef[[l]] <- mi$coefficients
      predi <- predict(mi, newdata=test.set)
      #
      cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(predi))
      cv_compression[[l]] <- c(mean(test.set$y), mean(predi))
      cv_cor[l] <- cor(exp(test.set$y),exp(predi))
      #
      pred_list[[l]] <- exp(predi)
      ytest_list[[l]] <- exp(test.set$y)
    }
  }
  
  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) }
  res_cv <- cbind(probs, stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Quantile', 'Corr', 'MedAPE')
  #print(res_cv)

  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)), res_cv=res_cv, folds=fold, cv_coef=unlist(cv_coef)))
}

### prediction functions
cr_blocking_model_mixed <- function(df, kf=8){
  
  #local per block 
  std_local0 <- df$std
  std_local <- ((std_local0)-min((std_local0),na.rm=TRUE))/(max((std_local0),na.rm=TRUE)-min((std_local0),na.rm=TRUE))
  loc_inter <- df$loc
  cr_local <- log(df$cr_local) 
  
  #global stats
  y <- log(df$cr_global) 
  std_global0 <- df$std_global
  std_global <- ((std_global0)-min((std_global0),na.rm=TRUE))/(max((std_global0),na.rm=TRUE)-min((std_global0),na.rm=TRUE))
  
  #separate everything by file
  file <- df$file
  df_pregroup <- data.frame(y, std_global, std_local, cr_local, loc_inter, file)
  
  by_file <- df_pregroup %>% group_by(file) 
  
  df_reg <- by_file %>%   summarise( "x1"     = sum(loc_inter*cr_local,            na.rm=TRUE),
                                     "x2"     = sum(std_local*cr_local,            na.rm=TRUE),
                                     "x3"     = sum(loc_inter*std_local*cr_local,  na.rm=TRUE),
                                     "y"      = mean(y,                            na.rm=TRUE))
  
  
  if (length(df_reg$file) < kf) {
    kf <- length(df_reg$file) %/% 2  
  }
  else { 
    kf <- kf
  }
  fold <- floor(runif(nrow(df_reg),1,(kf+1)))
  df_reg$fold <- fold
  cv_cor <- c() ; cv_mape <- c() 
  cv_compression <- c()
  pred_list <- c()
  ytest_list <- c()
  for (l in 1:kf){
    test.set <- df_reg[df_reg$fold == l,]
    train.set <- df_reg[df_reg$fold != l,]
    
    fit <- mixreg(y ~ x1 + x2 + x3, ncomp = 7, data=train.set, verb=FALSE)
    cv_coef <- fit$parmat[1,1:4]
    preds <- betas[1] + betas[2]*test.set$x1 + betas[3]*test.set$x2 + betas[4]*test.set$x3 
    
    cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(preds))
    cv_compression[[l]] <- c(mean(test.set$y),mean(preds))
    cv_cor[l] <- cor(exp(test.set$y),exp(preds))

    #
    pred_list[[l]] <- exp(preds)
    ytest_list[[l]] <- exp(test.set$y)  
  }
  
  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) } 
  res_cv <- cbind(probs, stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Quantile', 'Corr', 'MedAPE')
  
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)), res_cv=res_cv,coef=cv_coef))
}





