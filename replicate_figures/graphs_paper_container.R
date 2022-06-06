
rm(list=ls())

library('dplyr')
library('fields')
library('pals')
library('mgcv')
library('glmnet')
library('viridis')
library('png')
library('rhdf5')

set.seed(1234)
comp_thresh <- 100

########################################################################
########################################################################
## GRAPH 1 - introduction scatterplots of CR prediction

set.seed(1234)
source('functions_paper.R')

# loading data
dataset <- 'miranda_vx'
error_bnd <- 1e-5
error_mode <- 'abs'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)

# saving each panel graph
print('#############################################')
print('Saving figure 1 panels and printing corresponding validation statistics')
res_gam_mir_sz <- cr_regression_gam(list_df$df[['sz']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='SZ2', error_mode, error_bnd)
res_gam_mir_zfp <- cr_regression_gam(list_df$df[['zfp']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='ZFP', error_mode, error_bnd)
res_gam_mir_mgard <- cr_regression_gam(list_df$df[['mgard']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='MGARD', error_mode, error_bnd)
res_gam_mir_dr <- cr_regression_gam(list_df$df[['bit_grooming']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='Bit Grooming', error_mode, error_bnd)



########################################################################
########################################################################
## Section II-D comparing CR threshold 

print('#############################################')
print('Printing prediction accuracy comparison for various thresholds (maximum) of CR in regression model')

### Scale LetKF
source('functions_paper.R')
comp_red <- c('sz','zfp','mgard','digit_rounding')
error_bnd <- 1e-5
error_mode <- 'abs'
data0 <- read.csv('./generated_data/dataframe_output_scale_mar14.csv')
data0 <- as.data.frame(data0)
var_nm <- unique(data0$info.filename)[c(2,4,5,6,7,9,11)]

comp_threshold <- seq(100, 2000, by=300)
res_array <- array(0,c(4,length(var_nm),length(comp_threshold)))
for (i in  1:length(comp_red)){
  for (j in 1:length(var_nm)){
    for (k in  1:length(comp_threshold)){
      data <- filter(data0, info.filename == var_nm[j])
      list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=0, sz3=FALSE, comp_thresh=comp_threshold[k])
      if (dim(list_df$df[[comp_red[i]]])[1] > 15){
        gam_res <- cr_regression_gam_cv(df=list_df$df[[comp_red[i]]], kf=8, print_stats=0, comp_thresh=comp_threshold[k])
        res_array[i,j,k] <- gam_res$res_cv[2,2]  }}}}

row.names(res_array) <- comp_red
print('Printing discrepancy (%) in prediction accuracy comparison between CR threshold 2000 and 100')
for (i in 1:length(var_nm)){
  print(paste('SCALE LetKF field',var_nm[i]))
  print(round(apply(X=res_array[,i,], FUN=max, MARGIN=1)-apply(X=res_array[,i,], FUN=min, MARGIN=1),3))  }



### Miranda
source('functions_paper.R')
comp_red <- c('sz','zfp','mgard','digit_rounding')
error_bnd <- 1e-5
error_mode <- 'abs'
data0 <- read.csv('./generated_data/dataframe_output_miranda_feb27.csv')
data0 <- as.data.frame(data0)
data0 <- filter(data0, dim2 == 384)
var_nm <- unique(data0$info.filename)

comp_threshold <- seq(100, 2000, by=300)
res_array <- array(0,c(4,length(var_nm),length(comp_threshold)))
range_cr <- array()
for (i in  1:length(comp_red)){
  for (j in 1:length(var_nm)){
    for (k in  1:length(comp_threshold)){
      data <- filter(data0, info.filename == var_nm[j])
      list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=0, sz3=FALSE, comp_thresh=comp_threshold[k])
      if (dim(list_df$df[[comp_red[i]]])[1] > 20){
        gam_res <- cr_regression_gam_cv(df=list_df$df[[comp_red[i]]], kf=7, print_stats=0, comp_thresh=comp_threshold[k])
        res_array[i,j,k] <- gam_res$res_cv[2,2]  }}}}

row.names(res_array) <- comp_red
print('Printing discrepancy (%) in prediction accuracy comparison between CR threshold 2000 and 100')
for (i in 1:length(var_nm)){
  print(paste('Miranda field',var_nm[i]))
  print(round(apply(X=res_array[,i,], FUN=max, MARGIN=1)-apply(X=res_array[,i,], FUN=min, MARGIN=1),3))  }



########################################################################
########################################################################
## GRAPH 3  - predictors for Miranda and CESM

source('functions_paper.R')

# loading data
dataset <- 'miranda_vx'
error_bnd <- 1e-5
error_mode <- 'abs'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
dat_sz <- list_df$df[['sz']]

print('#############################################')
print('Saving left panel of figure 3 (SZ - Miranda Vx)')
graphics.off()
png('fig3_predictors_miranda_vx_sz_abs1e5.png', width=300,  height = 900)
par(mfcol=c(3,1), tcl=-0.2, mai=c(0.55,0.55,.55,1.2), mar=c(5.1, 4.1, 4.1, 6))
plot(dat_sz$vargm, dat_sz$y, pch=20, xlab='SVD-trunc', ylab='Compression ratio', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7,  main='Miranda Vx - SZ2 ABS 1e-5', mgp=c(2,0.5,0), ylim=c(0,55))
#
plot(dat_sz$std, dat_sz$y, pch=20, xlab='Standard deviation',  ylab='Compression ratio', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7,  main='',mgp=c(2,0.5,0), ylim=c(0,55))
#
nc <- 50
rbPal <- colorRampPalette(c('red','blue'))
colq <- rbPal(nc)[as.numeric(cut(dat_sz$qent,breaks = nc))]
plot(dat_sz$vrgstd, dat_sz$y, pch=20, xlab='Log(SVD-trunc / Std dev.)', ylab='Compression ratio', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7, col=colq, main='', mgp=c(2,0.5,0), ylim=c(0,55))
image.plot(legend.only = TRUE, zlim=range(sort(dat_sz$qent), na.rm=TRUE), col=rbPal(20)[as.numeric(cut(sort(dat_sz$qent),breaks = 20))], axis.args=c(cex.axis=1.7),legend.args=list( text='quantized entropy', cex=1.8, side=2))
dev.off()


##
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'cesm_cl'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
dat_sz <- list_df$df[['zfp']]

print('#############################################')
print('Saving right panel of figure 3 (ZFP - CESM-cloud)')
graphics.off()
png('fig3_predictors_cesm_cl_zfp_abs1e5.png', width=300,  height = 900)
par(mfcol=c(3,1), tcl=-0.2, mai=c(0.55,0.55,.55,1.2), mar=c(5.1, 4.1, 4.1, 6))
plot(dat_sz$vargm, dat_sz$y, pch=20, xlab='SVD-trunc', ylab='', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7,  main='CESM cloud - ZFP ABS 1e-5', mgp=c(2,0.5,0), ylim=c(0,45))
#
plot(dat_sz$std, dat_sz$y, pch=20, xlab='Standard deviation',  ylab='', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7,  main='',mgp=c(2,0.5,0), ylim=c(0,45))
#
nc <- 50
rbPal <- colorRampPalette(c('red','blue'))
colq <- rbPal(nc)[as.numeric(cut(dat_sz$qent,breaks = nc))]
plot(dat_sz$vrgstd, dat_sz$y, pch=20, xlab='Log(SVD-trunc / Std dev.)', ylab='', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7, col=colq, main='', mgp=c(2,0.5,0), ylim=c(0,45))
image.plot(legend.only = TRUE, zlim=range(sort(dat_sz$qent), na.rm=TRUE), col=rbPal(20)[as.numeric(cut(sort(dat_sz$qent),breaks = 20))], axis.args=c(cex.axis=1.7),legend.args=list( text='quantized entropy', cex=1.8, side=2))
dev.off()




########################################################################
########################################################################
## GRAPH 4 - Gaussian samples

###### Prediction metrics 
comp_red <- c('sz','zfp','mgard','digit_rounding','bit_grooming')
source('functions_paper.R')
error_mode <- 'abs'
error_bnd <- 1e-3

dataset <- 'gaussian_singlescale'
source('load_dataset_paper.R')
list_df1 <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian,sz3=FALSE)
dataset <- 'gaussian_type1'
source('load_dataset_paper.R')
list_df2 <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian,sz3=FALSE)
dataset <- 'gaussian_type2'
source('load_dataset_paper.R')
list_df3 <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
dataset <- 'gaussian_type3' 
source('load_dataset_paper.R')
list_df4 <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)


