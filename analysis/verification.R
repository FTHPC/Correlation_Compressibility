get_actual_block_count <- function(blocksizes,dims,ret=0,prnt=0) {
  tmpdf <- c()
  for (bs in blocksizes) {
    d1 <- seq(from=0,to=dims[1]-bs, by=bs)
    d2 <- seq(from=0,to=dims[2]-bs, by=bs)
    d3 <- seq(from=0,to=dims[3]-bs, by=bs)
    max_blocks = length(d1) * length(d2) * length(d3)
    tmpdf <- rbind(tmpdf, c(bs,max_blocks))
  }
  colnames(tmpdf) <- c("block_size","max_blocks")
  if (prnt) {
    print(knitr::kable(tmpdf,format="markdown"))    
  }
  if (ret) {
    return (tmpdf)  
  }
}

getEquivalentBlockCount <- function(dims, sampleratio) {
  blocksX <- dims[1] / 4
  blocksY <- dims[2] / 4
  blocksZ <- dims[3] / 4
  
  nbBlocksX <- blocksX * (sampleratio^(1/3))
  nbBlocksY <- blocksY * (sampleratio^(1/3))
  nbBlocksZ <- blocksZ * (sampleratio^(1/3))
  
  sample_num <- nbBlocksX*nbBlocksY*nbBlocksZ
  
  return(sample_num)
}

runGetEquivalentBlockCount <- function(df, dims) {
  bcounts <- data.frame()
  for(sr in unique(df$sampleratio)) {
    bc <- getEquivalentBlockCount(dims, sr)
    bcounts <- rbind(bcounts, cbind(sr, bc))
  }
  colnames(bcounts) <- c("sampleratio", "blockcount")
  return(bcounts)
}


makeCoordinates <- function(dims,bs) {
  zLen <- length(seq(from=0,to=dims[3]-bs, by=bs))
  yLen <- length(seq(from=0,to=dims[2]-bs, by=bs))
  xLen <- length(seq(from=0,to=dims[1]-bs, by=bs))
  
  idx <- 0
  max_idx <- zLen * yLen * xLen
  coords <- c()

  while (idx < max_idx) {
    z <- ((floor(idx / (xLen*yLen))) %% zLen) * bs
    y <- (floor(idx / xLen) %% yLen) * bs
    x <- (idx %% xLen) * bs
    coords <- rbind(coords, cbind(idx,x,y,z))
    idx <- idx + 1
  }
  colnames(coords) <- c("idx","x","y","z")
  coords <- as.data.frame(coords)
  return(coords)
}

getPercentageOfDataSampled <- function(dims,blocksizes,blockcount) {
  sizes <- as.data.frame(get_actual_block_count(blocksizes,dims,ret=1))
  total_size <- dims[1] * dims[2] * dims[3]
  sizes$samples_per_block <- blocksizes*blocksizes*blocksizes
  sizes$amount_sampled <- (sizes$samples_per_block * blockcount) / total_size
  #print(knitr::kable(dims,format="markdown"))  
  #print(knitr::kable(total_size,format="markdown"))  
  print(knitr::kable(sizes,format="markdown"))  
}
runGetPercentageOfDataSampled <- function(dims,blocksizes,blockcounts) {
  for (blockcount in blockcounts) {
    getPercentageOfDataSampled(dims,blocksizes,blockcount)
    print(blockcount)
  }
}


