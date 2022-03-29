
rm(list=ls())

#install.packages('microbenchmark', repos = "http://cran.us.r-project.org")
#install.packages('mgcv', repos = "http://cran.us.r-project.org")
#install.packages('glmnet', repos = "http://cran.us.r-project.org")

library('microbenchmark')
library('mgcv')
library('glmnet')

##############################
### training of regression models

# load and prepare data
load(file='dataframe_scale_test_runtime.RData')
x <- as.matrix(cbind(df$qent, df$vrgstd, df$qent*df$vrgstd))
y <- df$y

# lasso regression setup
lasso_reg <- function(){
  cv_model <- cv.glmnet(x, y, alpha = 1)
  best_lambda <- cv_model$lambda.min
  best_model <- glmnet(x, y, alpha = 1, lambda = best_lambda)
}

# benchmarking
training_bench <- microbenchmark(
  lasso_regression = lasso_reg,
  linear_regression =  lm(y ~ 1 + qent + vrgstd + qent*vrgstd, data = df),
  spline_regression = gam(y ~ s(qent, k=3) + s(vrgstd, k=3) + s(vrgstd, k=3) + ti(qent, vrgstd, k=5), data = df)
)

save(training_bench,file='training_benchmark_runtime_scale.RData')

##############################
### prediction with regression models

# training of models
cv_model <- cv.glmnet(x, y, alpha = 1)
best_lambda <- cv_model$lambda.min
res_lasso <- glmnet(x, y, alpha = 1, lambda = best_lambda)
res_lm <- lm(y ~ 1 + qent + vrgstd + qent*vrgstd, data = df)
res_gam <- gam(y ~ s(qent, k=3) + s(vrgstd, k=3) + s(vrgstd, k=3) + ti(qent, vrgstd, k=5), data = df)

# benchmarking
prediction_bench <- microbenchmark(
  lasso_regression = predict(res_lasso, s = best_lambda, newx = x),
  linear_regression = predict(res_lm, newdata=df),
  spline_regression = predict.gam(res_gam, df)
)

save(prediction_bench,file='prediction_benchmark_runtime_scale.RData')



##############################
### SAVING DATA - NOT TO BE RUN
# error_mode <- 'abs'
# error_bnd <- 1e-3
# dataset = 'scale_pr'
# source('load_dataset.R')
# source('functions_graphs.R')
# list_df <- extract_cr_predictors(data, error_mode, error_bnd, gaussian_corr=gaussian)
# dat_sz <- list_df$df[['sz']]
# dim(dat_sz)
# df <- data.frame(y=log(dat_sz$y), vrgstd=dat_sz$vrgstd, qent=dat_sz$qent)
# save(df,file='dataframe_scale_test_runtime.RData')