APE <- NULL
for (k in  1:length(comp_red)){
  set.seed(1234)
  gam_res1 <- cr_regression_gam(df=list_df1$df[[comp_red[k]]], kf=5, graph=0, fig_nm='', data_nm = 'Gaussian single scale', compressor_nm=comp_red[k], error_mode, error_bnd, print_stats=0)  
  APEi <- 100*c(unlist(abs(gam_res1$pred - gam_res1$ytest)/gam_res1$ytest))
  APE[[k]] <- APEi
  #
  set.seed(1234)
  gam_res2 <- cr_regression_gam(df=list_df2$df[[comp_red[k]]], kf=5, graph=0, fig_nm='', data_nm = 'Gaussian type 1', compressor_nm=comp_red[k], error_mode, error_bnd, print_stats=0)  
  APEi <- 100*c(unlist(abs(gam_res2$pred - gam_res2$ytest)/gam_res2$ytest))
  APE[[k+5]] <- APEi
  #
  set.seed(1234)
  gam_res3 <- cr_regression_gam(df=list_df3$df[[comp_red[k]]], kf=5, graph=0, fig_nm='', data_nm = 'Gaussian type 2', compressor_nm=comp_red[k], error_mode, error_bnd, print_stats=0)  
  APEi <- 100*c(unlist(abs(gam_res3$pred - gam_res3$ytest)/gam_res3$ytest))
  APE[[k+10]] <- APEi
  #
  set.seed(1234)
  gam_res4 <- cr_regression_gam(df=list_df4$df[[comp_red[k]]], kf=5, graph=0, fig_nm='', data_nm = 'Gaussian type 3', compressor_nm=comp_red[k], error_mode, error_bnd, print_stats=0)  
  APEi <- 100*c(unlist(abs(gam_res4$pred - gam_res4$ytest)/gam_res4$ytest))
  APE[[k+15]] <- APEi    }

