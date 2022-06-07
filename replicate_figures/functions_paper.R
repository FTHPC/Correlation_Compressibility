

### extract data 

extract_cr_predictors <- function(data, error_mode, error_bnd, gaussian_corr=0, sz3=TRUE, comp_thresh=100){
  data_orig <- filter(data, info.bound_mode == error_mode)
  data_orig <- filter(data_orig, info.bound==error_bnd)
  data0 <-  filter(data_orig, info.quantized=='False' | info.quantized=='FALSE')
  ###
  if (error_mode == 'abs'){
    compressor0 <- c("zfp", "mgard", "bit_grooming","digit_rounding") }
  if (error_mode == 'rel'){
    compressor0 <- c("zfp", "mgard") }
  ###
  list_df_cr <- NULL
  for(i in 1:length(compressor0)){
    vx_compressor <- filter(data0, info.compressor == compressor0[i])
    indsz <- which(as.numeric(vx_compressor$size.compression_ratio)<=comp_thresh)
    #
    qent0 <- as.numeric(vx_compressor$stat.quantized_entropy)[indsz]
    qent0[qent0==0] <- 1e-8
    qent <- qent0
    #
    vargm <- as.numeric(vx_compressor$stat.n99[indsz])
    std <- as.numeric(vx_compressor$error_stat.value_std[indsz])
    std[is.na(std)] <- 1e-8
    vrgstd0 <- vargm/std
    vrgstd <- log(vrgstd0)
    #
    y <- as.numeric(vx_compressor$size.compression_ratio)[indsz]
    df <- data.frame(y, qent, vrgstd, vargm, std) 
    indqna <- which(is.na(qent))
    if (length(indqna)>1) {df <- df[-indqna,]}
    list_df_cr[[compressor0[i]]] <- df  }
  ###
  vxsz <- filter(data0, info.compressor == 'sz')
  vx_compressor <- filter(vxsz, sz.quantization_intervals=="default")
  indsz <- which(as.numeric(vx_compressor$size.compression_ratio)<=comp_thresh)
  #indsz <- which(is.na(vx_compressor$sz.constant_flag[indsz]))
  #
  qent0 <- as.numeric(vx_compressor$stat.quantized_entropy)[indsz]
  qent0[qent0==0] <- 1e-8
  qent <- qent0
  #
  vargm <- as.numeric(vx_compressor$stat.n99)[indsz]
  std <- as.numeric(vx_compressor$error_stat.value_std)[indsz]
  std[is.na(std)] <- 1e-8
  vrgstd0 <- vargm/std
  vrgstd <- log(vrgstd0)
  #
  y <- as.numeric(vx_compressor$size.compression_ratio)[indsz]
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df <- df[-indqna,]}
  #
  reg_per <- as.numeric(vx_compressor$sz.regression_blocks)[indsz]
  reg_per[is.na(reg_per)] <- 0
  lor_per <- as.numeric(vx_compressor$sz.lorenzo_blocks)[indsz]
  lor_per[is.na(lor_per)] <- 0
  reg_per <- round(100*reg_per/max(reg_per,lor_per),2)
  df <- data.frame(y, qent, vrgstd, vargm, std, reg_per) 
  #
  list_df_cr[['sz']] <- df
  compressors <- c(compressor0, 'sz2')
  ### 
  if (sz3==TRUE){
    vx3 <- filter(data0, info.compressor == "sz3")
    sz_mode <- unique(vx3$sz.predictor_mode)
    for(i in 1:length(sz_mode)){
      vx_compressor <- filter(vx3, sz.predictor_mode == sz_mode[i])
      indsz <- which(vx_compressor$size.compression_ratio<=comp_thresh)
      #
      qent0 <- as.numeric(vx_compressor$stat.quantized_entropy)[indsz]
      qent0[qent0==0] <- 1e-8
      qent <- qent0
      #
      vargm <- as.numeric(vx_compressor$stat.n99)[indsz]
      std <- as.numeric(vx_compressor$error_stat.value_std)[indsz]
      std[is.na(std)] <- 1e-8
      vrgstd0 <- vargm/std
      vrgstd <- log(vrgstd0)
      #
      y <- as.numeric(vx_compressor$size.compression_ratio)[indsz]
      df <- data.frame(y, qent, vrgstd, vargm, std) 
      indqna <- which(is.na(qent))
      if (length(indqna)>1) {df <- df[-indqna,]}   
      list_df_cr[[sz_mode[i]]] <- df  }
    compressors <- c(compressor0, 'sz2', paste('sz3-',sz_mode,sep=''))
  }

  if (gaussian_corr==1){gaussian_corr <- vx_compressor$info.weight-2} 
  
  return(list(df=list_df_cr, compressors=compressors, mode=error_mode, bound=error_bnd, gaussian_corr=gaussian_corr))
}



