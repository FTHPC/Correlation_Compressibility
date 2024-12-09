library(flexmix)
library(modelr)
options(dplyr.summarise.inform = FALSE)

### compute loc (Arkas locality metric)
compute_loc <-function(data_lim){
  start.time <- Sys.time()
  df <- data_lim %>% dplyr::select(block.number,block.loc1,block.loc2,block.loc3)
  df_uni <- df[!duplicated(df[,c('block.loc1','block.loc2','block.loc3')]),]
  lx <- as.numeric(df_uni$block.loc1)
  ly <- as.numeric(df_uni$block.loc2)
  lz <- as.numeric(df_uni$block.loc3)
  loc0 <- data.frame(lx,ly,lz)
  #
  loc <- c()
  distmtx <- rdist(loc0)
  distmtx[distmtx==0] <- 1e-8
  l1norm <- as.matrix(dist(loc0, method='manhattan', upper=TRUE,diag=TRUE))
  for (j in 1:nrow(loc0)) {
    loc[j] <- sum(l1norm[,j] / distmtx[,j]) / sum(l1norm[,j])
  }  
  inner <- data.frame(df_uni, loc)  
  df_final <- merge(x=data_lim,y=inner, by="block.number") ### JOIN on block number
  stop.time <- Sys.time()
  print(stop.time - start.time)
  return(df_final)
}

###  evaluation metrics
RelMAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMeanAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMaxAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

cr_blocking_model <- function(df,modeltype,oos=FALSE,allEB=FALSE,kf=8){
  if (modeltype == "LINEAR") {
    return (predict_linear(df,kf))
  }
  if (modeltype == "FLEXMIX") {
    return (predict_flexmix(df,kf))
  }
}

### prediction functions
predict_cr <- function(df,modeltype,kf=5,oos=FALSE){
  start.time <- Sys.time()
  df_reg <- df %>% 
    mutate(
      #local per block 
      std = (std-min(std,na.rm=TRUE))/(max(std,na.rm=TRUE)-min(std,na.rm=TRUE)),
      cr_local = log(cr_local),
      #global stats
      #std_global = (std_global-min(std_global,na.rm=TRUE))/(max(std_global,na.rm=TRUE)-min(std_global,na.rm=TRUE)),
      y = log(cr_global)
      ) %>%
    #separate everything by file
    group_by(app,file) %>%
    dplyr::summarise("x1" = sum(loc*cr_local,na.rm=TRUE),
                     "x2" = sum(std*cr_local,na.rm=TRUE),
                     "x3" = sum(loc*std*cr_local,na.rm=TRUE),
                     "y"  = mean(y,na.rm=TRUE)
                    )
  #
  df_reg <- as.data.frame(df_reg)
  if (oos) {
    df_uni <- as.data.frame(unique(df_reg[c("app")])); colnames(df_uni) <- c("app")
  } else {
    df_uni <- as.data.frame(unique(df_reg[c("app","file")])); colnames(df_uni) <- c("app","file")  
  }
  #
  success <- FALSE
  tries <- 1
  max_iter <- 50
  predtime = 0
  while (!success) {
    if (tries > 1) { df_uni$fold <- NULL; df_reg$fold <- NULL }
    fold <- floor(runif(nrow(df_uni),1,(kf+1)))
    df_uni$fold <- fold
    if (oos) {
      df_reg <- merge(x=df_reg,y=df_uni,by=c('app'))
    } else {
      df_reg$fold <- fold  
    }
    #
    cv_cor <- c() ; cv_mape <- c() 
    cv_compression <- c()
    cv_coef <- c()
    pred_list <- c()
    ytest_list <- c()
    fits <- c()
    ncomps <- c()
    flag <- TRUE
    #
    for (l in 1:kf){
      test.set <- df_reg[df_reg$fold == l,]
      train.set <- df_reg[df_reg$fold != l,]
      #
      if (!nrow(test.set) || !(nrow(train.set))) { next }
      #
      if (modeltype == "LINEAR") {
        mi <- lm(y~1 + x1 + x2 + x3, data = train.set)
        #mi <- lm(y~1 + x1 + x2, data = train.set)
        cv_coef[[l]] <- mi$coefficients
        preds <- stats::predict(mi, newdata=test.set)
      }
      if (modeltype == "FLEXMIX") {
        ncomp <- ifelse(sd(train.set$y) < 0.2, 4, 8)
        ncomps[l] <- ncomp
        tryCatch(
          expr = { fit <<- flexmix(y ~ x1 + x2 + x3, data=train.set, k=ncomp) }, 
          error = function(e){ 
            flag <<- FALSE 
          }
        )
        if (!flag) { 
          tries <- tries + 1
          if (max_iter < tries) { stop("exceeded maximum number of model iterations.") }
          break 
        }
        posteriors <- posterior(fit, data.frame(test.set))
        start.predtime <- Sys.time()
        preds = sapply(1:nrow(test.set), function(x) {return(sum(unlist(predict(fit, test.set[x,]))*posteriors[x,]))})
        stop.predtime <- Sys.time()
        predtime <- stop.predtime - start.predtime
      }
      #
      cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(preds))
      cv_compression[[l]] <- c(mean(test.set$y),mean(preds))
      cv_cor[l] <- cor(exp(test.set$y),exp(preds))
      #
      pred_list[[l]] <- exp(preds)
      ytest_list[[l]] <- exp(test.set$y)  
    }
    if(flag) {
      success <- TRUE
    }
  }
  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) } 
  res_cv <- cbind(probs, stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Quantile', 'Corr', 'MedAPE')
  
  stop.time <- Sys.time()
  print(stop.time - start.time)
  print(paste("inference time: ", predtime))
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)), res_cv=res_cv,coef=c(unlist(cv_coef)),folds=fold,ncomps=ncomps,tries=tries,df_reg=df_reg))
}