col_cmp <- c(16,2:5)
fields_nm <- c('1-scale', 'Type 1', 'Type 2', 'Type 3')
MeanAPE <- c(unlist(lapply(APE,mean)))
MedianAPE <- c(unlist(lapply(APE,median)))

graphics.off()
png(filename = paste('fig4_gaussian_mean_predictionerror_allsamples.png', sep=''), width=600, height=400)
par(mar=c(6, 4.1, 4, 1), mgp=c(2.2,0.5,0))
boxplot(APE, pch=20, xaxt='n', col=col_cmp, outcol=col_cmp, cex=1.4, cex.lab=1.9, cex.axis=1.8, ylab='Absolute percentage error (%)')
points(c(MeanAPE), pch='x', col='white', cex=1.7)
title('Gaussian samples', cex.main=1.7, line=2.5)
axis(1, at=seq(3,length(APE),by=5), labels=fields_nm, las=2, cex.axis=1.9)
legend(x='topright', c('SZ ','ZFP ','MGARD ','Digit Rounding', 'BitGrooming'), col=c(16,2:5), pch=rep(20,5), bty='n', cex=1.5,  horiz='TRUE', inset=c(0.2,-.15), xpd=TRUE, x.intersp=1, text.width=c(2,2.1,2.3,2,-1))
dev.off()


########################################################################
########################################################################
## GRAPH 5  - SZ and different prediction modes