###  evaluation metrics

RelMAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMeanAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }

RelMaxAE <- function(pred,true){
  median(abs((pred-true)/true),na.rm=TRUE) }



### prediction functions


cr_regression_linreg <- function(df, kf=8, graph=1, data_nm, compressor_nm, error_mode, error_bnd, fold_col=1){
  indsz <- which(df$y<=comp_thresh)
  df <- df[indsz,]
  qent0 <- df$qent
  qent <- (log(qent0)-min(log(qent0),na.rm=TRUE))/(max(log(qent0),na.rm=TRUE)-min(log(qent0),na.rm=TRUE))
  vrgstd0 <- df$vrgstd
  vrgstd <- ((vrgstd0)-min((vrgstd0),na.rm=TRUE))/(max((vrgstd0),na.rm=TRUE)-min((vrgstd0),na.rm=TRUE))
  y <- log(df$y)
  df_reg <- data.frame(y, qent, vrgstd)
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df_reg <- df_reg[-indqna,]}
  
  fold <- floor(runif(nrow(df_reg),1,(kf+1)))
  df_reg$fold <- fold
  cv_cor <- c() ; cv_mape <- c() 
  pred_list <- c()
  ytest_list <- c()
  vtest_list <- c()
  for (l in 1:kf){
    test.set <- df_reg[df_reg$fold == l,]
    train.set <- df_reg[df_reg$fold != l,]
    mi <- lm(y~1+qent+vrgstd+qent*vrgstd, data = train.set)
    predi <- predict(mi, newdata=test.set)
    #
    cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(predi))
    cv_cor[l] <- cor(exp(test.set$y),exp(predi))
    #
    pred_list[[l]] <- exp(predi)
    ytest_list[[l]] <- exp(test.set$y) 
    vtest_list[[l]] <- test.set$vrgstd   }
  
  if (graph == 1){
    if (fold_col==1){Col <- c(wes_palette("GrandBudapest1", n = 4), wes_palette("GrandBudapest2", n = 4), wes_palette("Royal1", n = 2))}
    if (fold_col==0){Col <- rep(1,kf) }
    ymax <- max(c(unlist(pred_list)),c(unlist(ytest_list)), na.rm=TRUE) + .1
    ymin <- min(c(unlist(pred_list)),c(unlist(ytest_list)), na.rm=TRUE) - .1
    fold_nm <- c('Fold1', 'Fold2', 'Fold3', 'Fold4', 'Fold5', 'Fold6', 'Fold7', 'Fold8', 'Fold9', 'Fold10')
    
    graphics.off()
    png(filename = paste('scatterplot_cv_linreg_',compressor_nm,'_',graph_nm,'_',error_mode,error_bnd,'.png', sep=''), width = 400, height = 400)
    plot(ytest_list[[1]], pred_list[[1]], xlim=c(ymin, ymax), ylim=c(ymin, ymax), pch=20, cex=1.2,  cex.lab=1.45, cex.axis=1.4, cex.main=1.6,col=Col[1], xlab='Observed CR', ylab='Predicted CR', main=paste(data_nm,' - ',compressor_nm,error_mode,error_bnd), mgp=c(2,0.5,0))
    abline(0, 1)
    #mtext(paste(kf,'-fold cross-validation',sep=''), cex=1.5)
    for (i in 1:kf){
      points(ytest_list[[i]], pred_list[[i]], pch=20, cex=1.2, col=Col[i]) }
    if (fold_col==1){ legend(x='topleft', fold_nm[1:kf], ncol=2, col=Col[1:kf], pch=20, bty='n', cex=1.4) }
    dev.off()  }
  
  stats_quantile <- function(x){ quantile(x, probs=c(0.10, 0.5, 0.9), na.rm = TRUE) } 
  res_cv <- cbind(stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Corr','MedAPE')
  print(round(res_cv, 4))
  
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)),res_cv=res_cv))
}





