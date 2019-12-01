# CODE TO REPRODUCE RESULTS SHOWED IN THE REPORT AND THE PRESENTATION 
# ------------------------------------- Functions used -------------------------------------

import pandas as pd
import numpy as np

#drop randomly ratio*size(df) variables from df and returns also the indices of variables removed
def remove_value(df, ratio):
    nan_indices = np.random.choice(df.index, size=int(len(df)*ratio), replace=False)
    df.loc[nan_indices,'value'] = np.nan
    return df, nan_indices

# fill with mean of k neighbors
# for each NaN value, create a vector containing the first k neighbors (left and right)
# that are not NaN and imput the mean of that vector.
def mean_k_neighbors(dfX,k):
    X = np.array(dfX['value']).copy()   #array containing time-serie

    #if whole column is NA, can't impute and do not modify the NA
    if np.sum(np.isnan(X)) == len(X):
        dfX['value'] = X
        return dfX

    max_i = len(X)
    for i in range(0,max_i):    #iterate over all elements of the time-serie 

        if np.isnan(X[i]):      #if Nan:impute
            neighbors = []

            # k existing neighbors before X[i] (left)
            count = 0
            j = i
            while (count < k) & (j >= 0):   #takes the closest exsiting values until reach K values or the end of the vector
                while np.isnan(X[j]):
                    j -= 1
                    if j == 0:
                        break
                if j >= 0:
                    neighbors.append(X[j])
                    count += 1
                    j -= 1

            # k existing neighbors after X[i] (right)
            count = 0
            j = i
            while (count < k) & (j < max_i):    #takes the closest exsiting values until reach K values or the end of the vector
                while np.isnan(X[j]):
                    j += 1
                    if j == max_i:
                        break
                if j < max_i:
                    neighbors.append(X[j])
                    count += 1
                    j += 1

            #impute X[i] with mean of neighbors    
            X[i] = round(np.mean(neighbors),2)
            dfX['value'] = X
    return dfX 

#apply mean k neighbors on all subgroups made with name_columns_to_groupby
def impute_melt(df, k, name_columns_to_groupby):

    #make subgroups and get keys (subgroups = time-series)
    df_grp = df.groupby(name_columns_to_groupby)
    name_keys = list(df_grp.groups.keys())

    #stack all subgroups filled 
    for i in range(0,len(name_keys)):
        grp = df_grp.get_group(name_keys[i])
        grp_filled = mean_k_neighbors(grp.copy(),k)         #impute with adapted knn
        if i == 0:
            grps_filled = grp_filled
        else:
            grps_filled = grps_filled.append(grp_filled)
    df_KNNimputed = grps_filled.sort_index()
    return df_KNNimputed

# calculate the RMSE score between the original dataset and the imputed one
# df_f is filled df, df_o is original, nan_ind is index of NaN values
def RMSE_score(df_f,df_o,nan_ind):
    err = np.mean((df_f.loc[nan_ind,'value'] - df_o.loc[nan_ind,'value'])**2)**(1/2)
    err_norm = err / np.mean(df_o.loc[nan_ind,'value'])
    RMSE = 100*err_norm
    return RMSE
    

# ----------------------------------------------------------------------------------------------------------------------------------------------------------

# Import data
clean_series = pd.read_csv("data/clean_series.csv", sep=',', header=0)

# ------------------------------------- Preprocessing of Data -------------------------------------

# Create list of relevant columns names
column_names = [s for s in clean_series.columns.values.tolist() if "_SMEB_" in s]
unwanted_SMEB = {'Price_SMEB_total_wfloat',
                 'Price_SMEB_total_sanswater',
                 'Price_SMEB_usd',
                 'Price_SMEB_food',
                 'Price_SMEB_nfi',
                 'Price_SMEB_Cooking_oils',
                 'Price_SMEB_nfi_soaps',
                 'Price_SMEB_Kerosene',
                 'Price_SMEB_LP_Gas',
                 'Price_SMEB_Tomatoes',
                 'Price_SMEB_Potatoes',
                 'Price_SMEB_Onions',
                 'Price_SMEB_Cucumbers'
                }
column_names = [e for e in column_names if e not in unwanted_SMEB]
columns_to_melt = column_names.copy()
column_names.insert(0,'q_sbd')
column_names.insert(0,'month2')

