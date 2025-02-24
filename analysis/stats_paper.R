library('pixiedust')


getStatSignificanceModel <- function(fdf,comp) {
  tmpdf <- fdf %>% filter(compressor == comp)
  m <- summary(lm(mape ~ blocksize + blockcount, data=tmpdf))
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