cr_regression_gam <- function(df, kf=8, graph=1, fig_nm, data_nm, compressor_nm, error_mode, error_bnd, print_stats=1){
  indsz <- which(df$y<=comp_thresh)
  df <- df[indsz,]
  qent0 <- df$qent
  qent <- (log(qent0)-min(log(qent0),na.rm=TRUE))/(max(log(qent0),na.rm=TRUE)-min(log(qent0),na.rm=TRUE))
  vrgstd0 <- df$vrgstd
  vrgstd <- ((vrgstd0)-min((vrgstd0),na.rm=TRUE))/(max((vrgstd0),na.rm=TRUE)-min((vrgstd0),na.rm=TRUE))
  y <- log(df$y)
  df_reg <- data.frame(y, qent, vrgstd)
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df_reg <- df_reg[-indqna,]}
  
  fold <- floor(runif(nrow(df_reg),1,(kf+1)))
  df_reg$fold <- fold
  cv_cor <- c() ; cv_mape <- c() 
  pred_list <- c()
  ytest_list <- c()
  vtest_list <- c()
  for (l in 1:kf){
    test.set <- df_reg[df_reg$fold == l,]
    train.set <- df_reg[df_reg$fold != l,]
    mi <- gam(y~s(qent, k=3) + s(vrgstd, k=3) + ti(qent, vrgstd, k=3), data = train.set)
    predi <- predict.gam(mi, newdata=test.set)
    #
    cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(predi))
    cv_cor[l] <- cor(exp(test.set$y),exp(predi))
    #
    pred_list[[l]] <- exp(predi)
    ytest_list[[l]] <- exp(test.set$y) 
    vtest_list[[l]] <- test.set$vrgstd   }
  
  if (graph == 1){
    Col <- rep(1,kf)
    ymax <- max(c(unlist(pred_list)),c(unlist(ytest_list)), na.rm=TRUE) + .1
    ymin <- min(c(unlist(pred_list)),c(unlist(ytest_list)), na.rm=TRUE) - .1
    
    graphics.off()
    png(filename = paste(fig_nm,'_scatterplot_cv_gam_',compressor_nm,'_',data_nm,'_',error_mode,error_bnd,'.png', sep=''), width = 400, height = 400)
    plot(ytest_list[[1]], pred_list[[1]], xlim=c(ymin, ymax), ylim=c(ymin, ymax), pch=20, cex=1.2,  cex.lab=1.45, cex.axis=1.4, cex.main=1.6,col=Col[1], xlab='Observed CR', ylab='Predicted CR', main=paste(data_nm,' - ',compressor_nm,error_mode,error_bnd), mgp=c(2,0.5,0))
    abline(0, 1)
    #
    for (i in 1:kf){
      points(ytest_list[[i]], pred_list[[i]], pch=20, cex=1.2, col=Col[i]) }
    dev.off()
    }

  stats_quantile <- function(x){ quantile(x, probs=c(0.10, 0.5, 0.9), na.rm = TRUE) } 
  res_cv <- cbind(stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Corr','MedAPE')
  if (print_stats == 1){
    print(paste('Cross-validation metrics -',compressor_nm,'-',data_nm))
    print(round(res_cv, 4))
  }
  
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)),res_cv=res_cv))
}




