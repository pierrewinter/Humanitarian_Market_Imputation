# BCG Machine Learning case
# Author: Mario Tomasello


require("caret")
require("e1071")
require("lubridate")
require("RANN")
require("logicFS")
require("earth")
require("mda")
require("MASS")


# Function to print dataframe summary
print_data_summary <- function(data) {
    data_description <- sapply(data, FUN=function(x){
      #print(x)
      stats <- c(type=class(x),
                 fill_rate=as.numeric(100.0-sum(is.na(x)|as.character(x)=="")*100/length(x)),
                 distinct_values=length(unique(x)))
      return(stats)})
    print(t(data_description))
}



# Function to compute "cmgr" for each field - Compound Monthly Growth Rate - see processing of historical data below
compute_cmgr <- function(input_data, field_name) {
  #input_data <- hist_train_base #TEST: DELETE
  #field_name <- "price_p1_var"  #TEST: DELETE
  cmgr_vector <- NULL
  unique_IDs <- unique(input_data$id)
  for (ctrl_id in unique_IDs) {
    data_subset <- input_data[input_data$id==ctrl_id,]
    price_month_begin <- min(data_subset$price_month[!is.na(data_subset[, field_name])])
    price_month_end  <-  max(data_subset$price_month[!is.na(data_subset[, field_name])])
    value_begin <- data_subset[data_subset$price_month==price_month_begin, field_name]
    value_end  <-  data_subset[data_subset$price_month==price_month_end,   field_name]
    if(is.infinite(price_month_begin)|is.infinite(price_month_end)|(price_month_begin==price_month_end)) {
      cmgr_value <- NA
      #print(paste("check", ctrl_id)) #TEST: DELETE
    } else {
      if (value_begin==0) {
        cmgr_value <- NA
      } else {
        cmgr_value <- 100.0*((value_end/value_begin)^(1/(price_month_end-price_month_begin))-1)
      }
    }
    cmgr_vector <- c(cmgr_vector, cmgr_value)
  }
  cmgr <- data.frame(id=unique_IDs, value=cmgr_vector)
  names(cmgr) <- c("id", paste(field_name, "_cmgr", sep=""))
  return(cmgr)
}




