# Script for the generation of the plots in the report

# Make sure the package mice is loaded
require(mice)

# Executing funciton boot_mice()
source("boot_mice.R")

# Read all three datasets

dataset1<-read.table("Dataset1.csv",header=TRUE,sep=',')
dataset1<-dataset1[,-1]
dataset2<-read.table("Dataset2.csv",header=TRUE,sep=',')
dataset2<-dataset2[,-1]
dataset3<-read.table("Dataset3.csv",header=TRUE,sep=',')
dataset3<-dataset3[,-1]

# Calculate the proportion of missingness in ethe first two datasets
prop1<-sum(is.na(dataset1))/(dim(dataset1)[1]*(dim(dataset1)[2]-2))
#prop1<-0.6 # Because aproximately 
prop2<-sum(is.na(dataset2))/(dim(dataset2)[1]*(dim(dataset2)[2]-2))

# Imputation of Datasets 1 and 2
imputed1<-mice(dataset1,method="norm.predict",printFlag = F)
imputed2<-mice(dataset2,method="norm.predict",printFlag = F)

# Fill in the dataset with imputed values
completed1<-complete(imputed1,1)[,-c(1,2)]
completed2<-complete(imputed2,1)[,-c(1,2)]
for(comp in 2:5){
  #completed1<-complete(imputed1,comp)[,-c(1,2)] + completed1
  completed2<-complete(imputed2,comp)[,-c(1,2)] + completed2
}
# This is the data completed with the average of all 5 iterations of mice
completed1<-completed1/5
completed2<-completed2/5

# These last two datasets are the imputation produced for Dataset1 and Dataset2 using mice.

# Now we can plot the empirical density of the original datasets in pink and 
# the one from the imputed datasets in blue. This density plots are part of the 
# mice package.
densityplot(imputed1)
densityplot(imputed2)

# We simulate from the complete available data, Dataset3, with the proportion of missing
# values in the two previous datasets how mice would behave, and generate the same plot.

imputed3_prop1<-boot_mice(data=dataset3,prop=prop1,return.imputation = T)[[2]]
imputed3_prop2<-boot_mice(data=dataset3,prop=prop2,return.imputation = T)[[2]]

densityplot(imputed3_prop1)
densityplot(imputed3_prop2)

# PROBLEM: When only introducing a 3.2% of NA into Dataset3, not all price variables "receive"
# an NA, so the density plot does not show all 20 price variables as in the rest of the cases.
# It doesn't look as good, it only shows 3 price variables that have been imputed.