cr_regression_gam_cv <- function(df, kf=8, print_stats=1, comp_thresh=comp_thresh){
  set.seed(1234)
  
  indsz <- which( df$y <= comp_thresh )
  df <- df[indsz,]
  qent0 <- df$qent
  qent <- (log(qent0)-min(log(qent0),na.rm=TRUE))/(max(log(qent0),na.rm=TRUE)-min(log(qent0),na.rm=TRUE))
  vrgstd0 <- df$vrgstd
  vrgstd <- ((vrgstd0)-min((vrgstd0),na.rm=TRUE))/(max((vrgstd0),na.rm=TRUE)-min((vrgstd0),na.rm=TRUE))
  y <- log(df$y)
  df_reg <- data.frame(y, qent, vrgstd)
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df_reg <- df_reg[-indqna,]}
  
  df_reg <- df_reg[sample(1:nrow(df_reg)), ]
  fold <- rep(1:kf, each=floor(nrow(df_reg)/kf))
  if (length(fold)<nrow(df_reg)){fold_end <- rep(kf,length.out=(nrow(df_reg)-length(fold))) ; fold <- c(fold,fold_end)}
  df_reg$fold <- fold
  cv_cor <- c() ; cv_mape <- c() 
  pred_list <- c()
  ytest_list <- c()
  vtest_list <- c()
  for (l in 1:kf){
    test.set <- df_reg[df_reg$fold == l,]
    train.set <- df_reg[df_reg$fold != l,]
    mi <- gam(y~s(qent, k=3) + s(vrgstd, k=3) + ti(qent, vrgstd, k=3), data = train.set)
    predi <- predict.gam(mi, newdata=test.set)
    #
    cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(predi))
    cv_cor[l] <- cor(exp(test.set$y),exp(predi))
    #
    pred_list[[l]] <- exp(predi)
    ytest_list[[l]] <- exp(test.set$y) 
    vtest_list[[l]] <- test.set$vrgstd   }
  
  stats_quantile <- function(x){ quantile(x, probs=c(0.10, 0.5, 0.9), na.rm = TRUE) } 
  res_cv <- cbind(stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Corr','MedAPE')
  if (print_stats == 1){
    print(paste('Cross-validation metrics -',compressor_nm,'-',data_nm))
    print(round(res_cv, 4))
  }
  
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)),res_cv=res_cv))
}


cr_regression_gam_traintest <- function(df, kf=20, prctg, print_stats=1, compressor_nm){
  set.seed(1234)
  indsz <- which(df$y<=comp_thresh)
  df <- df[indsz,]
  qent0 <- df$qent
  qent <- (log(qent0)-min(log(qent0),na.rm=TRUE))/(max(log(qent0),na.rm=TRUE)-min(log(qent0),na.rm=TRUE))
  vrgstd0 <- df$vrgstd
  vrgstd <- ((vrgstd0)-min((vrgstd0),na.rm=TRUE))/(max((vrgstd0),na.rm=TRUE)-min((vrgstd0),na.rm=TRUE))
  y <- log(df$y)
  df_reg <- data.frame(y, qent, vrgstd)
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df_reg <- df_reg[-indqna,]}

  cv_cor <- c() ; cv_mape <- c() 
  pred_list <- c()
  ytest_list <- c()
  vtest_list <- c()
  for (l in 1:kf){
    df_reg <- df_reg[sample(1:nrow(df_reg)), ]
    test.set <- df_reg[1:(prctg*nrow(df_reg)),]
    train.set <- df_reg[(prctg*nrow(df_reg)+1):nrow(df_reg),]
    mi <- gam(y~s(qent, k=3) + s(vrgstd, k=3) + ti(qent, vrgstd, k=3), data = train.set)
    predi <- predict.gam(mi, newdata=test.set)
    #
    cv_mape[l] <- RelMAE(true=exp(test.set$y),pred=exp(predi))
    cv_cor[l] <- cor(exp(test.set$y),exp(predi))
    #
    pred_list[[l]] <- exp(predi)
    ytest_list[[l]] <- exp(test.set$y) 
    vtest_list[[l]] <- test.set$vrgstd   }
  
  stats_quantile <- function(x){ quantile(x, probs=c(0.10, 0.5, 0.9), na.rm = TRUE) } 
  res_cv <- cbind(stats_quantile(cv_cor), 100*stats_quantile(cv_mape))
  colnames(res_cv) <- c('Corr','MedAPE')
  if (print_stats == 1){
    print(paste('Cross-validation metrics -',compressor_nm))
    print(round(res_cv, 4))
  }
  return(list(pred=c(unlist(pred_list)), ytest=c(unlist(ytest_list)),res_cv=res_cv))
}




