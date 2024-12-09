#rm(list=ls())
suppressPackageStartupMessages({
  library('tidyverse')
  library('gtools')
  library('data.table')
  library('dplyr')
  library('rhdf5') #hdf5 library
  library('reshape2')
  library('stringr')
  library('fields') #variograms
  library('mgcv') #generalized additive modeling
  library('glmnet') #generalized linear model via penalized max likelihood (lasso,elasticnet)
  library('rTensor')
})

### read data
read_data <-function(app, compressor,blocksize,exclude=NA){
  #print(compressor)
  name <- paste0("../outputs/",app,"*",compressor, "_blocks128_block_size",blocksize,".csv")
  #print(name)
  filenames <- Sys.glob(name)
  if (!is.na(exclude)) {
    filenames <- grep(exclude, filenames, invert=TRUE, value = TRUE)
  } 
  #print(filenames)
  
  fdf <- c()
  for (filename in filenames) {
    print(filename)
    data <- read.csv(filename)
    data <- as.data.frame(data)
    #
    data <- data[1:(length(data)-1)]
    #
    data$size.compression_ratio <- as.numeric(data$size.compression_ratio)
    data$error_stat.value_std <- as.numeric(data$error_stat.value_std)
    data$error_stat.value_std[is.na(data$error_stat.value_std)] <- 1e-8
    data$error_stat.value_std[data$error_stat.value_std == 0] <- 1e-8
    
    data$global.compression_ratio <- as.numeric(data$global.compression_ratio)
    data$global.value_std <- as.numeric(data$global.value_std)
    data$global.value_std[is.na(data$global.value_std)] <- 1e-8
    data$global.value_std[data$global.value_std == 0] <- 1e-8
    data$block.number <- as.integer(data$block.number)
    data$block.total_count <- as.numeric(data$block.total_count)
    #
    fdf <- rbind(fdf,data)
  }
  
  return(fdf)
}

### limits amount of data based on blockcount
select_data <- function(data, blockcount, buffers, compressors, errorbounds, samplemode){
  limited_df <- data.frame()
  #
  max_block <- data$block.total_count[1]
  if (blockcount <= max_block) {
    if (samplemode == "STRIDE") {
      stride <- floor(max_block/blockcount)
      smpl <- seq(from=1, to=max_block, by=stride)
      subsample <- smpl[1:blockcount]
    }
    if (samplemode == "UNIFORM") {
      subsample <- sample(1:max_block,blockcount,FALSE)
    }
    #
    for (comp in compressors) {
      for (eb in errorbounds){ 
        filtered <- data %>% 
                    filter(info.error_bound == eb) %>% 
                    filter(info.compressor == comp)
        if (!nrow(filtered)) { 
          print(paste0(comp,",",eb, " does not have any data points. skipping."))
          next 
        }
        if (length(unique(filtered$info.filename)) < buffers) { 
          print(paste0(comp,",",eb," only has ", length(unique(filtered$info.filename))," buffers."))
          #next 
        }
        #TODO: randomly select subsample from each buffer - need to group by file?
        #if (samplemode == "RANDOM") {}
        
        #sample each buffer 'block_count' times
        df <- filtered %>% filter(block.number %in% subsample)
        limited_df <- rbind(limited_df, df)
      }
    }
  } else {
    print(paste0("insufficient blocks for blockcount ", blockcount,
                 ". max block=",max_block,". skipping."))
  }
  return(limited_df)
}

### extract data 
extract_cr_predictors <- function(data, errormode, errorbound, comp, thresh=200){
  df <- data %>%
    filter(info.bound_type == errormode) %>%
    filter(info.error_bound == errorbound) %>%
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


### limits amount of data based on blockcount
select_data_allEB <- function(data, blockcount, buffers, compressors, samplemode){
  limited_df <- data.frame()
  #
  max_block <- data$block.total_count[1]
  if (blockcount <= max_block) {
    if (samplemode == "STRIDE") {
      stride <- floor(max_block/blockcount)
      smpl <- seq(from=1, to=max_block, by=stride)
      subsample <- smpl[1:blockcount]
    } else {
      subsample <- sample(1:max_block,blockcount,FALSE)
    }
    #
    for (comp in compressors) {
      filtered <- data %>% 
        filter(info.compressor == comp)
      if (!nrow(filtered)) { 
        print(paste0(comp," does not have any data points. skipping."))
        next 
      }
      if (length(unique(filtered$info.filename)) < buffers) { 
        print(paste(comp,"only has", length(unique(filtered$info.filename)),"buffers. expected", buffers, "buffers"))
        #next 
      }
      #sample each buffer 'block_count' times
      df <- filtered %>% filter(block.number %in% subsample)
      limited_df <- rbind(limited_df, df)
    }
  } else {
    print(paste0("insufficient blocks for blockcount ", blockcount,
                 ". max block=",max_block,". skipping."))
  }
  return(limited_df)
}


### extract data 
extract_cr_predictors_allEB <- function(data, errormode, comp, thresh=200){
  df <- data %>%
    filter(info.bound_type == errormode) %>%
    filter(info.compressor == comp) %>%
    filter(global.compression_ratio < thresh)
  
  ## local per block stats
  cr_local <- df$size.compression_ratio
  std <- df$error_stat.value_std
  
  # global stats
  cr_global <- df$global.compression_ratio
  std_global <- df$global.value_std
  
  errorbound <- df$info.error_bound
  
  # distances
  loc <- df$loc
  
  # file identfier
  file <- df$info.filename
  
  df <- data.frame(cr_local, std, cr_global, std_global, loc, file, errorbound)
  return(df)
}

### read data
read_data_interactive <-function(app, compressor,blocksize,exclude=NA){
  #print(compressor)
  name <- paste0("outputs/",app,"*",compressor, "_blocks128_block_size",blocksize,".csv")
  #print(name)
  filenames <- Sys.glob(name)
  if (!is.na(exclude)) {
    filenames <- grep(exclude, filenames, invert=TRUE, value = TRUE)
  } 
  #print(filenames)
  
  fdf <- c()
  for (filename in filenames) {
    print(filename)
    data <- read.csv(filename)
    data <- as.data.frame(data)
    #
    data <- data[1:(length(data)-1)]
    #
    data$size.compression_ratio <- as.numeric(data$size.compression_ratio)
    data$error_stat.value_std <- as.numeric(data$error_stat.value_std)
    data$error_stat.value_std[is.na(data$error_stat.value_std)] <- 1e-8
    data$error_stat.value_std[data$error_stat.value_std == 0] <- 1e-8
    
    data$global.compression_ratio <- as.numeric(data$global.compression_ratio)
    data$global.value_std <- as.numeric(data$global.value_std)
    data$global.value_std[is.na(data$global.value_std)] <- 1e-8
    data$global.value_std[data$global.value_std == 0] <- 1e-8
    data$block.number <- as.integer(data$block.number)
    data$block.total_count <- as.numeric(data$block.total_count)
    #
    fdf <- rbind(fdf,data)
  }
  
  return(fdf)
}