# Function to read and aggregate historical price data
read_and_aggregate_data <- function(input_history, input_training) {
  
    # Read historical data
    hist_train <- read.csv(input_history, stringsAsFactors = TRUE)
    # Read training data
    data_input <- read.csv(input_training, stringsAsFactors = TRUE)
 
    
    # Converting price_date to Date format and extracting month
    hist_train$price_month <- month(as.Date(hist_train$price_date))
    control_id <- hist_train$id
    hist_train_preproc <- hist_train[,c("price_p1_var", "price_p2_var", "price_p3_var", "price_p1_fix", "price_p2_fix", "price_p3_fix")]
    hist_train_base <- hist_train[,c("id", "price_month", "price_p1_var", "price_p2_var", "price_p3_var", "price_p1_fix", "price_p2_fix", "price_p3_fix")]
    
    # Computing mean, s.d., min and max values for each field
    hist_train_mean <- aggregate(hist_train_preproc, by=list(id=control_id), FUN=function(x)mean(x, na.rm=TRUE))
    hist_train_sd  <-  aggregate(hist_train_preproc, by=list(id=control_id), FUN=function(x)sd(x, na.rm=TRUE))
    #hist_train_min <-  aggregate(hist_train_preproc, by=list(id=control_id), FUN=function(x)min(x, na.rm=TRUE))
    #hist_train_max <-  aggregate(hist_train_preproc, by=list(id=control_id), FUN=function(x)max(x, na.rm=TRUE))
    
    
    hist_train_cmgr <- merge(merge(merge(merge(merge(
                             compute_cmgr(hist_train_base, "price_p1_var"),
                             compute_cmgr(hist_train_base, "price_p2_var"), by="id"),
                             compute_cmgr(hist_train_base, "price_p3_var"), by="id"),
                             compute_cmgr(hist_train_base, "price_p1_fix"), by="id"),
                             compute_cmgr(hist_train_base, "price_p2_fix"), by="id"),
                             compute_cmgr(hist_train_base, "price_p3_fix"), by="id")
                            
    
    # Joining the aggregate dataframes with original dataframe (for extracting "cmgr" - see below)
    hist_train_final <- merge(merge(merge(
                              hist_train_base, hist_train_mean, by="id", suffixes=c("", "_mean")),
                              hist_train_sd, by="id", suffixes=c("", "_sd")),
                              hist_train_cmgr, by="id")
    
    hist_train_final <- unique(hist_train_final[,!colnames(hist_train_final) %in% c("price_month", "price_p1_var", "price_p2_var", "price_p3_var", "price_p1_fix", "price_p2_fix", "price_p3_fix")])
    
    
    # Join training data with historical data
    data_hist <- merge(data_input, hist_train_final, by="id")
    
    data_preprocess_01 <- data_hist
    
    data_preprocess_01$date_activ       <- as.Date(ifelse(data_preprocess_01$date_activ=="", NA,       as.character(data_preprocess_01$date_activ)))
    data_preprocess_01$date_end         <- as.Date(ifelse(data_preprocess_01$date_end=="", NA,         as.character(data_preprocess_01$date_end)))
    data_preprocess_01$date_first_activ <- as.Date(ifelse(data_preprocess_01$date_first_activ=="", NA, as.character(data_preprocess_01$date_first_activ)))
    data_preprocess_01$date_modif_prod  <- as.Date(ifelse(data_preprocess_01$date_modif_prod=="", NA,  as.character(data_preprocess_01$date_modif_prod)))
    data_preprocess_01$date_renewal     <- as.Date(ifelse(data_preprocess_01$date_renewal=="", NA,     as.character(data_preprocess_01$date_renewal)))
    
    data_preprocess_01$date_activ_diff       <- as.numeric(as.Date("2016-03-01") - data_preprocess_01$date_activ)
    data_preprocess_01$date_end_diff         <- as.numeric(as.Date("2016-03-01") - data_preprocess_01$date_end)
    data_preprocess_01$date_first_activ_diff <- as.numeric(as.Date("2016-03-01") - data_preprocess_01$date_first_activ)
    data_preprocess_01$date_modif_prod_diff  <- as.numeric(as.Date("2016-03-01") - data_preprocess_01$date_modif_prod)
    data_preprocess_01$date_renewal_diff     <- as.numeric(as.Date("2016-03-01") - data_preprocess_01$date_renewal)
    
    print_data_summary(data_preprocess_01)

    return(data_preprocess_01)
}




# Function to relevel factors when levels have too few observations
aggregate_levels <- function(data, col_name, threshold, replacement) {

  rank <- sort(table(data[,col_name]), decreasing=T)
  to_replace <- rank[rank<=(nrow(data)*threshold)]
  data[,col_name] <- as.character(data[,col_name])
  data[data[,col_name] %in% names(to_replace), col_name] <- replacement
  data[,col_name] <- as.factor(data[,col_name])
  return(data)
}