###### scatterplots and Table 2: prediction metrics 
set.seed(1234)
comp_red <- c('sz','interpolation','lorenzo','regression')
source('functions_paper.R')

print('#############################################')
print('Saving figure 5 and printing corresponding validation statistics')
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=TRUE)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, fig_nm='fig5', graph=0, data_nm = 'Miranda-Vx', error_mode, error_bnd)    }
##
scatterplot_sz_3modes_prediction(gam_res, fig_nm='fig5', data_nm = 'Miranda-Vx', error_bnd, error_mode)
##
print('Median (min, max) percentage usage of regression mode in SZ2:')
print(paste(median(list_df$df[['sz']]$reg_per),' (',min(list_df$df[['sz']]$reg_per),',', max(list_df$df[['sz']]$reg_per),')',sep=''))


###
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'cesm_cl'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, fig_nm='fig4', graph=0, data_nm='CESM-cloud', compressor_nm=comp_red[k], error_mode, error_bnd)    }
##
scatterplot_sz_3modes_prediction(gam_res, fig_nm='fig4', data_nm='CESM-cloud', error_bnd, error_mode)
##
print('Median (min, max) percentage usage of regression mode in SZ2:')
print(paste(median(list_df$df[['sz']]$reg_per),' (',min(list_df$df[['sz']]$reg_per),',', max(list_df$df[['sz']]$reg_per),')',sep=''))


###
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-3
dataset <- 'gaussian_singlescale'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, graph=0, fig_nm='fig4',  data_nm = 'Gaussian-single-scale', compressor_nm=comp_red[k], error_mode, error_bnd)    }
##
scatterplot_sz_3modes_prediction(gam_res, fig_nm='fig4', data_nm = 'Gaussian-single-scale', error_bnd, error_mode)
##
print('Median (min, max) percentage usage of regression mode in SZ2:')
print(paste(median(list_df$df[['sz']]$reg_per),' (',min(list_df$df[['sz']]$reg_per),',', max(list_df$df[['sz']]$reg_per),')',sep=''))


###
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-3
dataset <- 'scale_pres'
source('load_dataset_paper.R')
list_df <-  extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, graph=0, fig_nm='fig4', data_nm='SCALE-pressure', compressor_nm=comp_red[k], error_mode, error_bnd)    }
##
scatterplot_sz_3modes_prediction(gam_res, fig_nm='fig4', data_nm='SCALE-pressure', error_bnd, error_mode)
##
print('Median (min, max) percentage usage of regression mode in SZ2:')
print(paste(median(list_df$df[['sz']]$reg_per),' (',min(list_df$df[['sz']]$reg_per),',', max(list_df$df[['sz']]$reg_per),')',sep=''))



print('#############################################')
print('Predictor importance associated with figure 4')

set.seed(1234)
comp_red <- c('sz','interpolation','lorenzo','regression')
source('functions_paper.R')

error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_vx'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (k in  1:length(comp_red)){
  print(comp_red[k])
  lasso_selection(df=list_df$df[[comp_red[k]]],  print=1)  }

##
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-3
dataset <- 'scale_pres'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (k in  1:length(comp_red)){
  print(comp_red[k])
  lasso_selection(df=list_df$df[[comp_red[k]]],  print=1)  }

##
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-3
dataset <- 'gaussian_singlescale'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (k in  1:length(comp_red)){
  print(comp_red[k])
  lasso_selection(df=list_df$df[[comp_red[k]]],  print=1)  }

##
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'cesm_cl'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (k in  1:length(comp_red)){
  print(comp_red[k])
  lasso_selection(df=list_df$df[[comp_red[k]]],  print=1)  }




########################################################################
########################################################################
## Table 3 - different compressors and datasets

source('functions_paper.R')
comp_red <- c('sz','zfp','mgard','digit_rounding')

print('#############################################')
print('Printing validation statistics of Table  3')
##

set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'Miranda Vx', error_mode, error_bnd) }