### prediction functions -- including eb as param
predict_cr_allEB <- function(df,modeltype,kf=5,oos=FALSE){
  df_reg <- df %>% 
    mutate(
      #local per block 
      std = (std-min(std,na.rm=TRUE))/(max(std,na.rm=TRUE)-min(std,na.rm=TRUE)),
      cr_local = log(cr_local),
      #global stats
      std_global = (std_global-min(std_global,na.rm=TRUE))/(max(std_global,na.rm=TRUE)-min(std_global,na.rm=TRUE)),
      errorbound = errorbound,
      y = log(cr_global)
    ) %>%
    #separate everything by file
    group_by(app,file,errorbound) %>%
    dplyr::summarise("x1" = sum(loc*cr_local,na.rm=TRUE),
                     "x2" = sum(std*cr_local,na.rm=TRUE),
                     "x3" = sum(loc*std*cr_local,na.rm=TRUE),
                     "y"  = mean(y,na.rm=TRUE)
    )
  #
  names(df_reg)[names(df_reg)=="errorbound"] <- "x4"
  df_reg <- as.data.frame(df_reg)
  if (oos) {
    df_uni <- as.data.frame(unique(df_reg[c("app")])); colnames(df_uni) <- c("app")
  } else {
    df_uni <- as.data.frame(unique(df_reg[c("app","file")])); colnames(df_uni) <- c("app","file") 
  }
  success <- FALSE
  tries <- 1
  max_iter <- 50
  while (!success) {
    if (tries > 1) { df_uni$fold <- NULL; df_reg$fold <- NULL }
    fold <- floor(runif(nrow(df_uni),1,(kf+1)))
    df_uni$fold <- fold
    if (oos) {
      df_reg <- merge(x=df_reg,y=df_uni,by=c('app'))
    } else {
      df_reg <- merge(x=df_reg,y=df_uni, by=c("app","file"))  
    }
    #
    cv_cor <- c() ; cv_mape <- c() 
    cv_compression <- c()
    cv_coef <- c()
    pred_list <- c()
    ytest_list <- c()
    fits <- c()
    ncomps <- c()
    flag <- TRUE
    #
    for (l in 1:kf){
      test.set <- df_reg[df_reg$fold == l,]
      train.set <- df_reg[df_reg$fold != l,]
      #
      if (!nrow(test.set) || !(nrow(train.set))) { next }
      #
      if (modeltype == "LINEAR") {
        mi <- lm(y~1 + x1 + x2 + x3 + x4, data = train.set)
        cv_coef[[l]] <- mi$coefficients
        preds <- stats::predict(mi, newdata=test.set)
      }
      if (modeltype == "FLEXMIX") {
        ncomp <- ifelse(sd(train.set$y) < 0.2, 4, 8)
        ncomps[l] <- ncomp
        tryCatch(
          expr = { fit <<- flexmix(y ~ x1 + x2 + x3 + x4, data=train.set, k=ncomp) }, 
          error = function(e){ 
            flag <<- FALSE 
          }
        )
        if (!flag) { 
          tries <- tries + 1
          if (max_iter < tries) { stop("exceeded maximum number of model iterations.") }
          break 
        }
        posteriors <- posterior(fit, data.frame(test.set))
        preds = sapply(1:nrow(test.set), function(x) {return(sum(unlist(predict(fit, test.set[x,]))*posteriors[x,]))})
      }
      #
      cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(preds))
      cv_compression[[l]] <- c(mean(test.set$y),mean(preds))
      cv_cor[l] <- cor(exp(test.set$y),exp(preds))
      #
      pred_list[[l]] <- exp(preds)
      ytest_list[[l]] <- exp(test.set$y)  
    }
    if(flag) {
      if (tries > 1) {
        print(paste0("model passed on configuration ", tries, "."))
      }
      success <- TRUE
    }
  }
  probs=c(0.10, 0.5, 0.9)
  stats_quantile <- function(x){ quantile(x, probs=probs, na.rm = TRUE) } 
  res_cv <- cbind(probs, stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Quantile', 'Corr', 'MedAPE')
  
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)), res_cv=res_cv,coef=c(unlist(cv_coef)),folds=fold,ncomps=ncomps,tries=tries,df_reg=df_reg))
}