# Read and pre-process training data
data_preprocessing <- function(data, remove_NA_num_fields="no", NA_threshold=0.4, feature_selection_corr="no", NA_treatment="knnImpute", pca="no") {
    
    # Replacing "infinite" values with NAs  
    data$price_p1_var_cmgr[is.infinite(data$price_p1_var_cmgr)] <- NA
    data$price_p2_var_cmgr[is.infinite(data$price_p2_var_cmgr)] <- NA
    data$price_p3_var_cmgr[is.infinite(data$price_p3_var_cmgr)] <- NA
    data$price_p1_fix_cmgr[is.infinite(data$price_p1_fix_cmgr)] <- NA
    data$price_p2_fix_cmgr[is.infinite(data$price_p2_fix_cmgr)] <- NA
    data$price_p3_fix_cmgr[is.infinite(data$price_p3_fix_cmgr)] <- NA
    
    # Filtering out numeric columns - if requested by user
    if (remove_NA_num_fields=="yes") {
      data_preprocess_01 <- data[, !sapply(data, is.numeric) | sapply(data, FUN=function(x)return(as.numeric(1.0*sum(is.na(x)|as.character(x)=="")/length(x))<NA_threshold) )]
    } else {
      data_preprocess_01 <- data
    }
    
    # Removing empty variable "campaign_disc_ele" and columns of class "Date"
    data_preprocess_02 <- data_preprocess_01[, (colnames(data_preprocess_01)!="campaign_disc_ele") & (!sapply(data_preprocess_01, is.Date))]
    
    # Hard-coding empty values in factors
    data_preprocess_03 <- data_preprocess_02
    for (col in 1:ncol(data_preprocess_03)) {
      if(is.factor(data_preprocess_03[,col])) {
        y = as.character(data_preprocess_03[,col])
        y[is.na(y)|y==""] <- "Empty"
        unique(y)
        data_preprocess_03[,col] <- as.factor(y)
      }
    }
    
    data_preprocess_04 <- data_preprocess_03
    data_preprocess_04 <- aggregate_levels(data_preprocess_04, "activity_new", 1/12, "Other")
    data_preprocess_04 <- aggregate_levels(data_preprocess_04, "channel_sales", 1/10, "Other")
    data_preprocess_04 <- aggregate_levels(data_preprocess_04, "origin_up", 0.23, "Other")
    
    #sort(table(data_preprocess_04$activity_new))
    #sort(table(data_preprocess_04$channel_sales))
    #sort(table(data_preprocess_04$origin_up))
    
    
    # Eliminate highly correlated predictors - if requested by user
    if (feature_selection_corr=="yes") {
      correlation_matrix_spearman <- cor(data_preprocess_04[,sapply(data_preprocess_04, FUN=function(x){is.numeric(x)|is.integer(x)})], use="pairwise.complete.obs", method="spearman")
      highly_corr_variables <- findCorrelation(x=correlation_matrix_spearman, cutoff=0.6, exact=TRUE, names=TRUE)
      data_preprocess_05 <- data_preprocess_04[,!colnames(data_preprocess_04) %in% highly_corr_variables]
    } else {
      data_preprocess_05 <- data_preprocess_04
    }
    
    # Impute missing values for numerical predictors - if requested by user
    if (NA_treatment=="knnImpute") {
      data_preprocess_06 <- predict(preProcess(data_preprocess_05, method="knnImpute"), data_preprocess_05)
    } else if (NA_treatment=="remove") {
      data_preprocess_06 <- data_preprocess_05[complete.cases(data_preprocess_05),]
    } else if (NA_treatment=="leave") {
      data_preprocess_06 <- data_preprocess_05
    }
    
    # Perform a PCA if requested by user
    if (pca=="yes") {
      data_preprocess_07 <- predict(preProcess(data_preprocess_06, method="pca"), data_preprocess_06)
    } else if (pca=="no") {
      data_preprocess_07 <- data_preprocess_06
    } else if (pca=="yeojohn") {
      data_preprocess_07 <- predict(preProcess(data_preprocess_06, method="YeoJohnson"), data_preprocess_06)
    } 
    
    # Center and scale predictors
    data_preprocess_08 <- predict(preProcess(data_preprocess_07, method=c("center", "scale")), data_preprocess_07)
    
    # Return complete observations
    data_preprocess_09 <- data_preprocess_08[complete.cases(data_preprocess_08),]
    
    # Save data
    data_preprocessed <- data_preprocess_09
    save(data_preprocessed, file=paste(getwd(),"/output/data_preprocessed_NAfields", remove_NA_num_fields, "_corr", feature_selection_corr, "_NA", NA_treatment, "_pca", pca, ".Rdata", sep=""))
    
    return(data_preprocess_09)
}




# Function to read and join response to training data
aggregate_output <- function (data_train, input_response) {
  
  output <- read.csv(input_response, stringsAsFactors = TRUE)
  data <- merge(data_train, output, by="id")

  # Formatting levels of response to characters (if numeric, train function will crash)
  data$churn <- as.character(data$churn)
  data$churn[data$churn==0] <- "No"
  data$churn[data$churn==1] <- "Yes"
  data$churn <- as.factor(data$churn)
  
  # Removing customer_id factor - not needed for training
  data_output <- data[,!colnames(data)%in% c("id")]
  return(data_output)
}




