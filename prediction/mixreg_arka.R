setwd("...")
data_cloud= read.csv("CLOUDf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_precip= read.csv("PRECIPf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_qcloud= read.csv("QCLOUDf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_qgraup= read.csv("QGRAUPf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_qice= read.csv("QICEf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_qrain= read.csv("QRAINf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_qsnow= read.csv("QSNOWf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_qvapor= read.csv("QVAPORf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_p= read.csv("pf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_tc= read.csv("tcf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_u= read.csv("uf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_v= read.csv("vf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]
data_w= read.csv("wf48.log10_summary_statistics.csv", header=FALSE)[,-c(1)]

data= list(data_cloud, data_precip, data_qcloud, data_qgraup, data_qice,data_qrain,data_qsnow,
           data_p, data_tc, data_u, data_v, data_w)
library(modelr)
APE_all=list(NULL)
for(i in 1:length(data))
{
  cv_error=rep(0,8)
  colnames(data[[i]])=c("CR_SZ_1e.3" , "CR_SZ_1e.4" , 
                        "CR_SZ_1e.6", "CR_ZFP_1e.3", "CR_ZFP_1e.4"  , "CR_ZFP_1e.6", "CR_sperr_1e.3",  "CR_sperr_1e.4", 
                        "CR_sperr_1e.6","mean" ,"sd",  "min",  "max" , "spatial_var" , 
                        "spatial_cor_weighted" , "spatial_cor_mean",  "spatial_cor_minimax",  
                        "spatial_cor_min", "log_10.homoscadastic_coding_gain_intra.", "log_10.heteroscadastic_coding_gain_intra." ,
                        "svd_trunc_intra" , "Distortion_1e.3"  ,"Distortion_1e.4"  ,  
                        "Distortion_1e.6" )
  colnames(data[[i]])[20]="CodingGain"
  data[[i]]= data[[i]][data[[i]]$CR_SZ_1e.3<150,]
  data[[i]][,c(1:9,14)]=log(data[[i]][,c(1:9,14)])
  cv  <- crossv_kfold(data[[i]], k = 8)
  output_all_final= NULL
  for(j in 1:8)
  {
    train_index= cv$train[[j]]$idx
    test_index= cv$test[[j]]$idx
    data_train= data[[i]][train_index,]
    data_test=data[[i]][test_index,]
    n=nrow(data_train)
    print(n)
    #scaling the data
    library(caret)
    normalizing_param= preProcess(data_train[,-c(1:9)])
    data_train[,-c(1:9)]= predict(normalizing_param, data_train[,-c(1:9)])
    data_test[,-c(1:9)]= predict(normalizing_param, data_test[,-c(1:9)])
    library(flexmix)
    
    k1=ifelse(sd(data_train$CR_SZ_1e.3)<0.2,1,4)
    m1 <- flexmix(CR_SZ_1e.3~   spatial_var + spatial_cor_mean + 
                    CodingGain + svd_trunc_intra + Distortion_1e.3, data = data_train, k = k1)
    posteriors= posterior(m1, data_test)
    pred_test_1= sapply(1:nrow(test.set), function(x){return(sum(unlist(predict(fit, test.set[x,]))*posteriors[x,]))})
    MedAPE_test=median(100*abs(exp(pred_test_1)-exp(data_test$CR_SZ_1e.3))/exp(data_test$CR_SZ_1e.3))
    cv_error[j]=MedAPE_test
    imp_features_col= c(14,16, 20, 21,22)
    library(conformalInference)
    print("CP is starting")
    conformal_split=function(iter)
    {
      clust_wise_pred= function(cl)
      {
        train_fun= function(x,y){return(unlist(predict(m1, data.frame(x))[cl]))}
        test_fun=  function(out, newx)
        {
          colnames(newx)= c("spatial_var" , "spatial_cor_mean" , "CodingGain" , "svd_trunc_intra" , "Distortion_1e.3")
          return(unlist(predict(m1, data.frame(newx))[cl]))
        }
        out.split = conformal.pred.split(data_train[,imp_features_col], data_train$CR_SZ_1e.3, 
                                         as.matrix(data_test[,imp_features_col]), alpha=0.1, seed=iter,train.fun=train_fun, 
                                         predict.fun=test_fun)
        output=list(out.split$pred, out.split$lo, out.split$up)
        return(output)
      }
      all_output= lapply(1:dim(posteriors)[2], clust_wise_pred)
      pred= apply(sapply(1:dim(posteriors)[2], function(x){return(all_output[[x]][[1]]*posteriors[,x])}), 1, sum)
      lo= apply(sapply(1:dim(posteriors)[2], function(x){return(all_output[[x]][[2]]*posteriors[,x])}), 1, sum)
      up= apply(sapply(1:dim(posteriors)[2], function(x){return(all_output[[x]][[3]]*posteriors[,x])}), 1, sum)
      APE=100*abs(exp(pred_test_1)-exp(data_test$CR_SZ_1e.3))/exp(data_test$CR_SZ_1e.3)
      return(list(pred,lo,up,APE))
    }
    pred_all=matrix(0,100,nrow(data_test))
    lo_all=matrix(0,100,nrow(data_test))
    up_all=matrix(0,100,nrow(data_test))
    ape_all= matrix(0,100,nrow(data_test))
    for(iter in 1:100)
    {
      a=conformal_split(iter)
      pred_all[iter,]=a[[1]]
      lo_all[iter,]=a[[2]]
      up_all[iter,]=a[[3]]
      ape_all[iter,]=a[[4]]
    }
    pred= apply(pred_all,2,mean)
    lo=apply(lo_all,2,mean)
    up=apply(up_all,2,mean)
    ape= apply(ape_all,2,mean)
    output_all_final= rbind(output_all_final, (cbind(data_test$CR_SZ_1e.3, pred, lo, up, ape)))
  }
  print(c(cv_error, mean(cv_error)))
}
​
​
#ci=apply(cv_error, 1, function(x){return(c(mean(x), mean(x)-1.96*sd(x), mean(x)+1.96*sd(x)))})
setwd("...")
write.table(output_all_final, file = 'hurricane_mixture_regression_insample_conformal_qsnow.csv', sep = ",", append = TRUE, quote = FALSE, col.names = FALSE, row.names = TRUE)
​
​
############################################################################################################################################################################
############################################################################################################################################################################
​
​
data_all= data.frame(output_all_final)
colnames(data_all)=c("Original", "Predicted", "Lower Bound", "Upper Bound", "APE")
x=data_all[,1]
y=data_all[,2]
lo=data_all[,3]
up=data_all[,4]
missed= x > lo & x < up
APE= data_all[,5]
library(ggplot2)
library(cowplot)
#install.packages("patchwork")                 # Install & load patchwork package
library("patchwork")
setwd("/home/aganguli/compression/real-datasets/Mixture-reg_results")
ggp1 <- ggplot(data_all, aes(x, y)) +  geom_point() +labs(y= "Predicted", x = "Original") + ggtitle("Prediction interval")+
  theme(plot.title = element_text(hjust = 0.5))+ geom_ribbon(aes(ymin = lo, ymax = up), alpha = 0.2) + geom_abline(slope=1, intercept=0)

ggp2 <- ggplot(data_all, aes(x, APE)) +  geom_point() +labs(y= "APE", x = "Original") + ggtitle("APE")+
  theme(plot.title = element_text(hjust = 0.5))
ggp3 <- ggplot(data_all, aes( y=APE)) + ggtitle("APE - Boxplot")+
  geom_boxplot()+ theme(axis.title.x=element_blank(),
                        axis.text.x=element_blank(),
                        axis.ticks.x=element_blank())
​
ggp_all <- (ggp1 + ggp2+ggp3)  +    # Create grid of plots with title
  plot_annotation(title = paste0("Hurricane - W, empirical coverage=", round(mean(missed)*100,2), "%")) & 
  theme(plot.title = element_text(hjust = 0.5))
​
ggsave("Hurricane_mixture_regression_insample_conformal_W.png",ggp_all)