#k1=ifelse(sd(data_train$CR_SZ_1e.3)<0.2,1,4)
#m1 <- flexmix(CR_SZ_1e.3~   spatial_var + spatial_cor_mean + 
#                CodingGain + svd_trunc_intra + Distortion_1e.3, data = data_train, k = k1)
#posteriors= posterior(m1, data_test)
#pred_test_1= sapply(1:nrow(test.set), function(x){return(sum(unlist(predict(fit, test.set[x,]))*posteriors[x,]))})
#MedAPE_test=median(100*abs(exp(pred_test_1)-exp(data_test$CR_SZ_1e.3))/exp(data_test$CR_SZ_1e.3))



#fit <- flexmix(y ~ x1 + x2 + x3, data=train.set, k=ncomp,control=list(minprior=0.15,verbose=1))
#fit <- flexmix(y ~ x1 + x2 + x3, data=train.set, k=ncomp,control=list(verbose=1,classify="SEM"))
#fit <- flexmix(y ~ x1 + x2 + x3, data=train.set, k=ncomp,model=FLXMRglm(family = "Gamma"),control=list(verbose=1))
#fits[[l]] <- fit


#{
#  df_reg <- df %>% 
#    mutate(
#      std = (std-min(std,na.rm=TRUE))/(max(std,na.rm=TRUE)-min(std,na.rm=TRUE)),
#      cr_local = log(cr_local),
#      std_global = (std_global-min(std_global,na.rm=TRUE))/(max(std_global,na.rm=TRUE)-min(std_global,na.rm=TRUE)),
#      y = log(cr_global)
#    ) %>%
#    group_by(file) %>%
#    dplyr::summarise("x1" = loc*cr_local,
#                     "x2" = std*cr_local,
#                     "x3" = loc*std*cr_local,
#                     "y" = y
#    )
#  df_uni <- as.data.frame(unique(df_reg$file)); colnames(df_uni) <- c('file')
#  fold <- floor(runif(nrow(df_uni),1,(kf+1)))
#  df_uni$fold <- fold
#  df_reg <- merge(x=df_reg,y=df_uni, by="file")
#  df_reg <- as.data.frame(df_reg)
#}


mix_predict <- function(fit,test.set) {
  preds <- c()
  beta0 <- fit$parmat[,"beta0"]; beta1 <- fit$parmat[,"beta1"]
  lambda <- fit$parmat[,"lambda"]
  for (i in 1:nrow(test.set)) {
    preds[i] <- sum(lambda*(beta0 + beta1*test.set$x1[i]))
  }
  if (!nrow(test.set)) {
    preds <- numeric(0)
  }
  return (preds)
}



