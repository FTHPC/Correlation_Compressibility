source('init_functions.R')

############################################################################################################################
gen_new_figs = FALSE
gen_scatterplots = FALSE
#---------------------------------------------------------------------------------------------------------------------------
bit_grooming <- "bit_grooming"
sperr <- "sperr"
sz <- "sz"
sz3 <- "sz3"
tthresh <- "tthresh"
zfp <- "zfp"
#---------------------------------------------------------------------------------------------------------------------------
linear <- "linear"
mixed <- "mixed"
flexmix <- "flexmix"
stride <- "stride"
uniform <- "uniform"
#---------------------------------------------------------------------------------------------------------------------------
hurricane <- "Hurricane_Isabel"
cloud <- "hurricane_CLOUD"
pf <- "hurricane_P"
vf <- "hurricane_V"
uf <- "hurricane_U"
qcloud <- "hurricane_QCLOUD"
qgraup <- "hurricane_QGRAUP"
qice <- "hurricane_QICE"
qrain <- "hurricane_QRAIN"
precip <- "hurricane_PRECIP"
qrain <- "hurricane_QRAIN"
tc <- "hurricane_TC"
multi <- "hurricane_multi"
step48 <- "hurricane_step48"
miranda <- "Miranda"
qmcpack <- "qmcpack"
scale <- "SCALE_LETKF"
nyx <- "NYX"
#---------------------------------------------------------------------------------------------------------------------------
dims_miranda <- c(256,384,384)
dims_qmcpack <- c(69,69,115)
dims_hurricane <- c(100,500,500)
dims_scale <- c(98,1200,1200)
dims_nyx <- c(512,512,512)
#---------------------------------------------------------------------------------------------------------------------------
generic_limits <- c(100,100,100,100,100,100)
cloud_limits <- c(10,15,10,20,30,15)
cloud_mixed_limits <- c(5,5.3,5.3,5.3,20,5)
multi_limits <- c(20,25,30,30,50,35)
multi_mixed_limits <- c(5,5,5,5,15,5)
p_limits <- c(1,2,2,2,1)
precip_limits <- c(4,20,15,15,15)
precip_mixed_limits <- c(5,10,5.5,5.1,5)
qice_limits <- c(10,10,10,10,25,10)
qrain_limits <- c(20,20,10,15,25)
qrain_mixed_limits <- c(5,5,5,5,5)
qcloud_mixed_limits <- c(10,10,10,10,50,10)
qgraup_mixed_limits <- c(2,30,10,5.1,50,5)
step48_limits <- c(100,100,100,100,100)
tc_limits <- c(1,5,5.5,5,1)
tc_mixed_limits <- c(1,5,5.5,5,1)
miranda_limits <- c(25,100,100,100,100)
miranda_mixed_limits <- c(20,50,50,50,50)
scale_limits <- c(100,100,100,100,100)
qmcpack_limits <- c(10,25,30,30,30,20)
#---------------------------------------------------------------------------------------------------------------------------
cloud_alleb_limits <- c(10,15,10,20,30,15)
step48_alleb_limits <- c(20,50,50,50,50)
############################################################################################################################
# HURRICANE CLOUD
############################################################################################################################
hurricane_CLOUD_stride_linear_fdf <- getFDF("hurricane_CLOUD",stride,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_CLOUD_uniform_linear_fdf <- getFDF("hurricane_CLOUD",uniform,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_CLOUD_stride_flexmix_fdf <- getFDF("hurricane_CLOUD",stride,flexmix)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_CLOUD_uniform_flexmix_fdf <- getFDF("hurricane_CLOUD",uniform,flexmix)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_CLOUD_stride_mixed_fdf <- getFDF("hurricane_CLOUD",stride,mixed)
# cloud_sm_predictions <- getPredictionsVsReal(hurricane_CLOUD_stride_mixed_fdf,"hurricane_CLOUD",stride,mixed)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_CLOUD_uniform_mixed_fdf <- getFDF("hurricane_CLOUD",uniform,mixed)
# cloud_um_predictions <- getPredictionsVsReal(hurricane_CLOUD_uniform_mixed_fdf,"hurricane_CLOUD",uniform,mixed)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_CLOUD_stride_linear_allEB_fdf <- getFDF("hurricane_CLOUD",stride,linear,TRUE)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_CLOUD_uniform_linear_allEB_fdf <- getFDF("hurricane_CLOUD",uniform,linear,TRUE)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_CLOUD_stride_flexmix_allEB_fdf <- getFDF("hurricane_CLOUD",stride,flexmix,TRUE)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_CLOUD_uniform_flexmix_allEB_fdf <- getFDF("hurricane_CLOUD",uniform,flexmix,TRUE)

############################################################################################################################
# MIRANDA
############################################################################################################################
miranda_stride_linear_fdf <- getFDF("Miranda",stride,linear)
#---------------------------------------------------------------------------------------------------------------------------
miranda_uniform_linear_fdf <- getFDF("Miranda",uniform,linear)
#---------------------------------------------------------------------------------------------------------------------------
miranda_stride_flexmix_fdf <- getFDF("Miranda",stride,flexmix)
#---------------------------------------------------------------------------------------------------------------------------
miranda_uniform_flexmix_fdf <- getFDF("Miranda",uniform,flexmix)
# #---------------------------------------------------------------------------------------------------------------------------
# miranda_stride_mixed_fdf <- getFDF("Miranda",stride,mixed)
# miranda_sm_predictions <- getPredictionsVsReal(miranda_stride_mixed_fdf,"Miranda",stride,mixed)
# #---------------------------------------------------------------------------------------------------------------------------
# miranda_uniform_mixed_fdf <- getFDF("Miranda",uniform,mixed)
# miranda_um_predictions <- getPredictionsVsReal(miranda_uniform_mixed_fdf,"Miranda",uniform,mixed)

############################################################################################################################
# HURRICANE Multi
############################################################################################################################
hurricane_multi_stride_linear_fdf <- getFDF("hurricane_multi",stride,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_multi_uniform_linear_fdf <- getFDF("hurricane_multi",uniform,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_multi_stride_flexmix_fdf <- getFDF("hurricane_multi",stride,flexmix)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_multi_uniform_flexmix_fdf <- getFDF("hurricane_multi",uniform,flexmix)

############################################################################################################################
# HURRICANE All
############################################################################################################################
hurricane_uniform_flexmix_allEB_predictions <- hurricane_uniform_flexmix_allEB_predictions[-(which(hurricane_uniform_flexmix_allEB_predictions$compressor %in% "bit_grooming")),]

#hurricane_global <- hurricane_global[~(which(hurricane_global$compressor))]

hurricane_global <- hurricane_global[-(which(hurricane_global$compressor %in% "bit_grooming")),]
names(hurricane_global)[names(hurricane_global)=="globalCR"] <- "real"

############################################################################################################################
# Hurricane P
############################################################################################################################
hurricane_Pf_stride_linear_fdf <- getFDF("hurricane_Pf",stride,linear)
hurricane_Pf_stride_linear_fdf$app <- "hurricane_P"
#---------------------------------------------------------------------------------------------------------------------------
hurricane_Pf_uniform_linear_fdf <- getFDF("hurricane_Pf",uniform,linear)
hurricane_Pf_uniform_linear_fdf$app <- "hurricane_P"
#---------------------------------------------------------------------------------------------------------------------------
hurricane_Pf_stride_flexmix_fdf <- getFDF("hurricane_Pf",stride,flexmix)
hurricane_Pf_stride_flexmix_fdf$app <- "hurricane_P"
#---------------------------------------------------------------------------------------------------------------------------
hurricane_Pf_uniform_flexmix_fdf <- getFDF("hurricane_Pf",uniform,flexmix)
hurricane_Pf_uniform_flexmix_fdf$app <- "hurricane_P"
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_Pf_stride_mixed_fdf <- getFDF("hurricane_Pf",stride,mixed)
# hurricane_Pf_stride_mixed_fdf$app <- "hurricane_P"
# pf_sm_predictions <- getPredictionsVsReal(hurricane_Pf_stride_mixed_fdf,"hurricane_Pf",stride,mixed)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_Pf_uniform_mixed_fdf <- getFDF("hurricane_Pf",uniform,mixed)
# hurricane_Pf_uniform_mixed_fdf$app <- "hurricane_P"
# pf_um_predictions <- getPredictionsVsReal(hurricane_Pf_uniform_mixed_fdf,"hurricane_Pf",uniform,mixed)

############################################################################################################################
# Hurricane PRECIP
############################################################################################################################
hurricane_PRECIP_stride_linear_fdf <- getFDF("hurricane_PRECIP",stride,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_PRECIP_uniform_linear_fdf <- getFDF("hurricane_PRECIP",uniform,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_PRECIP_stride_flexmix_fdf <- getFDF("hurricane_PRECIP",stride,flexmix)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_PRECIP_uniform_flexmix_fdf <- getFDF("hurricane_PRECIP",uniform,flexmix)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_PRECIP_stride_mixed_fdf <- getFDF("hurricane_PRECIP",stride,mixed)
# precip_sm_predictions <- getPredictionsVsReal(hurricane_PRECIP_stride_mixed_fdf,"hurricane_PRECIP",stride,mixed)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_PRECIP_uniform_mixed_fdf <- getFDF("hurricane_PRECIP",uniform,mixed)
# precip_um_predictions <- getPredictionsVsReal(hurricane_PRECIP_uniform_mixed_fdf,"hurricane_PRECIP",uniform,mixed)

############################################################################################################################
# Hurricane QRAIN
############################################################################################################################
hurricane_QRAIN_stride_linear_fdf <- getFDF("hurricane_QRAIN",stride,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_QRAIN_uniform_linear_fdf <- getFDF("hurricane_QRAIN",uniform,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_QRAIN_stride_flexmix_fdf <- getFDF("hurricane_QRAIN",stride,flexmix)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_QRAIN_uniform_flexmix_fdf <- getFDF("hurricane_QRAIN",uniform,flexmix)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_QRAIN_stride_mixed_fdf <- getFDF("hurricane_QRAIN",stride,mixed)
# qrain_sm_predictions <- getPredictionsVsReal(hurricane_QRAIN_stride_mixed_fdf,"hurricane_QRAIN",stride,mixed)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_QRAIN_uniform_mixed_fdf <- getFDF("hurricane_QRAIN",uniform,mixed)
# qrain_um_predictions <- getPredictionsVsReal(hurricane_QRAIN_uniform_mixed_fdf,"hurricane_QRAIN",uniform,mixed)
############################################################################################################################
# Hurricane QCLOUD
############################################################################################################################
#hurricane_qcloud_stride_linear_fdf <- getFDF("hurricane_QCLOUD",stride,linear)
#hurricane_qcloud_uniform_linear_fdf <- getFDF("hurricane_QCLOUD",uniform,linear)
hurricane_qcloud_stride_flexmix_fdf <- getFDF("hurricane_QCLOUD",stride,flexmix)
hurricane_qcloud_uniform_flexmix_fdf <- getFDF("hurricane_QCLOUD",uniform,flexmix)

############################################################################################################################
# Hurricane QGRAUP
############################################################################################################################
#hurricane_qgraup_stride_linear_fdf <- getFDF("hurricane_QGRAUP",stride,linear)
#hurricane_qgraup_uniform_linear_fdf <- getFDF("hurricane_QGRAUP",uniform,linear)
hurricane_qgraup_stride_flexmix_fdf <- getFDF("hurricane_QGRAUP",stride,flexmix)
hurricane_qgraup_uniform_flexmix_fdf <- getFDF("hurricane_QGRAUP",uniform,flexmix)

############################################################################################################################
# Hurricane U
############################################################################################################################
#hurricane_u_stride_linear_fdf <- getFDF("hurricane_U",stride,linear)
#hurricane_u_uniform_linear_fdf <- getFDF("hurricane_U",uniform,linear)
hurricane_u_stride_flexmix_fdf <- getFDF("hurricane_U",stride,flexmix)
hurricane_u_uniform_flexmix_fdf <- getFDF("hurricane_U",uniform,flexmix)

############################################################################################################################
# Hurricane Step 48
############################################################################################################################
hurricane_step48_stride_linear_fdf <- getFDF("hurricane_step48",stride,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_step48_uniform_linear_fdf <- getFDF("hurricane_step48",uniform,linear)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_step48_stride_flexmix_fdf <- getFDF("hurricane_step48",stride,flexmix)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_step48_uniform_flexmix_fdf <- getFDF("hurricane_step48",uniform,flexmix)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_step48_stride_mixed_fdf <- getFDF("hurricane_step48",stride,mixed)
# step48_sm_predictions <- getPredictionsVsReal(hurricane_step48_stride_mixed_fdf, "hurricane_step48",stride,mixed)
# #---------------------------------------------------------------------------------------------------------------------------
# hurricane_step48_uniform_mixed_fdf <- getFDF("hurricane_step48",uniform,mixed)
# step48_um_predictions <- getPredictionsVsReal(hurricane_step48_uniform_mixed_fdf, "hurricane_step48",uniform,mixed)
#---------------------------------------------------------------------------------------------------------------------------
hurricane_step48_stride_linear_allEB_fdf <- getFDF("hurricane_step48",stride,linear,TRUE)
hurricane_step48_uniform_linear_allEB_fdf <- getFDF("hurricane_step48",uniform,linear,TRUE)
hurricane_step48_stride_flexmix_allEB_fdf <- getFDF("hurricane_step48",stride,flexmix,TRUE)
hurricane_step48_uniform_flexmix_allEB_fdf <- getFDF("hurricane_step48",uniform,flexmix,TRUE)

############################################################################################################################
# Hurricane TC
############################################################################################################################
hurricane_TC_stride_linear_fdf <- getFDF("hurricane_TC",stride,linear)
hurricane_TC_uniform_linear_fdf <- getFDF("hurricane_TC",uniform,linear)
hurricane_TC_stride_flexmix_fdf <- getFDF("hurricane_TC",stride,flexmix)
hurricane_TC_uniform_flexmix_fdf <- getFDF("hurricane_TC",uniform,flexmix)
# #---------------------------------------------------------------------------------------------------------------------------
# # hurricane_TC_stride_mixed_fdf <- getFDF("hurricane_TC",stride,mixed)
# # tc_sm_predictions <- getPredictionsVsReal(hurricane_TC_stride_mixed_fdf, "hurricane_TC",stride,mixed)
# hurricane_TC_uniform_mixed_fdf <- getFDF("hurricane_TC",uniform,mixed)
# tc_um_predictions <- getPredictionsVsReal(hurricane_TC_uniform_mixed_fdf, "hurricane_TC",uniform,mixed)

############################################################################################################################
# SCALE-LETKF
############################################################################################################################
scale_stride_linear_fdf <- getFDF("SCALE",stride,linear)
scale_uniform_linear_fdf <- getFDF("SCALE",uniform,linear)
scale_stride_flexmix_fdf <- getFDF("SCALE",stride,flexmix)
scale_uniform_flexmix_fdf <- getFDF("SCALE",uniform,flexmix)
# #---------------------------------------------------------------------------------------------------------------------------
# scale_stride_mixed_fdf <- getFDF("SCALE",stride,mixed)
# scale_sm_predictions <- getPredictionsVsReal(scale_stride_mixed_fdf,"SCALE",stride,mixed)
# scale_uniform_mixed_fdf <- getFDF("SCALE",uniform,mixed)
# scale_um_predictions <- getPredictionsVsReal(scale_uniform_mixed_fdf,"SCALE",uniform,mixed)

############################################################################################################################
# qmcpack
############################################################################################################################
qmcpack_stride_linear_fdf <- getFDF("qmcpack",stride,linear)
qmcpack_uniform_linear_fdf <- getFDF("qmcpack",uniform,linear)
qmcpack_stride_flexmix_fdf <- getFDF("qmcpack",stride,flexmix)
qmcpack_uniform_flexmix_fdf <- getFDF("qmcpack",uniform,flexmix)

############################################################################################################################
# NYX
############################################################################################################################
#NYX_stride_linear_fdf <- getFDF("NYX",stride,linear)
#NYX_uniform_linear_fdf <- getFDF("NYX",uniform,linear)
nyx_stride_flexmix_fdf <- getFDF("NYX",stride,flexmix,1)
nyx_uniform_flexmix_fdf <- getFDF("NYX",uniform,flexmix,1)

############################################################################################################################


combine = TRUE
if(combine) {
  combined_stride_linear <- rbind(hurricane_CLOUD_stride_linear_fdf,hurricane_Pf_stride_linear_fdf,
                                  hurricane_PRECIP_stride_linear_fdf,hurricane_QRAIN_stride_linear_fdf,
                                  hurricane_step48_stride_linear_fdf,hurricane_TC_stride_linear_fdf,
                                  miranda_stride_linear_fdf)#,qmcpack_stride_linear_fdf)
                                  
  combined_uniform_linear <- rbind(hurricane_CLOUD_uniform_linear_fdf,hurricane_Pf_uniform_linear_fdf,
                                  hurricane_PRECIP_uniform_linear_fdf,hurricane_QRAIN_uniform_linear_fdf,
                                  hurricane_step48_uniform_linear_fdf,hurricane_TC_uniform_linear_fdf,
                                  miranda_uniform_linear_fdf)
  
  combined_stride_flexmix <- rbind(hurricane_CLOUD_stride_flexmix_fdf,hurricane_Pf_stride_flexmix_fdf,
                                  hurricane_PRECIP_stride_flexmix_fdf,hurricane_QRAIN_stride_flexmix_fdf,
                                  hurricane_step48_stride_flexmix_fdf,hurricane_TC_stride_flexmix_fdf,
                                  miranda_stride_flexmix_fdf)
  
  combined_uniform_flexmix <- rbind(hurricane_CLOUD_uniform_flexmix_fdf,hurricane_Pf_uniform_flexmix_fdf,
                                   hurricane_PRECIP_uniform_flexmix_fdf,hurricane_QRAIN_uniform_flexmix_fdf,
                                   hurricane_step48_uniform_flexmix_fdf,hurricane_TC_uniform_flexmix_fdf,
                                   miranda_uniform_flexmix_fdf)
  
  total_combined <- rbind(hurricane_CLOUD_stride_linear_fdf,hurricane_Pf_stride_linear_fdf,
                          hurricane_PRECIP_stride_linear_fdf,hurricane_QRAIN_stride_linear_fdf,
                          hurricane_step48_stride_linear_fdf,hurricane_TC_stride_linear_fdf,
                          miranda_stride_linear_fdf,
                          hurricane_CLOUD_uniform_linear_fdf,hurricane_Pf_uniform_linear_fdf,
                          hurricane_PRECIP_uniform_linear_fdf,hurricane_QRAIN_uniform_linear_fdf,
                          hurricane_step48_uniform_linear_fdf,hurricane_TC_uniform_linear_fdf,
                          miranda_uniform_linear_fdf,
                          hurricane_CLOUD_stride_flexmix_fdf,hurricane_Pf_stride_flexmix_fdf,
                          hurricane_PRECIP_stride_flexmix_fdf,hurricane_QRAIN_stride_flexmix_fdf,
                          hurricane_step48_stride_flexmix_fdf,hurricane_TC_stride_flexmix_fdf,
                          miranda_stride_flexmix_fdf,
                          hurricane_CLOUD_uniform_flexmix_fdf,hurricane_Pf_uniform_flexmix_fdf,
                          hurricane_PRECIP_uniform_flexmix_fdf,hurricane_QRAIN_uniform_flexmix_fdf,
                          hurricane_step48_uniform_flexmix_fdf,hurricane_TC_uniform_flexmix_fdf,
                          miranda_uniform_flexmix_fdf
                          )
}


if(gen_scatterplots) {
  cloud_sl_predictions <- getPredictionsVsReal(hurricane_CLOUD_stride_linear_fdf,"hurricane_CLOUD",stride,linear)
  cloud_ul_predictions <- getPredictionsVsReal(hurricane_CLOUD_uniform_linear_fdf,"hurricane_CLOUD",uniform,linear)
  cloud_sf_predictions <- getPredictionsVsReal(hurricane_CLOUD_stride_flexmix_fdf,"hurricane_CLOUD",stride,flexmix)
  cloud_uf_predictions <- getPredictionsVsReal(hurricane_CLOUD_uniform_flexmix_fdf,"hurricane_CLOUD",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  miranda_sl_predictions <- getPredictionsVsReal(miranda_stride_linear_fdf,"Miranda",stride,linear)
  miranda_ul_predictions <- getPredictionsVsReal(miranda_uniform_linear_fdf,"Miranda",uniform,linear)
  miranda_sf_predictions <- getPredictionsVsReal(miranda_stride_flexmix_fdf,"Miranda",stride,flexmix)
  miranda_uf_predictions <- getPredictionsVsReal(miranda_uniform_flexmix_fdf,"Miranda",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  multi_sl_predictions <- getPredictionsVsReal(hurricane_multi_stride_linear_fdf,"hurricane_multi",stride,linear)
  multi_ul_predictions <- getPredictionsVsReal(hurricane_multi_uniform_linear_fdf,"hurricane_multi",uniform,linear)
  multi_sf_predictions <- getPredictionsVsReal(hurricane_multi_stride_flexmix_fdf,"hurricane_multi",stride,flexmix)
  multi_uf_predictions <- getPredictionsVsReal(hurricane_multi_uniform_flexmix_fdf,"hurricane_multi",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  pf_sl_predictions <- getPredictionsVsReal(hurricane_Pf_stride_linear_fdf,"hurricane_Pf",stride,linear)
  pf_ul_predictions <- getPredictionsVsReal(hurricane_Pf_uniform_linear_fdf,"hurricane_Pf",uniform,linear)
  pf_sf_predictions <- getPredictionsVsReal(hurricane_Pf_stride_flexmix_fdf,"hurricane_Pf",stride,flexmix)
  pf_uf_predictions <- getPredictionsVsReal(hurricane_Pf_uniform_flexmix_fdf,"hurricane_Pf",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  precip_sl_predictions <- getPredictionsVsReal(hurricane_PRECIP_stride_linear_fdf,"hurricane_PRECIP",stride,linear)
  precip_ul_predictions <- getPredictionsVsReal(hurricane_PRECIP_uniform_linear_fdf,"hurricane_PRECIP",uniform,linear)
  precip_sf_predictions <- getPredictionsVsReal(hurricane_PRECIP_stride_flexmix_fdf,"hurricane_PRECIP",stride,flexmix)
  precip_uf_predictions <- getPredictionsVsReal(hurricane_PRECIP_uniform_flexmix_fdf,"hurricane_PRECIP",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  qrain_sl_predictions <- getPredictionsVsReal(hurricane_QRAIN_stride_linear_fdf,"hurricane_QRAIN",stride,linear)
  qrain_ul_predictions <- getPredictionsVsReal(hurricane_QRAIN_uniform_linear_fdf,"hurricane_QRAIN",uniform,linear)
  qrain_sf_predictions <- getPredictionsVsReal(hurricane_QRAIN_stride_flexmix_fdf,"hurricane_QRAIN",stride,flexmix)
  qrain_uf_predictions <- getPredictionsVsReal(hurricane_QRAIN_uniform_flexmix_fdf,"hurricane_QRAIN",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  step48_sl_predictions <- getPredictionsVsReal(hurricane_step48_stride_linear_fdf, "hurricane_step48",stride,linear)
  step48_ul_predictions <- getPredictionsVsReal(hurricane_step48_uniform_linear_fdf, "hurricane_step48",uniform,linear)
  step48_sf_predictions <- getPredictionsVsReal(hurricane_step48_stride_flexmix_fdf, "hurricane_step48",stride,flexmix)
  step48_uf_predictions <- getPredictionsVsReal(hurricane_step48_uniform_flexmix_fdf, "hurricane_step48",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  tc_sl_predictions <- getPredictionsVsReal(hurricane_TC_stride_linear_fdf, "hurricane_TC",stride,linear)
  tc_ul_predictions <- getPredictionsVsReal(hurricane_TC_uniform_linear_fdf, "hurricane_TC",uniform,linear)
  tc_sf_predictions <- getPredictionsVsReal(hurricane_TC_stride_flexmix_fdf, "hurricane_TC",stride,flexmix)
  tc_uf_predictions <- getPredictionsVsReal(hurricane_TC_uniform_flexmix_fdf, "hurricane_TC",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  scale_sl_predictions <- getPredictionsVsReal(scale_stride_linear_fdf,"SCALE",stride,linear)
  scale_ul_predictions <- getPredictionsVsReal(scale_uniform_linear_fdf,"SCALE",uniform,linear)
  scale_sf_predictions <- getPredictionsVsReal(scale_stride_flexmix_fdf,"SCALE",stride,flexmix)
  scale_uf_predictions <- getPredictionsVsReal(scale_uniform_flexmix_fdf,"SCALE",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
  qmcpack_sl_predictions <- getPredictionsVsReal(qmcpack_stride_linear_fdf,"qmcpack",stride,linear)
  qmcpack_ul_predictions <- getPredictionsVsReal(qmcpack_uniform_linear_fdf,"qmcpack",uniform,linear)
  qmcpack_sf_predictions <- getPredictionsVsReal(qmcpack_stride_flexmix_fdf,"qmcpack",stride,flexmix)
  qmcpack_uf_predictions <- getPredictionsVsReal(qmcpack_uniform_flexmix_fdf,"qmcpack",uniform,flexmix)
  #---------------------------------------------------------------------------------------------------------------------------
}

if(gen_new_figs) {
  # CLOUD
  makeHeatmapByEB_allEB(hurricane_CLOUD_stride_linear_fdf,1,25)
  makeHeatmapByEB_allEB(hurricane_CLOUD_uniform_linear_fdf,1,25)
  makeHeatmapByEB_allEB(hurricane_CLOUD_stride_flexmix_fdf,1,25)
  makeHeatmapByEB_allEB(hurricane_CLOUD_uniform_flexmix_fdf,1,25)
  
  runGetHeatmapByEBAndComp_allModels(hurricane_CLOUD_stride_linear_fdf, hurricane_CLOUD_uniform_linear_fdf,
                                     hurricane_CLOUD_stride_flexmix_fdf, hurricane_CLOUD_uniform_flexmix_fdf,
                                     cloud_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # P
  makeHeatmapByEB_allEB(hurricane_Pf_stride_linear_fdf,1,2.1)
  makeHeatmapByEB_allEB(hurricane_Pf_uniform_linear_fdf,1,2.1)
  makeHeatmapByEB_allEB(hurricane_Pf_stride_flexmix_fdf,1,2.1)
  makeHeatmapByEB_allEB(hurricane_Pf_uniform_flexmix_fdf,1,2.1)
  
  runGetHeatmapByEBAndComp_allModels(hurricane_Pf_stride_linear_fdf, hurricane_Pf_uniform_linear_fdf,
                                     hurricane_Pf_stride_flexmix_fdf, hurricane_Pf_uniform_flexmix_fdf,
                                     p_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # PRECIP
  makeHeatmapByEB_allEB(hurricane_PRECIP_stride_linear_fdf,1,15.1)
  makeHeatmapByEB_allEB(hurricane_PRECIP_uniform_linear_fdf,1,15.1)
  makeHeatmapByEB_allEB(hurricane_PRECIP_stride_flexmix_fdf,1,15.1)
  makeHeatmapByEB_allEB(hurricane_PRECIP_uniform_flexmix_fdf,1,15.1)
  
  runGetHeatmapByEBAndComp_allModels(hurricane_PRECIP_stride_linear_fdf, hurricane_PRECIP_uniform_linear_fdf,
                                     hurricane_PRECIP_stride_flexmix_fdf, hurricane_PRECIP_uniform_flexmix_fdf,
                                     precip_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # multi
  makeHeatmapByEB_allEB(hurricane_multi_stride_linear_fdf,1,30)
  makeHeatmapByEB_allEB(hurricane_multi_uniform_linear_fdf,1,30)
  makeHeatmapByEB_allEB(hurricane_multi_stride_flexmix_fdf,1,25)
  makeHeatmapByEB_allEB(hurricane_multi_uniform_flexmix_fdf,1,25)
  
  runGetHeatmapByEBAndComp_allModels(hurricane_multi_stride_linear_fdf, hurricane_multi_uniform_linear_fdf,
                                     hurricane_multi_stride_flexmix_fdf, hurricane_multi_uniform_flexmix_fdf,
                                     multi_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # QRAIN
  makeHeatmapByEB_allEB(hurricane_QRAIN_stride_linear_fdf,1,25.1)
  makeHeatmapByEB_allEB(hurricane_QRAIN_uniform_linear_fdf,1,25.1)
  makeHeatmapByEB_allEB(hurricane_QRAIN_stride_flexmix_fdf,1,15.1)
  makeHeatmapByEB_allEB(hurricane_QRAIN_uniform_flexmix_fdf,1,15.1)
  
  runGetHeatmapByEBAndComp_allModels(hurricane_QRAIN_stride_linear_fdf, hurricane_QRAIN_uniform_linear_fdf,
                                     hurricane_QRAIN_stride_flexmix_fdf, hurricane_QRAIN_uniform_flexmix_fdf,
                                     qrain_limits)
  
  #---------------------------------------------------------------------------------------------------------------------------
  # step48
  makeHeatmapByEB_allEB(hurricane_step48_stride_linear_fdf,1,100)
  makeHeatmapByEB_allEB(hurricane_step48_uniform_linear_fdf,1,100)
  makeHeatmapByEB_allEB(hurricane_step48_stride_flexmix_fdf,1,100)
  makeHeatmapByEB_allEB(hurricane_step48_uniform_flexmix_fdf,1,100)
  
  runGetHeatmapByEBAndComp_allModels(hurricane_step48_stride_linear_fdf, hurricane_step48_uniform_linear_fdf,
                                     hurricane_step48_stride_flexmix_fdf, hurricane_step48_uniform_flexmix_fdf,
                                     step48_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # TC
  makeHeatmapByEB_allEB(hurricane_TC_stride_linear_fdf,1,5.1)
  makeHeatmapByEB_allEB(hurricane_TC_uniform_linear_fdf,1,5.1)
  makeHeatmapByEB_allEB(hurricane_TC_stride_flexmix_fdf,1,2.1)
  makeHeatmapByEB_allEB(hurricane_TC_uniform_flexmix_fdf,1,2.1)
  
  runGetHeatmapByEBAndComp_allModels(hurricane_TC_stride_linear_fdf, hurricane_TC_uniform_linear_fdf,
                                     hurricane_TC_stride_flexmix_fdf, hurricane_TC_uniform_flexmix_fdf,
                                     tc_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # Miranda
  makeHeatmapByEB_allEB(miranda_stride_linear_fdf,1,100)
  makeHeatmapByEB_allEB(miranda_uniform_linear_fdf,1,100)
  makeHeatmapByEB_allEB(miranda_stride_flexmix_fdf,1,100)
  makeHeatmapByEB_allEB(miranda_uniform_flexmix_fdf,1,100)
  
  runGetHeatmapByEBAndComp_allModels(miranda_stride_linear_fdf, miranda_uniform_linear_fdf,
                                     miranda_stride_flexmix_fdf, miranda_uniform_flexmix_fdf,
                                     miranda_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # SCALE
  makeHeatmapByEB_allEB(scale_stride_linear_fdf,1,100)
  makeHeatmapByEB_allEB(scale_uniform_linear_fdf,1,100)
  makeHeatmapByEB_allEB(scale_stride_flexmix_fdf,1,100)
  makeHeatmapByEB_allEB(scale_uniform_flexmix_fdf,1,100)
  
  runGetHeatmapByEBAndComp_allModels(scale_stride_linear_fdf, scale_uniform_linear_fdf,
                                     scale_stride_flexmix_fdf, scale_uniform_flexmix_fdf,
                                     scale_limits)
  #---------------------------------------------------------------------------------------------------------------------------
  # qmcpack
  makeHeatmapByEB_allEB(qmcpack_stride_linear_fdf,1,30)
  makeHeatmapByEB_allEB(qmcpack_uniform_linear_fdf,1,25)
  makeHeatmapByEB_allEB(qmcpack_stride_flexmix_fdf,1,10)
  makeHeatmapByEB_allEB(qmcpack_uniform_flexmix_fdf,1,10)
  
  runGetHeatmapByEBAndComp_allModels(qmcpack_stride_linear_fdf, qmcpack_uniform_linear_fdf,
                                     qmcpack_stride_flexmix_fdf, qmcpack_uniform_flexmix_fdf,
                                     qmcpack_limits)
  #---------------------------------------------------------------------------------------------------------------------------
}



