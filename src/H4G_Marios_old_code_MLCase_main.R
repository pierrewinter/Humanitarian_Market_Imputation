# BCG Machine Learning case
# Author: Mario Tomasello


require("caret")
require("e1071")
require("lubridate")
require("RANN")
require("logicFS")

setwd("~/BCG_case/ML_Case_MarioTomasello")
source(paste(getwd(), "/MLCase_functions.R", sep=""))

# Input files
input_history <- paste(getwd(),"/ml_case_data/ml_case_training_hist_data.csv", sep="")
input_training <- paste(getwd(),"/ml_case_data/ml_case_training_data.csv", sep="")
input_response <- paste(getwd(),"/ml_case_data/ml_case_training_output.csv", sep="")

data_step_01 <- read_and_aggregate_data(input_history, input_training)


# Define and train models in entire parameter space
for (remove_NA_num_fields in c("yes", "no")) {
  for (feature_selection_corr in c("yes", "no")) {
    for (NA_treatment in c("knnImpute", "remove")) {
      for (pca in c("yes", "no", "yeojohn")) {
        for (my_method in c("rfe_rf", "glm", "rf", "AdaBag", "LDA", "svmRadial", "knn", "nnet", "penalized")) { #for (my_method in c("rfe_rf", "rfe_svm_lin", "rfe_svm_rad", "glm", "rf", "AdaBag", "LDA", "svmRadial", "knn", "nnet", "penalized")) {
          
          tryCatch({
            preprocessed_data <- data_preprocessing(data_step_01, remove_NA_num_fields=remove_NA_num_fields, NA_threshold=0.4, feature_selection_corr=feature_selection_corr, NA_treatment=NA_treatment, pca=pca)
            training_data <- aggregate_output(preprocessed_data, input_response)
            model <- train_model(training_data, method = my_method)
            save(model, file=paste(getwd(), "/output/model_NAfields", remove_NA_num_fields, "_corr", feature_selection_corr, "_NA", NA_treatment, "_pca", pca, "_method", my_method,  ".Rdata", sep=""))
            print(paste("remove_NA_num_fields", remove_NA_num_fields, "_corr", feature_selection_corr, "_NA", NA_treatment, "_pca", pca, "_method", my_method,  ".Rdata", sep=""))
            
            #generating a second version for each model with features derived from RFE_RF
            if ((my_method != "rfe_rf") & (feature_selection_corr=="no")) {
              load(file=paste(getwd(), "/output/model_NAfields", remove_NA_num_fields, "_corr", "no", "_NA", NA_treatment, "_pca", pca, "_method", "rfe_rf",  ".Rdata", sep=""))
              model <- train_model(training_data[,colnames(training_data) %in% c(model$optVariables, "churn")], method = my_method)
              save(model, file=paste(getwd(), "/output/model_NAfields", remove_NA_num_fields, "_corr", "RFE", "_NA", NA_treatment, "_pca", pca, "_method", my_method,  ".Rdata", sep=""))
              print(paste("remove_NA_num_fields", remove_NA_num_fields, "_corr", "RFE", "_NA", NA_treatment, "_pca", pca, "_method", my_method,  ".Rdata", sep=""))
            }
            
          }, error = function(e) {
            print(paste("ERROR: remove_NA_num_fields", remove_NA_num_fields, "_corr", feature_selection_corr, "_NA", NA_treatment, "_pca", pca, "_method", my_method,  ".Rdata", sep=""))
          } )
        }
      }
    }
  }
}



