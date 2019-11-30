boot_mice<-function(data, prop=0.3,method.used="norm.predict",return.imputation=FALSE){
  
# Function that randomly introduces NAs in the dataset and imputes them using MICE 
# ARGUMENTS
  # data: data.frame without NAs where bootstrap will be applied to test the imputation
  # prop: proportion of individual observations that will be set to NA in the dataset
  #         30% by default
  # method.used: method included in the MICE library used for imputation
  #             norm.predict by default
  # return.imputation: logical value indicating wether the outcome of the mice() call
  #                    should be returned
  
# NOTE: No NA values will be introduced in the first two columns, and the rest must be numeric.
  
  # Ensure that the data.frame has no NAs
  if(sum(is.na(data))>0){
    cat("Error: The introduced data.frame has NA values.")
    break
  }
  
  # Make sure the MICE library is loaded
  require(mice)
  
  # Number of observations in our dataset without NAs
  n<-dim(data)[1]
  # Number of variables
  m<-dim(data)[2]
  
  # Number of observations of data left out for testing with bootstrapping
  p<-floor(n*prop)
  
  # Take a random subsample 
  boot1<-sample(1:n,p,replace = T)
  boot2<-sample(3:m,p,replace =T)
  btrain<-data
  
  sum_extracted<-0
  for(j in 1:p){
    # Introduce NA in each index of the data.frame
    btrain[boot1[j],boot2[j]]<-NA
    # Calculate average of the true values set to NA
    sum_extracted<-sum_extracted+data[boot1[j],boot2[j]]
  }
  cat(prop*100,"% NAs randomly generated","\n")
  
  # This is the mean of the values set to NA, used to normalize RMSE later on
  mean_extracted<-sum_extracted/p
  cat("The average of all extracted values is: ",mean_extracted,"\n")
  
  # Data imputation with method norm.predict
  # (imputes univaraite missing data using the predicted value from a linear regression)
  imputed<-mice(btrain,method=method.used,printFlag = F)
  cat("Training dataset imputed", "\n")
  
  # imputed$imp returns the imputed values for each variable and for each iteration of MICE
  # With each call to mice() we get 5 (by default) complete datasets
  
  # Fill in the dataset with simulated NAs with imputed values
  completed<-complete(imputed,1)[,-c(1,2)]
  for(comp in 2:5){
    completed<-complete(imputed,comp)[,-c(1,2)] + completed
  }
  # This is the data completed with the average of all 5 iterations of mice
  completed<-completed/5 
  error<-data[,-c(1,2)]-completed
  
  # Calculation of the RMSE
  rmse<-sqrt(sum(error^2)/p)/mean_extracted*100
  # This is the other error measure we talked about, but it is not computed right now
  # mpe<-sum(abs(error)/original[-c(1,2)])/ntest*100
  
  cat("The normalized Root Mean Squared Error is ",rmse,"\n","\n")
  
  if(return.imputation) list(rmse,imputed)
  else
  c(rmse) # The returned value
}
