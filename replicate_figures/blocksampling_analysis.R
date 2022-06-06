
#rm(list=ls())

#data <- read.csv('revisions_sc22_blocksampling/block_sample_miranda_velocityx.csv')
#data <- read.csv('revisions_sc22_blocksampling/block_sample_scale_U-98x1200x1200.csv')
#data0 <- read.csv('revisions_sc22_blocksampling/block_sample_cesm_CLOUD_1_26_1800_3600.csv')
data <- as.data.frame(data0)
data <- filter(data, size.error_bound==1e-3)
data0 <- filter(data, info.is_sample=='False')
cr0 <- data0$size.compression_ratio
cr0 <- cr0[cr0<100]

dataS <- filter(data, info.is_sample=='True')
crS <- matrix(dataS$size.compression_ratio, 10, length(dataS$size.compression_ratio)/10)
crS <- crS[,which(cr0<100)]
crS_mu <- colMeans(crS)

ape <-100*abs(cr0-crS_mu)/cr0
print('10th, 50th and 90th quantile of abs. percentage error for block-sampling')
print(round(quantile(x=ape, prob=c(.1,.5,.9)),1))

#matplot(t(crS), pch=20, col=1, ylim=c(0, max(cr0)))
#points(cr0, col=2, pch='+', cex=2)

########################################################

#rm(list=ls())

#data1 <- read.csv('revisions_sc22_blocksampling/klasky_cesm_CLOUD_1_26_1800_3600.csv')
data <- as.data.frame(data1)
data <- filter(data, size.error_bound==1e-5)

cr0 <- data$actual.cr
cr0 <- cr0[cr0<100]
crE <- data$estimate.cr
crE <- crE[cr0<100]
crS <- data$sample.cr
crS <- crS[cr0<100]

ape <-100*abs(cr0-crE)/cr0
print('10th, 50th and 90th quantile of abs. percentage error for Qin et al. method')
print(round(quantile(x=ape, prob=c(.1,.5,.9)),1))

#matplot(cbind(crE, cr0, crS))