# Reading results and ranking models
model_performances <- data.frame(matrix(NA, nrow=0, ncol=9, dimnames=list(a=NULL, b=c("remove_NA_num_fields", "feature_selection_corr", "NA_treatment", "pca", "method", "AUC_ROC", "Brier_Score", "Prediction_NO", "Prediction_YES")) ))
for (remove_NA_num_fields in c("yes", "no")) {
  for (feature_selection_corr in c("yes", "no", "RFE")) {
    for (NA_treatment in c("knnImpute", "remove")) {
      for (pca in c("yes", "no", "yeojohn")) {
        
        preprocessed_data <- data_preprocessing(data_step_01, remove_NA_num_fields=remove_NA_num_fields, NA_threshold=0.4, feature_selection_corr=feature_selection_corr, NA_treatment=NA_treatment, pca=pca)
        save(preprocessed_data, file=paste(getwd(), "/output/preprocessed_data_NAfields", remove_NA_num_fields, "_corr", feature_selection_corr, "_NA", NA_treatment, "_pca", pca,  ".Rdata", sep=""))
        training_data <- aggregate_output(preprocessed_data, input_response)
        
        for (my_method in c("rfe_rf", "glm", "rf", "AdaBag", "LDA", "svmRadial", "knn", "nnet", "penalized")) { #for (my_method in c("rfe_rf", "rfe_svm_lin", "rfe_svm_rad", "glm", "rf", "AdaBag", "LDA", "svmRadial", "knn", "nnet", "penalized")) {
          
          tryCatch({
            
            load(file=paste(getwd(), "/output/model_NAfields", remove_NA_num_fields, "_corr", feature_selection_corr, "_NA", NA_treatment, "_pca", pca, "_method", my_method,  ".Rdata", sep=""))
            ROC_value <- max(model$results$ROC)
            obs <- ifelse(training_data$churn=="Yes", 1, 0)
            pred <- ifelse(predict(model)=="Yes", 1, 0)
            brier_score <- BrierScore(obs, pred)
            pred_yes <- length(pred[pred==1])
            pred_no <- length(pred[pred==0])
            model_performances[nrow(model_performances)+1,] <- list(remove_NA_num_fields,feature_selection_corr,NA_treatment,pca,my_method,ROC_value, brier_score, pred_no, pred_yes)
          }, error = function(e) {
            print(paste("ERROR: remove_NA_num_fields", remove_NA_num_fields, "_corr", feature_selection_corr, "_NA", NA_treatment, "_pca", pca, "_method", my_method,  ".Rdata", sep=""))
          } )
          
        }
      }
    }
  }
}

model_top_performances <- model_performances[order(-model_performances$AUC_ROC),]
model_top_performances[1,]




# Loading model with best perfromance in terms of ROC
load(file=paste(getwd(), "/output/model_NAfields", model_top_performances[1,"remove_NA_num_fields"],
                "_corr", model_top_performances[1,"feature_selection_corr"],
                "_NA", model_top_performances[1,"NA_treatment"],
                "_pca", model_top_performances[1,"pca"],
                "_method", model_top_performances[1,"method"], 
                ".Rdata", sep=""))

model
model$results$ROC
model$resample
model$optVariables
model_final <- model

# Use the specific model with optimal score
preprocessed_data <- data_preprocessing(data_step_01, remove_NA_num_fields=model_top_performances[1,"remove_NA_num_fields"],
                                        NA_threshold=0.4,
                                        feature_selection_corr=model_top_performances[1,"feature_selection_corr"],
                                        NA_treatment=model_top_performances[1,"NA_treatment"],
                                        pca=model_top_performances[1,"pca"])
training_data <- aggregate_output(preprocessed_data, input_response)



# Plotting ROC curve and Brier score for final model
obs <- ifelse(training_data$churn=="Yes", 1, 0)
pred <- ifelse(predict(model_final)=="Yes", 1, 0)

mydata <- data.frame(pred=pred, obs=obs)

ggplot(mydata, aes(m=pred, d=obs)) + geom_roc(hjust = -0.4, vjust = 1.5) + coord_equal() +
  labs(title= "ROC curve", 
       x = "False Positive Rate (1-Specificity)", 
       y = "True Positive Rate (Sensitivity)")


# Brier Score
print(BrierScore(obs, pred))


# Printing Confusion Matrix
conf_matrix <- confusionMatrix(predict(model_final), training_data$churn)



# Reading and pre-processing TEST data
input_test_history <- paste(getwd(),"/ml_case_data/ml_case_test_hist_data.csv", sep="")
input_test_training <- paste(getwd(),"/ml_case_data/ml_case_test_data.csv", sep="")

