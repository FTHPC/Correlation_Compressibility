#//TODO write test to see when global CR gets
# too high such that it starts impacting
# prediction rates
# write statistical test to verify that it does
# impact CR rate before doing above

library('pixiedust')

getStatSignificanceWilcox <- function(fdf,comp, eb) {
  tmpdf <- fdf %>% filter(compressor == comp) %>% filter(errorbound == eb)
  df_small <- tmpdf %>% filter(blocksize == 16)
  df_large <- tmpdf %>% filter(blocksize == 32)
  res <- wilcox.test(df_small$mape, df_large$mape, alternative="greater")
  return(res)
}

getStatSignificanceTTest <- function(fdf,comp, eb) {
  tmpdf <- fdf %>% filter(compressor == comp) %>% filter(errorbound == eb)
  df_small <- tmpdf %>% filter(blocksize == 16)
  df_large <- tmpdf %>% filter(blocksize == 32)
  res <- t.test(df_small$mape, df_large$mape, alternative="greater")
  return(res)
}

getStatSignificanceRho <- function(fdf,comp, eb) {
  tmpdf <- fdf %>% filter(compressor == comp) %>% filter(errorbound == eb)
  res <- cor.test(tmpdf$blocksize,tmpdf$mape,method="pearson",alternative="less")
  return(res)
}

getStatSignificanceModel_byEB <- function(fdf,comp, eb) {
  tmpdf <- fdf %>% filter(compressor == comp) %>% filter(errorbound == eb)
  m <- summary(lm(mape ~ blocksize + blockcount, data=tmpdf))
  test_stat <- (m$coefficients[2] - m$coefficients[3]) /sqrt(m$cov.unscaled[2,2] + m$cov.unscaled[3,3] - 2*m$cov.unscaled[2,3])
  pt_res <- pt(test_stat,2)
  print(paste(comp,eb, pt_res))
  print(m)
}


getStatSignificanceModel_BC <- function(fdf,comp) {
  tmpdf <- fdf %>% filter(compressor == comp)
  m <- summary(lm(mape ~ blockcount, data=tmpdf))
  print(m)
}

getStatSignificanceModel_BS <- function(fdf,comp) {
  tmpdf <- fdf %>% filter(compressor == comp)
  m <- summary(lm(mape ~ blocksize, data=tmpdf))
  print(m)
}

getStatsByEB <- function(fdf, compressors, error_bnds) {
  for (i in 1:length(compressors)) {
    print("##################################################################")
    comp <- compressors[i]
    for (bound in error_bnds) {
      res <- getStatSignificanceModel_byEB(fdf,comp,bound)
      print(paste(comp,bound,res))
      #print("==================================================================")
    }
  }
}

getStatSignificanceModel_IQR <- function(fdf,comp) {
  tmpdf <- fdf %>% filter(compressor == comp)
  m <- summary(lm(quartilerange ~ blocksize + blockcount, data=tmpdf))
  # in numerator, we're looking at beta coefficients (b1 - b2)
  # in denominator, we're taking the square root of the standardized errors (sqrt(stderr(b1)) + sqrt(stderr(b2)) - 2*covariance)
  test_stat <- (m$coefficients[2] - m$coefficients[3]) / sqrt(m$cov.unscaled[2,2] + m$cov.unscaled[3,3] - 2*m$cov.unscaled[2,3])
  pt_res <- pt(test_stat,2) # 2 degrees of freedom
  print(paste(comp, pt_res))
  print(m)
}
getStats_IQR <- function(fdf) {
  for (comp in unique(fdf$compressor)) {
    print("##################################################################")
    res <- getStatSignificanceModel_IQR(fdf,comp)
  }
}

getStatSignificanceModel <- function(fdf,comp) {
  tmpdf <- fdf %>% filter(compressor == comp)
  m <- summary(lm(mape ~ blocksize + blockcount, data=tmpdf))
  # in numerator, we're looking at beta coefficients (b1 - b2)
  # in denominator, we're taking the square root of the standardized errors (sqrt(stderr(b1)) + sqrt(stderr(b2)) - 2*covariance)
  test_stat <- (m$coefficients[2] - m$coefficients[3]) / sqrt(m$cov.unscaled[2,2] + m$cov.unscaled[3,3] - 2*m$cov.unscaled[2,3])
  pt_res <- pt(test_stat,2) # 2 degrees of freedom
  print(paste(comp, pt_res))
  print(m)
}
getStats <- function(fdf) {
  for (comp in unique(fdf$compressor)) {
    print("##################################################################")
    res <- getStatSignificanceModel(fdf,comp)
  }
}


getStatSignificanceModel_byEB_relerr <- function(accdf,comp, eb) {
  tmpdf <- accdf %>% filter(compressor == comp) %>% filter(errorbound == eb)
  m <- summary(lm(relerr ~ blocksize + blockcount, data=tmpdf))
  test_stat <- (m$coefficients[2] - m$coefficients[3]) /sqrt(m$cov.unscaled[2,2] + m$cov.unscaled[3,3] - 2*m$cov.unscaled[2,3])
  pt_res <- pt(test_stat,2)
  print(paste(comp,eb, pt_res))
  print(m)
}

getStatsByEB_relerr <- function(accdf) {
  for (i in 1:length(unique(accdf$compressor))) {
    print("##################################################################")
    comp <- unique(compressors)[i]
    for (bound in unique(accdf$errorbound)) {
      getStatSignificanceModel_byEB_relerr(accdf,comp,bound)
      print("==================================================================")
      #print(paste(comp,bound,res))
    }
  }
}

runTwoSampleTTest <- function(stride_fdf, uniform_fdf,filterBS = TRUE,bs=28,bc=24) {
  if(!filterBS) {
    tmp_stride <- stride_fdf
    tmp_uniform <- uniform_fdf
  } else {
    tmp_stride <- stride_fdf %>% filter(blocksize == 28) %>% filter(blockcount == 24)
    tmp_uniform <- uniform_fdf %>% filter(blocksize == 28) %>% filter(blockcount == 24)
  }
  print(t.test(tmp_stride$mape, tmp_uniform$mape, var.equal=FALSE))
}
runTTest <- function(stride_fdf, uniform_fdf,filterBS = TRUE,bs=28,bc=24) {
  comps <- unique(stride_fdf$compressor)
  for(comp in comps) {
    tmp_stride <- stride_fdf %>% filter(compressor == comp)
    tmp_uniform <- uniform_fdf %>% filter(compressor == comp)
    print(comp)
    runTwoSampleTTest(tmp_stride, tmp_uniform, filterBS,bs,bc)
  }
}


