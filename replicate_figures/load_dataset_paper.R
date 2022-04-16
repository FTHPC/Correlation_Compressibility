
if (dataset == 'gaussian_singlescale'){
  gaussian <- 0
  var_nm <- "single scale"
  title_nm <- "gaussian single scale"
  data <- read.csv('./generated_data/dataframe_output_gaussian_singlescale_mar14.csv')
  data <- as.data.frame(data)
}


if (dataset == 'gaussian_type1'){
  gaussian <- 0
  var_nm <- "multiscale scalar weight"
  title_nm <- "gaussian multiscale scalar weight"
  data <- read.csv('./generated_data/dataframe_output_scalarweight_fixed_sum.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.weight==3)
  }


if (dataset == 'gaussian_type2'){
  gaussian <- 0
  var_nm <- "multiscale spatial weights fixed correlation"
  title_nm <- "multiscale spatial weights fixed correlation"
  data <- read.csv('./generated_data/dataframe_output_spatialweight_fixed_sum.csv')
  data <- as.data.frame(data)
}


if (dataset == 'gaussian_type3'){
  gaussian <- 0
  var_nm <- "multiscale spatial weights random correlation"
  title_nm <- "multiscale spatial weights random correlation"
  data <- read.csv('./generated_data/dataframe_output_spatialweight_random_sum.csv')
  data <- as.data.frame(data)
}


if (dataset == 'gaussian_type4'){
  gaussian <- 1
  var_nm <- "multiscale scalar weight"
  title_nm <- "gaussian multiscale scalar weight"
  data <- read.csv('./generated_data/dataframe_output_scalarweight_fixed_sum.csv')
  data <- as.data.frame(data)
}


if (dataset == 'miranda_vx'){
  gaussian <- 0
  var_nm <- "velocityx"
  title_nm <- "Miranda velocity-x 384*384"
  data <- read.csv('./generated_data/dataframe_output_miranda_feb27.csv')
  data <- as.data.frame(data)
  data <- filter(data, dim2 == 384)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'miranda_de'){
  gaussian <- 0
  var_nm <- "density"
  title_nm <- "Miranda density 384*384"
  data <- read.csv('./generated_data/dataframe_output_miranda_feb27.csv')
  data <- as.data.frame(data)
  data <- filter(data, dim2 == 384)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'miranda_pr'){
  gaussian <- 0
  var_nm <- "pressure"
  title_nm <- "Miranda pressure 384*384"
  data <- read.csv('./generated_data/dataframe_output_miranda_feb27.csv')
  data <- as.data.frame(data)
  data <- filter(data, dim2 == 384)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'cesm_cl'){
  gaussian <- 0
  var_nm <- "CLOUD"
  title_nm <- "CESM cloud 1800*3600"
  data <- read.csv('./generated_data/dataframe_output_cesm_mar14.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'scale_qr'){
  gaussian <- 0
  var_nm <- "QR"
  title_nm <- "SCALE QR 1200*1200"
  data <- read.csv('./generated_data/dataframe_output_scale_mar14.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'scale_u'){
  gaussian <- 0
  var_nm <- "U"
  title_nm <- "SCALE U 1200*1200"
  data <- read.csv('./generated_data/dataframe_output_scale_mar14.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'scale_pres'){
  gaussian <- 0
  var_nm <- "PRES"
  title_nm <- "SCALE pressure 1200*1200"
  data <- read.csv('./generated_data/dataframe_output_scale_mar14.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'nyx_da'){
  gaussian <- 0
  var_nm <- "dark_matter_density"
  title_nm <- "NYX dark matter density 512*512"
  data <- read.csv('./generated_data/dataframe_output_exasky_nyx_mar28.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'nyx_vx'){
  gaussian <- 0
  var_nm <- "velocity_x"
  title_nm <- "NYX velocity-x 512*512"
  data <- read.csv('./generated_data/dataframe_output_exasky_nyx_mar28.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
}


if (dataset == 'hurricane_qg'){
  gaussian <- 0
  var_nm <- "QGRAUPf48"
  title_nm <- "Hurricane QGRAUP 500*500"
  data <- read.csv('./generated_data/dataframe_output_hurricane_mar20.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
  data <- filter(data, dim2 == 500 & dim1==500)
}




if (dataset == 'hurricane_u'){
  gaussian <- 0
  var_nm <- "Uf48"
  title_nm <- "Hurricane U 500*500"
  data <- read.csv('./generated_data/dataframe_output_hurricane_mar20.csv')
  data <- as.data.frame(data)
  data <- filter(data, info.filename == var_nm)
  data <- filter(data, dim2 == 500 & dim1==500)
}
