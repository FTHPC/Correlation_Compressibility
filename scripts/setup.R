rm(list=ls())

install.packages("BiocManager", repos = "http://cran.us.r-project.org")
install.packages('png', repos = "http://cran.us.r-project.org")

BiocManager::install("rhdf5")

install.packages('gstat', repos = "http://cran.us.r-project.org")
install.packages('microbenchmark', repos = "http://cran.us.r-project.org")
install.packages('mgcv', repos = "http://cran.us.r-project.org")
install.packages('glmnet', repos = "http://cran.us.r-project.org")
install.packages('dplyr', repos = "http://cran.us.r-project.org")
install.packages('fields', repos = "http://cran.us.r-project.org")
install.packages('pals', repos = "http://cran.us.r-project.org")
install.packages('viridis', repos = "http://cran.us.r-project.org")