##
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_de'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'Miranda De.', error_mode, error_bnd)  }}


###
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-2
dataset <- 'nyx_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'NYX Vx', error_mode, error_bnd)  } }


###
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-3
dataset <- 'scale_u'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    print(cmp)
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'SCALE U', error_mode, error_bnd)  }}


###
set.seed(1234)
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'cesm_cl'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    print(cmp)
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'CESM cloud', error_mode, error_bnd)  }}


###
set.seed(1234)
error_mode <- 'abs' 
error_bnd <- 1e-2
dataset <- 'hurricane_qg'
source('load_dataset_paper.R')
source('functions_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    print(cmp)
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'Hurricane QGRAUP', error_mode, error_bnd)  }}



########################################################################
########################################################################
## GRAPH 5: Results on aggregating prediction error across fields

set.seed(1234)
source('functions_paper.R')
comp_red <- c('sz','zfp','mgard','digit_rounding')

### Miranda 
data0 <- read.csv('./generated_data/dataframe_output_miranda_feb27.csv')
data0 <- as.data.frame(data0)
data0 <- filter(data0, dim2 == 384)
var_nm <- unique(data0$info.filename)[-c(5,6)]

error_mode <- 'abs'
error_bnd <- 1e-5

APE <- NULL
COMP <- NULL
FIELD <- NULL
MeanAPE <- matrix(0, length(comp_red), length(var_nm))
MaxAPE <- matrix(0, length(comp_red), length(var_nm))
for (j in 1:length(var_nm)){
  for (i in  1:length(comp_red)){
    data <- filter(data0, info.filename == var_nm[j])
    list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=0, sz3=FALSE, comp_thresh=100)
    APE[[(j-1)*length(comp_red) + i]] <- NA
    COMP[[(j-1)*length(comp_red) + i]] <- NA
    FIELD[[(j-1)*length(comp_red) + i]] <- NA
    if (dim(list_df$df[[comp_red[i]]])[1] > 10 ){
      gam0 <- cr_regression_gam_cv(df=list_df$df[[comp_red[i]]], kf=4, print_stats=0, comp_thresh=100)
      APEi <- 100*c(unlist(abs(gam0$pred - gam0$ytest)/gam0$ytest))
      MeanAPE[i,j] <- mean(APEi, na.rm=TRUE)
      MaxAPE[i,j] <- max(APEi, na.rm=TRUE)
      APE[[(j-1)*length(comp_red) + i]] <- APEi 
      COMP[[(j-1)*length(comp_red) + i]] <- comp_red[i]
      FIELD[[(j-1)*length(comp_red) + i]] <- var_nm[j]   } } }

col_cmp <- c(unlist(COMP))
col_cmp[col_cmp=='sz'] <- 16
col_cmp[col_cmp=='zfp'] <- 2 
col_cmp[col_cmp=='mgard'] <- 3
col_cmp[col_cmp=='digit_rounding'] <- 4
col_cmp <- as.numeric(col_cmp)

max_fields <- apply(X=MaxAPE, MARGIN=1, FUN=max)
leg_lab <- paste('(',round(rowMeans(MeanAPE),1),'%, ', round(max_fields,1),'%)', sep='')
fields_nm <- c('Vy', 'De', 'Pres.', 'Vx', 'Vz')

graphics.off()
png(filename = paste('fig6_miranda_mean_predictionerror_allfields.png', sep=''), width=600, height=400)
par(mar=c(4.9, 4.1, 5, 1), mgp=c(2.2,0.5,0))
boxplot(APE, pch=20, xaxt='n', col=col_cmp, outcol=col_cmp, cex=1.4, cex.lab=1.9, cex.axis=1.8, ylab='Absolute percentage error (%)', ylim=c(0,55))
points(c(MeanAPE), pch='x', col='white', cex=1.7)
axis(1, at=seq(2.5,length(APE),by=4), labels=fields_nm, las=2, cex.axis=1.9)
title('Miranda all fields', cex.main=1.7, line=3.5)
legend(x='topright', leg_lab, col=c(16,2:4), pch=NA, bty='n', cex=1.5, horiz='TRUE', inset=c(-.07,-.13), xpd=TRUE, text.width=c(5,5,5,6), x.intersp=0.5)
legend(x='topright', c('SZ ','ZFP ','MGARD ','Digit Rounding '), col=c(16,2:4), pch=rep(20,4), bty='n', cex=1.5, horiz='TRUE', inset=c(0.05,-.2), xpd=TRUE, text.width=c(4.2,4,3.5,3.2), x.intersp=0.5)
dev.off()