# Wrapper functions for rfe and fits
train_model <- function(data_for_training, method="rfe") {
  
  # defining auxiliry control functions
  fiveStats <- function(...) c(twoClassSummary(...), defaultSummary(...))
  svmFuncs <- caretFuncs
  svmFuncs$summary <- fiveStats
  caretFuncs$summary <- fiveStats
  lmFuncs$summary <- fiveStats
  rfFuncs$summary <- fiveStats
  
  # Training control (for inner CV loop)
  train_control<- trainControl(method="cv", number=10, classProbs = TRUE, summaryFunction = twoClassSummary)
  
  if (method=="rfe_rf") {
    control <- rfeControl(method = "cv",number = 12,verbose = TRUE,saveDetails = TRUE,functions = rfFuncs)
    model <- rfe(x = data_for_training[, !colnames(data_for_training) %in% c("churn")],
                 y = data_for_training$churn,
                 sizes = c(1:(ncol(data_for_training)-2)),
                 metric = "ROC",
                 rfeControl = control,
                 method = "rf",
                 na.action=na.omit,
                 trControl = train_control)
    
  } else if (method=="rfe_svm_lin") {
    control <- rfeControl(method = "cv",number = 12,verbose = TRUE,saveDetails = TRUE,functions = rfFuncs)
    model <- rfe(x = data_for_training[, !colnames(data_for_training) %in% c("churn")],
                 y = data_for_training$churn,
                 sizes = c(1:(ncol(data_for_training)-2)),
                 metric = "ROC",
                 rfeControl = control,
                 method = "svmLinear",
                 na.action=na.omit,
                 trControl = train_control)
    
  } else if (method=="rfe_svm_rad") {
    control <- rfeControl(method = "cv",number = 12,verbose = TRUE,saveDetails = TRUE,functions = rfFuncs)
    model <- rfe(x = data_for_training[, !colnames(data_for_training) %in% c("churn")],
                 y = data_for_training$churn,
                 sizes = c(1:(ncol(data_for_training)-2)),
                 metric = "ROC",
                 rfeControl = control,
                 method = "svmRadial",
                 na.action=na.omit,
                 trControl = train_control)
    
  } else if (method =="glm") {
    model <- train(churn~., data=data_for_training, trControl=train_control, method="glm",
                   family=binomial(), na.action=na.omit, metric="ROC")
  } else if (method == "rf") {
    model <- train(churn~., data=data_for_training, trControl=train_control,
                      method="rf", na.action=na.omit, metric="ROC", verbose=T)
  } else if (method == "AdaBag") {
    model <- train(churn~., data=data_for_training, trControl=train_control,
                          method="AdaBag", na.action=na.omit, metric="ROC")
  } else if (method == "bagFDA") {
    model <- train(churn~., data=data_for_training, trControl=train_control, method="bagFDA",
                   na.action=na.omit, metric="ROC")
  } else if (method == "LDA") {
    model <- train(churn~., data=data_for_training, trControl=train_control, method="lda2",
                   na.action=na.omit, metric="ROC")
  } else if (method == "svmRadial") {
    model <- train(churn~., data=data_for_training, trControl=train_control, method="svmRadial",
                   na.action=na.omit, metric="ROC", verbose=T)
  } else if (method == "knn") {
    model <- train(churn~., data=data_for_training, trControl=train_control, method="knn",
                       na.action=na.omit, metric="ROC")
  } else if (method == "nnet") {
    model <- train(churn~., data=data_for_training, trControl=train_control, method="nnet",
                   na.action=na.omit, metric="ROC")
  } else if (method == "penalized") {
    model <- train(churn~., data=data_for_training, trControl=train_control, method="glmnet", tuneLength=10,
                   na.action=na.omit, metric="ROC")
  }
  
  return(model)
}