scatterplot_sz_3modes_prediction <- function(gam_res, fig_nm, data_nm, error_bnd, error_mode){
  ymin <- min(gam_res[[1]]$ytest, gam_res[[1]]$pred,gam_res[[2]]$ytest, gam_res[[2]]$pred,gam_res[[3]]$ytest, gam_res[[3]]$pred, gam_res[[4]]$ytest, gam_res[[4]]$pred, na.rm=TRUE) -.05
  ymax <- max(gam_res[[1]]$ytest, gam_res[[1]]$pred,gam_res[[2]]$ytest, gam_res[[2]]$pred,gam_res[[3]]$ytest, gam_res[[3]]$pred, gam_res[[4]]$ytest, gam_res[[4]]$pred, na.rm=TRUE) +.05
  
  graphics.off()
  png(filename = paste(fig_nm,'_scatterplot_cv_gam_sz3modes_',data_nm,'_',error_mode,error_bnd,'.png', sep=''), width = 400, height = 400)
  plot(gam_res[[1]]$ytest, gam_res[[1]]$pred, xlim=c(ymin, ymax), ylim=c(ymin, ymax), pch=20, cex=1.2,  cex.lab=1.45, cex.axis=1.4, cex.main=1.6,col=1, xlab='Observed CR', ylab='Predicted CR', main=paste(data_nm,' - ',error_mode,error_bnd), mgp=c(2,0.5,0))
  abline(0, 1)
  for (i in 2:4){
    points(gam_res[[i]]$ytest, gam_res[[i]]$pred, pch=4, cex=1.2, lwd=1.5, col=i) }
  legend(x='topleft',c('SZ2', 'SZ3 interpolation', 'SZ3 Lorenzo', 'SZ3 regression'), col=1:4, pch=c(20,4,4,4), cex=1.5, lwd=1.8, bty='n',  lty=NA)
  legend(x='bottomright',c('MedAPE (%)', paste('SZ2:',round(gam_res[[1]]$res_cv[2,2],2)), paste('interp.:',round(gam_res[[2]]$res_cv[2,2],2)), paste('Lor.:',round(gam_res[[3]]$res_cv[2,2],2)), paste('regr.',round(gam_res[[4]]$res_cv[2,2],2))), col=1, pch=NA, cex=1.5, lwd=1.8, bty='n',  lty=NA)
  dev.off()
  
}




lasso_selection <- function(df,  print=1){
  indsz <- which(df$y<=comp_thresh)
  df <- df[indsz,]
  qent0 <- log(df$qent)
  qent <- scale(qent0, scale = TRUE, center=TRUE)
  vrgstd0 <- df$vrgstd
  vrgstd <- scale(vrgstd0, scale = TRUE, center=TRUE)
  
  x <- as.matrix(cbind(qent, vrgstd, qent*vrgstd))
  y <- log(df$y)
  cv_model <- cv.glmnet(x, y, alpha = 1,  nfolds = 8)
  best_lambda <- cv_model$lambda.min
  best_model <- glmnet(x, y, alpha = 1, lambda = best_lambda)
  if(print==1){ print('LASSO results')
    print(abs(round(coef(best_model),3))) }
  return(best_model)
}




gam_selection <- function(df){
  indsz <- which(df$y<=comp_thresh)
  df <- df[indsz,]
  qent0 <- df$qent
  qent <- (log(qent0)-min(log(qent0),na.rm=TRUE))/(max(log(qent0),na.rm=TRUE)-min(log(qent0),na.rm=TRUE))
  vrgstd0 <- df$vrgstd
  vrgstd <- ((vrgstd0)-min((vrgstd0),na.rm=TRUE))/(max((vrgstd0),na.rm=TRUE)-min((vrgstd0),na.rm=TRUE))
  y <- log(df$y)
  df_reg <- data.frame(y, qent, vrgstd)
  indqna <- which(is.na(qent))
  if (length(indqna)>1) {df_reg <- df_reg[-indqna,]}
  
  res_gam <- gam(y~s(qent, k=3) + s(vrgstd, k=3) + ti(qent, vrgstd, k=3), data = df_reg, select=TRUE)
  print(summary(res_gam)$s.table[,4])
}




