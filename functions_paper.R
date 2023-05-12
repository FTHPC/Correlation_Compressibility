### read data
read_data <-function(block_count, block_size){
  name <- paste0("/home/dkrasow/compression/outputs/*blocks", block_count, "_block_size", block_size, "*.csv")
  filename <- Sys.glob(name)
  print(filename)
  data <- read.csv(filename)
  data <- as.data.frame(data)
  return(data)
}


### compute loc (arkas locality metric)
compute_loc <-function(data){
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
  inner <- data.frame(df_uni, loc)  
  ### JOIN on column unique identifiers
  df_final <- merge(x = data, y = inner,
                by.x=c("info.filename","block.method", "block.loc1", "block.loc2", "block.loc3"), 
                by.y=c("data.info.filename","data.block.method", "data.block.loc1", "data.block.loc2", "data.block.loc3"))


  return(df_final)
}

### extract data 
extract_cr_predictors <- function(data, error_mode, error_bnd, compressor, comp_thresh=200){
  data_orig <- filter(data, info.bound_type == error_mode)
  data0 <- filter(data_orig, info.error_bound==error_bnd)
  ###

  vx_compressor <- filter(data0, info.compressor == compressor)
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
  cr_local <- as.numeric(vx_compressor$size.compression_ratio)[indsz]

  ## global stats
  cr_global <- as.numeric(vx_compressor$global.compression_ratio)[indsz]
  # global std
  std_global <- as.numeric(vx_compressor$global.value_std[indsz])
  std_global[is.na(std_global)] <- 1e-8
  # distances
  loc <- vx_compressor$loc[indsz]

  #file identfier
  file <- vx_compressor$info.filename

  df <- data.frame(cr_local, qent, vrgstd, vargm, std, cr_global, std_global, loc, file)
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df <- df[-indqna,]}

  return(df)
}



###  evaluation metrics

RelMAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMeanAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMaxAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }



### prediction functions


cr_blocking_model <- function(df, kf=8){
  indsz <- which(df$cr_global<=comp_thresh)
  df <- df[indsz,]

   
  #local per block 

  qent0 <- df$qent
  qent <- (log(qent0)-min(log(qent0),na.rm=TRUE))/(max(log(qent0),na.rm=TRUE)-min(log(qent0),na.rm=TRUE))

  vrgstd0 <- df$vrgstd
  vrgstd <- ((vrgstd0)-min((vrgstd0),na.rm=TRUE))/(max((vrgstd0),na.rm=TRUE)-min((vrgstd0),na.rm=TRUE))

  std_local0 <- df$std
  std_local <- ((std_local0)-min((std_local0),na.rm=TRUE))/(max((std_local0),na.rm=TRUE)-min((std_local0),na.rm=TRUE))

  loc_inter <- df$loc
  cr_local <- log(df$cr_local) 

  #global stats
  #reduces the lenght to match others. all local blocks within a global block have same global stats
  y <- log(df$cr_global) # y values is the global compression ratio

  std_global0 <- df$std_global
  std_global <- ((std_global0)-min((std_global0),na.rm=TRUE))/(max((std_global0),na.rm=TRUE)-min((std_global0),na.rm=TRUE))



  #separate everything by file
  file <- df$file
  df_pregroup <- data.frame(y, std_global, std_local, cr_local, loc_inter, file)

  by_file <- df_pregroup %>% group_by(file) 

  df_reg <- by_file %>%   summarise( "x1"     = sum(loc_inter*cr_local,            na.rm=TRUE),
                                     "x2"     = sum(std_local*cr_local,           na.rm=TRUE),
                                     "x3"     = sum(loc_inter*std_local*cr_local,  na.rm=TRUE),
                                     "y"      = mean(y,                           na.rm=TRUE))


  # print(df_reg)

  ### does not separate by file
  # df_reg <- data.frame(y, std_global, std_local, cr_local, loc_inter)

  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df_reg <- df_reg[-indqna,]}
  if (nrow(df_reg) == 0){
    stop("model failed")
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

    ### used if separate by file
    mi <- lm(y~1 + x1 + x2 + x3, data = train.set)
    # mi <- lm(y~1 + loc_inter*cr_local + std_local*cr_local + loc_inter*std_local*cr_local, data = train.set)
    # print(summary(mi))

    predi <- predict(mi, newdata=test.set)
    #
    cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(predi))
    cv_compression[[l]] <- c(mean(test.set$y), mean(predi))
    cv_cor[l] <- cor(exp(test.set$y),exp(predi))
    #
    pred_list[[l]] <- exp(predi)
    ytest_list[[l]] <- exp(test.set$y)  
  }

  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) } 
  res_cv <- cbind(probs, stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Quantile', 'Corr', 'MedAPE')

  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)), res_cv=res_cv))
}
