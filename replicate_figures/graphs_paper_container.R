
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

###################################
## GRAPH 1 - introduction scatterplots of CR prediction

source('functions_paper.R')

# loading data
dataset <- 'miranda_vx'
error_bnd <- 1e-5
error_mode <- 'abs'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)

# saving each panel graph
print('saving figure 1 panels and printing corresponding statistics')
res_gam_mir_sz <- cr_regression_gam(list_df$df[['sz']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='SZ2', error_mode, error_bnd)
res_gam_mir_zfp <- cr_regression_gam(list_df$df[['zfp']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='ZFP', error_mode, error_bnd)
res_gam_mir_mgard <- cr_regression_gam(list_df$df[['mgard']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='MGARD', error_mode, error_bnd)
res_gam_mir_dr <- cr_regression_gam(list_df$df[['bit_grooming']], kf=8, graph=1, fig_nm='fig1', data_nm='Miranda Vx',compressor_nm='Bit Grooming', error_mode, error_bnd)



###################################
## GRAPH 3  - predictors for Miranda and CESM

source('functions_paper.R')

error_mode <- 'abs'
dataset <- 'miranda_vx'
error_bnd <- 1e-5
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
dat_sz <- list_df$df[['sz']]

print('saving left panel of figure 3')
graphics.off()
png('fig3_predictors_miranda_vx_sz_abs1e5.png', width=300,  height = 900)
par(mfcol=c(3,1), tcl=-0.2, mai=c(0.55,0.55,.55,1.2), mar=c(5.1, 4.1, 4.1, 6))
plot(dat_sz$vargm, dat_sz$y, pch=20, xlab='SVD-trunc', ylab='Compression ratio', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7,  main='Miranda Vx - SZ2 ABS 1e-5', mgp=c(2,0.5,0), ylim=c(0,100))
#
plot(dat_sz$std, dat_sz$y, pch=20, xlab='Standard deviation',  ylab='Compression ratio', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7,  main='',mgp=c(2,0.5,0), ylim=c(0,100))
#
nc <- 50
rbPal <- colorRampPalette(c('red','blue'))
colq <- rbPal(nc)[as.numeric(cut(dat_sz$qent,breaks = nc))]
plot(dat_sz$vrgstd, dat_sz$y, pch=20, xlab='Log(SVD-trunc / Std dev.)', ylab='Compression ratio', cex=1.7, cex.lab=1.9, cex.axis=1.7, cex.main=1.7, col=colq, main='', mgp=c(2,0.5,0), ylim=c(0,100))
image.plot(legend.only = TRUE, zlim=range(sort(dat_sz$qent), na.rm=TRUE), col=rbPal(20)[as.numeric(cut(sort(dat_sz$qent),breaks = 20))], axis.args=c(cex.axis=1.7),legend.args=list( text='quantized entropy', cex=1.8, side=2))
dev.off()
#


error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'cesm_cl'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
dat_sz <- list_df$df[['zfp']]

print('saving right panel of figure 3')
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



###################################
## Table 2 - Gaussian samples

###### Table 2: prediction metrics 
comp_red <- c('sz','zfp','mgard','digit_rounding','bit_grooming')
source('functions_paper.R')
error_mode <- 'abs'
error_bnd <- 1e-3


dataset <- 'gaussian_singlescale'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian,sz3=FALSE)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, graph=0, fig_nm='', data_nm = 'Gaussian single scale', compressor_nm=comp_red[k], error_mode, error_bnd)    }

##
dataset <- 'gaussian_type1'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian,sz3=FALSE)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, graph=0, fig_nm='', data_nm = 'Gaussian type 1', compressor_nm=comp_red[k], error_mode, error_bnd)    }

##
dataset <- 'gaussian_type2'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, graph=0, fig_nm='', data_nm = 'Gaussian type 2', compressor_nm=comp_red[k], error_mode, error_bnd)    }

##
dataset <- 'gaussian_type3'
print(dataset)
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, graph=0, fig_nm='', data_nm = 'Gaussian type 3', compressor_nm=comp_red[k], error_mode, error_bnd)    }



###################################
## GRAPH 4  - SZ and different prediction modes

###### scatterplots and Table 2: prediction metrics 

comp_red <- c('sz','interpolation','lorenzo','regression')
source('functions_paper.R')

error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
gam_res <- NULL
for (k in  1:length(comp_red)){
  gam_res[[k]] <- cr_regression_gam(df=list_df$df[[comp_red[k]]], kf=8, fig_nm='fig4', graph=0, data_nm = 'Miranda-Vx', error_mode, error_bnd)    }
##
scatterplot_sz_3modes_prediction(gam_res, fig_nm='fig4', data_nm = 'Miranda-Vx', error_bnd, error_mode)


###
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


###
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


###
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



###### Predictor importance with LASSO regression

comp_red <- c('sz','interpolation','lorenzo','regression')
source('functions_paper.R')

error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (k in  1:length(comp_red)){
  print(comp_red[k])
  lasso_selection(df=list_df$df[[comp_red[k]]],  print=1)  }


##
error_mode <- 'abs'
error_bnd <- 1e-3
dataset <- 'gaussian_singlescale'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (k in  1:length(comp_red)){
  print(comp_red[k])
  lasso_selection(df=list_df$df[[comp_red[k]]],  print=1)  }



###################################
## Table 4 - different compressors and datasets

source('functions_paper.R')

comp_red <- c('sz','zfp','mgard','digit_rounding')

###### table 1: prediction metrics 
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'Miranda Vx', error_mode, error_bnd) }


##
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'miranda_de'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'Miranda De.', error_mode, error_bnd)
  }
}


###
error_mode <- 'abs'
error_bnd <- 1e-2
dataset <- 'nyx_vx'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'NYX Vx', error_mode, error_bnd)  } }


###
error_mode <- 'abs'
error_bnd <- 1e-3
dataset <- 'scale_u'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    print(cmp)
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'SCALE U', error_mode, error_bnd)
  }
}


###
error_mode <- 'abs'
error_bnd <- 1e-5
dataset <- 'cesm_cl'
source('load_dataset_paper.R')
list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    print(cmp)
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'CESM cloud', error_mode, error_bnd)
  }
}


###
error_mode <- 'abs' # 'rel' is a valid mode 
error_bnd <- 1e-2
dataset <- 'hurricane_qg'
source('load_dataset_paper.R')
source('functions_paper.R')

list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian, sz3=FALSE)
for (cmp in  comp_red){
  if (dim(list_df$df[[cmp]])[1] > 0 ){
    print(cmp)
    gami <- cr_regression_gam(df=list_df$df[[cmp]], kf=8, graph=0, fig_nm='', compressor_nm=cmp, data_nm = 'Hurricane QGRAUP', error_mode, error_bnd)
  }
}



###################################
## GRAPH 6: regression coefficients across compressors and error bound 

error_mode <- 'abs'
dataset <- 'gaussian_singlescale'
source('load_dataset_paper.R')
source('functions_paper.R')
graph_nm <- paste('fig5_cr_nonABScoefficient_regression_gaussian_1scale_',error_mode,'.png', sep='')
res_coeff <- cr_regression_coeffcient(data, graph_nm=graph_nm, error_mode)


###################################
## Table 5: runtime performance for training and prediction of regression models 

load('training_benchmark_runtime_nyx.RData')
print(summary(training_bench))

load('prediction_benchmark_runtime_nyx.RData')
print(summary(prediction_bench))

load('training_benchmark_runtime_scale.RData')
print(summary(training_bench))

load('prediction_benchmark_runtime_scale.RData')
print(summary(prediction_bench))