test_data_input <- read_and_aggregate_data(input_test_history, input_test_training)
test_data <- data_preprocessing(test_data_input, remove_NA_num_fields=model_top_performances[1,"remove_NA_num_fields"],
                                NA_threshold=0.4,
                                feature_selection_corr=model_top_performances[1,"feature_selection_corr"],
                                NA_treatment=model_top_performances[1,"NA_treatment"],
                                pca=model_top_performances[1,"pca"])
# Origin_up has 1 level not in training data
new_level <- unique(test_data$origin_up[!test_data$origin_up %in% preprocessed_data$origin_up])
test_data$origin_up[test_data$origin_up==new_level] <- "Other"

# Making predictions on test data
all_predictions_probs <- cbind(id=test_data$id, predict(model_final, newdata=test_data[,!colnames(test_data) %in% c("id")], type="prob"))
all_predictions_binary <- data.frame(cbind(id=as.character(test_data$id), churn=as.character(predict(model_final, newdata=test_data[,!colnames(test_data) %in% c("id")]))))
all_predictions <- merge(all_predictions_probs, all_predictions_binary, by="id")

sum(pred[pred==1])/length(pred)
sum(obs[obs==1])/length(obs)
table(all_predictions$churn)

# Adjusting threshold probability to match distribution of model_final on training dataset
adj_churn_prob <- quantile(all_predictions$Yes, probs=c(1-sum(pred[pred==1])/length(pred)))

length(all_predictions$Yes[all_predictions$Yes>adj_churn_prob]) / nrow(all_predictions)

all_predictions_adjusted <- all_predictions
all_predictions_adjusted$churn_adj <- ifelse(all_predictions_adjusted$Yes>adj_churn_prob, "Yes", "No")

# Export predictions to file
data_template <- read.csv(file=paste(getwd(), "/ml_case_data/ml_case_test_output_template.csv", sep=""))
to_export <- merge(data_template, all_predictions_adjusted, by= "id") [,c("X", "id", "churn_adj", "Yes") ]
names(to_export) <- c("", "id", "Churn_prediction", "Churn_probability")
to_export <- to_export[order(to_export[,1]),]
to_export$Churn_prediction <- as.character(to_export$Churn_prediction)
to_export$Churn_prediction <- ifelse(to_export$Churn_prediction=="Yes", 1, 0)
write.csv(to_export, file=paste(getwd(), "/output_predictions.csv", sep=""), row.names = FALSE)


# Plot churn probability histogram
par(bg = 'white')
myhist <- hist(all_predictions$Yes, n=40, plot=F)
plot(myhist$mids, myhist$counts, type="h", lwd=2, col=ifelse(myhist$mids<0.27, "green", "red"), xlim=c(0,1), xlab="Churn probability prediction", ylab="Counts")
abline(v=0.5, lty=2)
abline(v=0.27, col="red", lty=2, lwd=1.8)




# Estimating revenues and margin on the training dataset
data <- aggregate_output(data_step_01, input_response)
estim_pow_revenues <- 1.0* data$pow_max  * (data$price_p1_fix_mean + data$price_p2_fix_mean + data$price_p3_fix_mean) / ifelse(data$price_p2_fix_mean==0 & data$price_p3_fix_mean==0,1, ifelse(data$price_p2_fix_mean==0,2,3))
estim_ele_revenues <- 1.0* data$cons_12m * (data$price_p1_var_mean + data$price_p2_var_mean + data$price_p3_var_mean) / ifelse(data$price_p2_var_mean==0 & data$price_p3_var_mean==0,1, ifelse(data$price_p2_var_mean==0,2,3))
print(paste("Tot estimated revenues", sum(estim_pow_revenues + estim_ele_revenues, na.rm=T)))
print(paste("Net margin form electricity", sum(data$margin_net_pow_ele, na.rm=T)))
print(paste("Total net margin", sum(data$net_margin, na.rm=T)))

print(paste("Tot estimated revenues", sum((estim_pow_revenues + estim_ele_revenues)[data$churn=="No"], na.rm=T)))
print(paste("Net margin form electricity", sum(data$margin_net_pow_ele[data$churn=="No"], na.rm=T)))
print(paste("Total net margin", sum(data$net_margin[data$churn=="No"], na.rm=T)))