### Scale LetKF
source('functions_paper.R')
comp_red <- c('sz','zfp','mgard','digit_rounding')
data0 <- read.csv('./generated_data/dataframe_output_scale_mar14.csv')
data0 <- as.data.frame(data0)
var_nm <- unique(data0$info.filename)[c(2,4,5,6,7,9,11)]

error_mode <- 'abs'
error_bnd <- 1e-5

APE <- NULL
COMP <- NULL
FIELD <- NULL
MeanAPE <- matrix(0, length(comp_red), length(var_nm))
MaxAPE <- matrix(0, length(comp_red), length(var_nm))
for (j in 1:length(var_nm)){
  for (i in  1:length(comp_red)){
    data <- filter(data0, info.filename == var_nm[j])
    list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=0, sz3=FALSE)
    APE[[(j-1)*length(comp_red) + i]] <- NA
    COMP[[(j-1)*length(comp_red) + i]] <- NA
    FIELD[[(j-1)*length(comp_red) + i]] <- NA
    if (dim(list_df$df[[comp_red[i]]])[1] > 20 ){
      gam0 <- cr_regression_gam_cv(df=list_df$df[[comp_red[i]]], kf=8, print_stats=0, comp_thresh=100)
      APEi <- 100*c(unlist(abs(gam0$pred - gam0$ytest)/gam0$ytest))
      MeanAPE[i,j] <- mean(APEi, na.rm=TRUE)
      MaxAPE[i,j] <- max(APEi, na.rm=TRUE)
      APE[[(j-1)*length(comp_red) + i]] <- APEi 
      COMP[[(j-1)*length(comp_red) + i]] <- comp_red[i]
      FIELD[[(j-1)*length(comp_red) + i]] <- var_nm[j]   } } }

col_cmp <- c(unlist(COMP))
col_cmp[col_cmp=='sz'] <- 16
col_cmp[col_cmp=='zfp'] <- 2 
col_cmp[col_cmp=='mgard'] <- 3
col_cmp[col_cmp=='digit_rounding'] <- 4
col_cmp <- as.numeric(col_cmp)

max_fields <- apply(X=MaxAPE, MARGIN=1, FUN=max)
leg_lab <- paste('(',round(rowMeans(MeanAPE),1),'%, ', round(max_fields,1),'%)', sep='')
fields_nm <- c('Pres.', "T", "U", "V", "QV", "RH", "W")

graphics.off()
png(filename = paste('fig6_scale_mean_predictionerror_allfields.png', sep=''), width=600, height=400)
par(mar=c(4.9, 4.1, 5, 1), mgp=c(2.2,0.5,0))
boxplot(APE, pch=20, xaxt='n', col=col_cmp, outcol=col_cmp, cex=1.7, cex.lab=2, cex.axis=2, ylab='Absolute percentage error (%)')
points(c(MeanAPE), pch='x', col='white', cex=1.7)
axis(1, at=seq(2.5,length(APE),by=4), labels=fields_nm, las=2, cex.axis=1.9)
title('SCALE LetKF all fields', cex.main=1.7, line=3.5)
legend(x='topright', leg_lab, col=c(16,2:4), pch=NA, bty='n', cex=1.5, horiz='TRUE', inset=c(0.3,-.13), xpd=TRUE, text.width=c(4.2,3.5,2,-2), x.intersp=0.5)
legend(x='topright', c('SZ ','ZFP ','MGARD ','Digit Rounding '), col=c(16,2:4), pch=rep(20,4), bty='n', cex=1.5, horiz='TRUE', inset=c(0.25,-.2), xpd=TRUE, text.width=c(4.2,3.5,2.3,-1.3), x.intersp=0.5)
dev.off()




