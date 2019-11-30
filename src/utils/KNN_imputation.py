# CODE USED TO IMPUTE DATASET 1 and 2
# ------------------------------------- Functions used -------------------------------------

import pandas as pd
import numpy as np

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
    
# ----------------------------------------------------------------------------------------------------------------------------------------------------------

# Import data
Dataset1 = pd.read_csv("data/Dataset1.csv", sep=',', header=0)  # with all possible combination of subdistricts and months
Dataset2 = pd.read_csv("data/Dataset2.csv", sep=',', header=0)  # only combination present in the original dataset

column_names = [s for s in Dataset1.columns.values.tolist() if "_SMEB_" in s]   #list of columns to melt

# Melt columns to have all prices in one column
Dataset1_melt = pd.melt(Dataset1, id_vars=['month2','q_sbd'], value_vars=column_names)
Dataset2_melt = pd.melt(Dataset2, id_vars=['month2','q_sbd'], value_vars=column_names)

# Remove duplicates in melt_series, ie. for multiple observers. (six duplicates removed) (Otherwise cannot unmelt)
Dataset2_melt = Dataset2_melt.drop_duplicates(subset = ['month2', 'q_sbd', 'variable'], keep="first")



# ------------------------------------- Imputation of Data -------------------------------------
import time

k = 3

# start_time = time.time()                                                  # Uncomment to have the time

# Impute datasets with KNN method
Dataset1_melt_KNNimp = impute_melt(Dataset1_melt, k, ['q_sbd','variable'])
Dataset2_melt_KNNimp = impute_melt(Dataset2_melt, k, ['q_sbd','variable'])

# Can happen that some NA's are still present (if column was entirely unknown).
# Impute with the mean of the item prices for the same months in all subdistricts
Dataset1_melt_imp = Dataset1_melt_KNNimp.groupby(['month2', 'variable'],sort=False).apply(lambda x: x.fillna(
    value=x.mean())).reset_index(drop=True)
Dataset2_melt_imp = Dataset2_melt_KNNimp.groupby(['month2', 'variable'],sort=False).apply(lambda x: x.fillna(
    value=x.mean())).reset_index(drop=True)

# print("--- Total time: %s seconds ---" % (time.time() - start_time))      # Uncomment to have the time

# Unpivot to original format
Dataset1_imp = Dataset1_melt_imp.set_index(['month2', 'q_sbd', 'variable'])['value'].unstack().reset_index()
Dataset2_imp = Dataset2_melt_imp.set_index(['month2', 'q_sbd', 'variable'])['value'].unstack().reset_index()

# To csv.
Dataset1_imp.to_csv("data/Dataset1_KNNimputed.csv", sep=',')
Dataset2_imp.to_csv("data/Dataset2_KNNimputed.csv", sep=',')