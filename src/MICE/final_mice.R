# Final MICE script

library(mice)

# Running the function definition for boot_mice()
# This function does one iteration of the bootstrap procedure that randomly
# generates NAs and imputes them using mice(), it returns the nRMSE value obtained.
source("boot_mice.R")
# NOTE: Make sure this file is in the working directory.

# Reading the dataset without NAs
original<-read.table("Dataset3.csv",sep=",",header=T)
dim(original)
original<-original[,-1]
# Very important to eliminate the observation index column, otherwise the boot_mice()
# function will not work. IT only allows for datasets where all the columns except the
# two first ones are numerical values withou NAs.

# Proportions of missing data that we will impose in the dataset for testing
prop<-0.1*(1:8)

# Number of times we do the bootstrapping to calculate the RMSE
iter<-20

# This is where we will save the error and the error variance over the bootstrap iterations.
mean_nRMSE<-var_nRMSE<-c()

# Iteration over all percentages of missing values that we simulate
for(p in seq_along(prop)){
  
  # Simulation of missing values to calculate the error with bootstrap
  
  # Initialization of the vector where we record the RMSE for each iteration
  rmse<-rep(NA,iter)
  for(i in 1:iter){
    cat("iteration",i,"\n")
    
    rmse[i]<-boot_mice(data=original,prop=p)
    # By default, boot_mice uses the method norm.predict to impute values.
  }
  
  # Calculate the mean and variance of nRMSE over all iterations
  # and save them in a data.frame
  mean_nRMSE<-c(mean_nRMSE,mean(rmse))
  var_nRMSE<-c(var_nRMSE,var(rmse))
}

# Plotting the mean nRMSE versus the percentage of missing data, with an error bar.
plot(prop,mean_nRMSE,ylim=c(min(mean_nRMSE-sqrt(var_nRMSE)),max(mean_nRMSE+sqrt(var_nRMSE))))
arrows(prop,mean_nRMSE-sqrt(var_nRMSE),prop,mean_nRMSE+sqrt(var_nRMSE),length=0.05,angle=90,code=3)
# This plot gives an idea of how the nRMSE changes over the boostrap iterations. It is quite volatile.


# These are the values obtained when executed for the report:
# mean of nRMSE
# c(22.34060, 24.10332, 23.45088, 24.82278, 26.14981, 27.91098, 27.75493, 26.72592)
# variance of nRMSE
# c(10.921445, 29.358364, 11.147314, 8.298710, 8.675457,4.884527, 2.293331, 2.436879)