########################################################################
########################################################################
## Section V.C: statistics of train/test ratio

source('functions_paper.R')
comp_red <- c('sz','zfp','mgard','digit_rounding')
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)

prctg_test <- seq(0.2, 0.7, by=0.1)
res_array <- array(0,c(4,length(prctg_test)))
for (i in  1:length(comp_red)){
  if (dim(list_df$df[[comp_red[i]]])[1] > 5){
    for (j in  1:length(prctg_test)){
      gam_res <- cr_regression_gam_traintest(df=list_df$df[[comp_red[i]]], kf=20, prctg_test[j], print_stats=0, compressor_nm=comp_red[i])  
      res_array[i,j] <- gam_res$res_cv[2,2]  }}}
row.names(res_array) <- comp_red

print('#############################################')
print('Percentage degradation of MedianAPE from 20%- to 70%-datasize training set on Miranda Vx')
print(round(100*(res_array[,1]-res_array[,6])/res_array[,6],1))


source('functions_paper.R')
comp_red <- c('sz','zfp','mgard','digit_rounding')
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'scale_u'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)

prctg_test <- seq(0.2, 0.7, by=0.1)
res_array <- array(0,c(4,length(prctg_test)))
for (i in  1:length(comp_red)){
  if (dim(list_df$df[[comp_red[i]]])[1] > 10){
    for (j in  1:length(prctg_test)){
      gam_res <- cr_regression_gam_traintest(df=list_df$df[[comp_red[i]]], kf=20, prctg_test[j], print_stats=0, compressor_nm=comp_red[i])  
      res_array[i,j] <- gam_res$res_cv[2,2]  }}}
row.names(res_array) <- comp_red

print('#############################################')
print('Percentage degradation of MedianAPE from 20%- to 70%-datasize training set on Scale-LetKF U')
print(round(100*(res_array[,1]-res_array[,6])/res_array[,6],1))



########################################################################
########################################################################
## Table 3

print('#############################################')
print('Printing prediction accuracy for block-sampling and Qin et al. method') 

data0 <- read.csv('./generated_data/tpds2018_cesm_CLOUD_1_26_1800_3600.csv')
data1 <- read.csv('./generated_data/ipdps2018_cesm_CLOUD_1_26_1800_3600.csv')

print('Printing results for CESM-cloud data')
source('blocksampling_analysis.R')


data0 <- read.csv('./generated_data/tpds2018_miranda_velocityx.csv')
data1 <- read.csv('./generated_data/ipdps2018_miranda_velocityx.csv')

print('Printing results for Miranda-Vx data')
source('blocksampling_analysis.R')



########################################################################
########################################################################
## GRAPH 7: regression coefficients across compressors and error bound

print('#############################################')
print('Saving figure 7')
error_mode <- 'abs'
dataset <- 'gaussian_singlescale'
source('load_dataset_paper.R')
source('functions_paper.R')
graph_nm <- paste('fig7_cr_nonABScoefficient_regression_gaussian_1scale_',error_mode,'.png', sep='')
res_coeff <- cr_regression_coeffcient(data, graph_nm=graph_nm, error_mode)

###################################
## Table 5: runtime performance for training and prediction of regression models 

print('#############################################')
print('Printing runtimes from table 5')
load('../runtime_analysis/training_benchmark_runtime_nyx.RData')
print(summary(training_bench))

load('../runtime_analysis/prediction_benchmark_runtime_nyx.RData')
print(summary(prediction_bench))

load('../runtime_analysis/training_benchmark_runtime_scale.RData')
print(summary(training_bench))

load('../runtime_analysis/prediction_benchmark_runtime_scale.RData')
print(summary(prediction_bench))
