**Introduction:**  
This repository contains the the report "Imputation of Missing Price Values: Supporting Cash-Based Humanitarian Responses in Northern Syria" and supporting data and source code. It was created as part of the Fall 2019 Hack4Good Event at ETH Zurich in which our team developed a data science solution to a humanitarian problem in 8 weeks. Our team consisted of 4 ETH Zurich students and we collaborated with IMPACT Initiatives, an NGO which monitors and evaluates humanitarian and development interventions in order to support aid actors in assessing the efficiency and efficacy of their programmes. We present analytical methods which impute missing price values in a sparse data set. This allows for more accurate and effective cash-based humanitarian programming in conflict regions around the world.

**Useful Links:**
*  [IMPACT Initiatives Website](https://www.impact-initiatives.org)
*  [Hack4Good 2019](https://analytics-club.org/hack4good)

**Comment Section**
Three distinct methods to impute a sparse matrix of price data have been made available as follows.

Python-based Sequential Forward Fill;

/data/processed	- - - ffill_imputed is an imputed and complete Dataset1.
/src/utils - - - hack4good_impact_create_melt.py, which reformats a price data matrix to prepare for imputation in hack4good_impact_imputation_ffill.py; - - - hack4good_impact_imputation.py for sequential imputation of NA by increasingly coarse methods.


Python-based Adapted K-Nearest Neighbors (KNN);

/data/processed - - - contains Dataset1_KNNimputed, imputed based on KNN_imputation.
/src/utils - - - KNN_imputation - - - KNN_results reproduces the graph with RMSE vs ratio of values removed.


R-based Multivariate Imputation by Chained Equations (MICE);

/src/utils - - - contains boot_mice.R, the function that creates random NAs and computes the nRMSE for a given dataset - - - final_mice.R is the script with which the average of 20 iterations of bootstrap for proportions of missingness from 0.1 to 0.8 is calculated - - - plots_mice.R is the script used to create the density plots and creates the imputation for Dataset1 and Dataset2.


```
├── LICENSE
│
│
├── README.md                <- The top-level README for developers using this project
│                          
│
├── data
│   └── processed            <- The final, canonical data sets for modeling.
│ 
│
├── reports                   <- Generated analysis as HTML, PDF, LaTeX, etc.
│   └── figures               <- Generated graphics and figures to be used in reporting
│
│
├── src                      <- Source code of this project. All final code comes here (Notebooks are thought for exploration)
│   ├── __init__.py          <- Makes src a Python module
│   ├── main.py              <- main file, that can be called.
│   │
│   │
│   └── utils                <- Scripts to create exploratory and results oriented visualizations


```

