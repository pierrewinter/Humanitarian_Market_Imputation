**Introduction:**  
This repository contains the report "Imputation of Missing Price Values: Supporting Cash-Based Humanitarian Responses in Northern Syria" along with the supporting data and source code. It was created as part of the Fall 2019 Hack4Good Event at ETH Zurich in which our team developed a data science solution to a humanitarian problem in 8 weeks. Our team consisted of 4 ETH Zurich students and we collaborated with IMPACT Initiatives, an NGO which monitors and evaluates humanitarian and development interventions in order to support aid actors in assessing the efficiency and efficacy of their programmes. We present analytical methods which impute missing price values in a sparse data set. This allows for more accurate and effective cash-based humanitarian programming in conflict regions around the world.

**Useful Links:**
*  [IMPACT Initiatives Website](https://www.impact-initiatives.org)
*  [Hack4Good 2019](https://analytics-club.org/hack4good)

**Imputation Methods:**\
Three distinct methods to impute a sparse matrix of price data have been made available as follows.

1. Python-based Sequential Forward Fill

/data/processed	- - - ffill_imputation.csv is an imputed and complete Dataset1\
/src/utils - - - hack4good_impact_create_melt.py reformats a price data matrix to prepare for imputation in hack4good_impact_imputation_ffill.py\
/src/utils - - - hack4good_impact_imputation_ffill.py performs sequential imputation of NA by increasingly coarse methods


2. Python-based Adapted K-Nearest Neighbors (KNN)

/data/processed - - - Dataset1_KNNimputed.csv is an imputed and complete Dataset1\
/src/utils - - - KNN_imputation.py performs KNN imputation of NA by grouping over time series\
/src/utils - - - KNN_results.py produces plots of nRMSE vs percentage of values removed


3. R-based Multivariate Imputation by Chained Equations (MICE)

/src/utils - - - boot_mice.R creates random NA values and computes the nRMSE for a given dataset\
/src/utils - - - final_mice.R takes the average error over 20 bootstrap iterations as a function of percentage of values removed\
/src/utils - - - plots_mice.R creates the density plots and creates the imputation for Dataset1 and Dataset2


```
├── LICENSE
│
│
├── README.md                <- The top-level README for developers using this project
│                          
│
├── data
│   └── processed            <- The final imputed data sets for modeling.
│ 
│
├── reports                   <- Written report in PDF format
│
│
├── src                      <- Source code of this project. All final code comes here (Notebooks are thought for exploration)
│   │
│   └── utils                <- Scripts to create visualizations, parse datasets, and create results


```