# Subset with only SMEB full, pivoted such as all prices are in one column
clean_series_SMEB_full = clean_series[clean_series['smeb_complete']==True]
clean_series_SMEB_full = clean_series_SMEB_full[column_names]
melted_data_SMEB_full = pd.melt(clean_series_SMEB_full, id_vars=['month2','q_sbd'], value_vars=columns_to_melt)
melt_full = melted_data_SMEB_full.copy()


# ------------------------------------- Imputation of Data -------------------------------------
import time

ratio_vect = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]   # Ratio of NA to randomly add in the dataset (%)
n_iter = 20                                             # Number of iterations (RMSE value can vary form one iteraiton to the other due to
                                                        # randomness when removing values).
                                                        # Final RMSE is the mean of RMSE's for each iteration
k_vect=[1,2,3,4,5,8,10]                                 # Parameter for KNN

RMSE_vect = []  #final vector containing all the results printed

start_time = time.time()
for k in k_vect:
  print('K = {}'.format(k))

  RMSEs_means = []
  for ratio in ratio_vect:

    RMSEs = []
    for _ in range(0,n_iter):

        # Replace randomly values by Na's in Dataset. Returns Dataset with missing values and corresponding list of indices
        out = remove_value(melt_full.copy(), ratio)
        melt_full_imput = out[0]; nan_indices = out[1]

        # Impute dataset with KNN method
        melt_full_KNNimputed = impute_melt(melt_full_imput, k, ['q_sbd','variable'])

        # Can happen that some NA's are still present (if column was entirely unknown).
        # Impute with the mean of the item prices for the same months in all subdistricts
        melt_full_imputed = melt_full_KNNimputed.groupby(['month2', 'variable'],sort=False).apply(lambda x: x.fillna(
              value=x.mean())).reset_index(drop=True)

        # Compute RMSE score
        RMSE = RMSE_score(melt_full_imputed, melt_full, nan_indices)
        RMSEs.append(RMSE)
    RMSEs_mean = np.mean(RMSEs)
    print('Final RMSE is {} for {}% of values removed'.format(RMSEs_mean,ratio))
    RMSEs_means.append(RMSEs_mean)
  RMSE_vect.append(RMSEs_means)

print("--- Total time: %s seconds ---" % (time.time() - start_time))

# ------------------------------------- Save/Load RMSE calculated -------------------------------------
# import pickle

# Uncomment if wants to save RMSE_vect
# with open("RMSE_vect.txt", "wb") as fp:   #Pickling
#  pickle.dump(RMSE_vect, fp)

# Uncomment if wants to load RMSE_vect
# with open("RMSE_vect.txt", "rb") as fp:   # Unpickling
#  RMSE_vect = pickle.load(fp)

# ------------------------------------- Plot results -------------------------------------
# Results can be either plotted raw, or a regression (linear or polynomial of degree 2) can be applied on them first
import matplotlib.pyplot as plt

# uncomment if regression is needed
# from sklearn.linear_model import LinearRegression
# degree = 1
# degree = 2

# ratio_f contains the different ratio used in [%]
# RMSE_f contains the different RMSE obtained for each k and each ratio
ratio_vect_perc = [100*s for s in ratio_vect]
ratio_f = np.array(ratio_vect_perc)
RMSE_f = np.array(RMSE_vect)

colors = ['red', 'green', 'blue', 'yellow', 'orange', 'brown', 'pink']

fig = plt.figure(figsize=(12, 8))
ax = fig.subplots()

plt.xlim(ratio_f[0], ratio_f[len(ratio_f)-1])
plt.grid(True)

plt.xlabel('ratio of values removed (%)', fontsize=16)
plt.ylabel('RMSE (mean over 20 iterations)',fontsize=16)
plt.title('RMSE scores for different K ',fontsize=20)

ax.tick_params(axis='x', labelsize=16)
ax.tick_params(axis='y', labelsize=16)

for i in range(0,len(k_vect)):
    plt.plot(ratio_f, RMSE_f[i], colors[i], linewidth = 2)

# uncomment if regression is needed
#for i in range(0,len(k_vect)):   
#    z = np.polyfit(ratio_f, RMSE_f[i],degree)
#    p = np.poly1d(z)
#    plt.plot(ratio_f, p(ratio_f), colors[i], linewidth = 2)

plt.legend(['K=1','K=2','K=3','K=4','K=5','K=8','K=10'], loc='lower right',fontsize=16)

plt.show()