cr_regression_coeffcient <- function(data, graph_nm, error_mode){
  err_bnd <- unique(data$info.bound)
  coeff_regression <- array(NA, c((length(unique(data$info.compressor))+2), (length(err_bnd)), 4))
  for (j in 1:(length(err_bnd))){
    list_df <- extract_cr_predictors(data, error_mode, error_bnd=err_bnd[j], gaussian_corr=0) 
    indsz0 <- which(list_df$df[['sz']]$y<=comp_thresh)
    compressors <- list_df$compressors
    for (i in 1:length(compressors)){
      df <- list_df$df[[i]]
      indsz <- which(df$y<=comp_thresh)
      df <- df[indsz,]
      qent0 <- log(df$qent)
      qent <- scale(qent0, scale = TRUE, center=TRUE)
      vrgstd0 <- df$vrgstd
      vrgstd <- scale(vrgstd0, scale = TRUE, center=TRUE)
      x <- as.matrix(cbind(qent, vrgstd, qent*vrgstd))
      y <- log(df$y)
      m <- lm(y ~ 1+x)
      coeff_regression[i,j,] <- m$coefficients       }    }
  
  graphics.off()
  png(filename = graph_nm, width = 700, height = 700)
  par(mfrow=c(2,2), tcl=-0.2, mai=c(0.5,0.5,0.4,0.5), oma = c(6,1,1,1), mar=c(4.5,4.5,4.5,2.1))
  matplot(t(coeff_regression[,,1]), cex=1.8, cex.main=1.8, cex.lab=1.8, cex.axis=1.8, xlab='', ylab='Regression coefficient', typ='b',lwd=.8, xaxt='n', col=1:length(compressors), lty=1, pch=c(rep(20,5),rep(17,3)), mgp=c(2,0.2,0))
  mtext('Intercept a', cex=2)
  axis(1, at=1:length(err_bnd), labels=c('1e-5', '1e-4', '1e-3', '1e-2'), cex.lab=1.8, cex.axis=1.8, cex=1.8)
  grid()
  ##
  matplot((t(coeff_regression[,,2])), cex=1.8, cex.main=1.8, cex.lab=1.8, cex.axis=1.8, xlab='', ylab='', typ='b',lwd=.8, xaxt='n', col=1:length(compressors), lty=1, pch=c(rep(20,5),rep(17,3)), mgp=c(2,0.2,0))
  mtext('Slope b', cex=2)
  axis(1, at=1:length(err_bnd), labels=c('1e-5', '1e-4', '1e-3', '1e-2'), cex.lab=1.8, cex.axis=1.8)
  grid()
  ##
  mtext('log(CR)~a+b*log(qent)+c*log(svd/std)+d*log(svd/std)*log(qent)', cex=1.5, side = 3, line = -2, outer = TRUE)
  ##
  matplot((t(coeff_regression[,,3])), cex=1.8, cex.main=1.8, cex.lab=1.8, cex.axis=1.8, xlab='Error bound', ylab='Regression coefficient', typ='b', xaxt='n', col=1:length(compressors), lty=1, lwd=.8, pch=c(rep(20,5),rep(17,3)), mgp=c(2.5,0.2,0))
  mtext('Slope c', cex=2)
  axis(1, at=1:length(err_bnd), labels=c('1e-5', '1e-4', '1e-3', '1e-2'), cex.lab=1.8, cex.axis=1.8)
  grid()
  ##
  matplot((t(coeff_regression[,,4])), cex=1.8, cex.main=1.8, cex.lab=1.8, cex.axis=1.8, xlab='Error bound', ylab='', typ='b', xaxt='n', col=1:length(compressors), lty=1, lwd=.8, pch=c(rep(20,5),rep(17,3)), mgp=c(2.5,0.2,0))
  mtext('Slope d', cex=2)
  axis(1, at=1:length(err_bnd), labels=c('1e-5', '1e-4', '1e-3', '1e-2'), cex.lab=1.8, cex.axis=1.8)
  grid()
  ##
  par(fig = c(0, 1, 0, 1), oma = c(0, 0, 0, 0), mar = c(0, 0, 0, 0), new = TRUE)
  #par(xpd=TRUE)
  plot(0, 0, type = 'l', bty = 'n', xaxt = 'n', yaxt = 'n')
  legend(x='bottom', compressors, col=1:length(compressors), pch=c(rep(20,5),rep(17,3)), cex=2, bty='n', ncol=3)
  dev.off()
  
  return(coeff_regression)
}