# Testing the 20% discount scenario also on training data..
data$discount_factor <- ifelse(data$churn=="No", 1.0, 0.8)
estim_pow_forecast_disc <- data$pow_max  * data$discount_factor * (data$price_p1_fix_mean + data$price_p2_fix_mean + data$price_p3_fix_mean) / ifelse(data$price_p2_fix_mean==0 & data$price_p3_fix_mean==0,1, ifelse(data$price_p2_fix_mean==0,2,3))
estim_ele_forecast_disc <- data$cons_12m * data$discount_factor * (data$price_p1_var_mean + data$price_p2_var_mean + data$price_p3_var_mean) / ifelse(data$price_p2_var_mean==0 & data$price_p3_var_mean==0,1, ifelse(data$price_p2_var_mean==0,2,3))

print(paste("Tot estimated revenues", sum((estim_pow_forecast_disc + estim_ele_forecast_disc), na.rm=T)))
print(paste("Net margin from electricity", sum(data$margin_net_pow_ele - estim_pow_revenues - estim_ele_revenues + estim_pow_forecast_disc + estim_ele_forecast_disc, na.rm=T)))
print(paste("Total net margin", sum(data$net_margin - estim_pow_revenues - estim_ele_revenues + estim_pow_forecast_disc + estim_ele_forecast_disc, na.rm=T)))



# Estimating revenues and margin on the test dataset
data <- merge(test_data_input, all_predictions_adjusted, by="id")
estim_pow_revenues <- 1.0* data$pow_max  * (data$price_p1_fix_mean + data$price_p2_fix_mean + data$price_p3_fix_mean) / ifelse(data$price_p2_fix_mean==0 & data$price_p3_fix_mean==0,1, ifelse(data$price_p2_fix_mean==0,2,3))
estim_ele_revenues <- 1.0* data$cons_12m * (data$price_p1_var_mean + data$price_p2_var_mean + data$price_p3_var_mean) / ifelse(data$price_p2_var_mean==0 & data$price_p3_var_mean==0,1, ifelse(data$price_p2_var_mean==0,2,3))
print(paste("Tot estimated revenues", sum(estim_pow_revenues + estim_ele_revenues, na.rm=T)))
print(paste("Net margin from electricity", sum(data$margin_net_pow_ele, na.rm=T)))
print(paste("Total net margin", sum(data$net_margin, na.rm=T)))

print(paste("Tot estimated revenues", sum((estim_pow_forecast + estim_ele_forecast)[data$churn_adj=="No"], na.rm=T)))
print(paste("Net margin from electricity", sum(data$margin_net_pow_ele[data$churn_adj=="No"], na.rm=T)))
print(paste("Total net margin", sum(data$net_margin[data$churn_adj=="No"], na.rm=T)))


# On test dataset - With 20 % discount
data$discount_factor <- ifelse(data$churn_adj=="No", 1.0, 0.8)
estim_pow_forecast_disc <- data$pow_max  * data$discount_factor * (data$price_p1_fix_mean + data$price_p2_fix_mean + data$price_p3_fix_mean) / ifelse(data$price_p2_fix_mean==0 & data$price_p3_fix_mean==0,1, ifelse(data$price_p2_fix_mean==0,2,3))
estim_ele_forecast_disc <- data$cons_12m * data$discount_factor * (data$price_p1_var_mean + data$price_p2_var_mean + data$price_p3_var_mean) / ifelse(data$price_p2_var_mean==0 & data$price_p3_var_mean==0,1, ifelse(data$price_p2_var_mean==0,2,3))

print(paste("Tot estimated revenues", sum((estim_pow_forecast_disc + estim_ele_forecast_disc), na.rm=T)))
print(paste("Net margin from electricity", sum(data$margin_net_pow_ele - estim_pow_revenues - estim_ele_revenues + estim_pow_forecast_disc + estim_ele_forecast_disc, na.rm=T)))
print(paste("Total net margin", sum(data$net_margin - estim_pow_revenues - estim_ele_revenues + estim_pow_forecast_disc + estim_ele_forecast_disc, na.rm=T)))





