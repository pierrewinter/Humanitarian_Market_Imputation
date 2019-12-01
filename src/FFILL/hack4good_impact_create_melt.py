# Reformats a price data matrix to prepare for imputation in hack4good_impact_imputation_ffill.py.
# Dependencies are a .csv "data.csv" acquired through .xlsx "reach_syr_dataset_market_monitoring_redesign_august2019", sheet "Subdistrict_Time_Series" as distributed by IMPACT Initiatives.

import pandas as pd

# Import .csv, incomplete data.
clean_series = pd.read_csv("data.csv", sep=',', header=0)

column_names = clean_series.columns.values.tolist()
column_names_with_SMEB_ = [s for s in column_names if "_SMEB_" in s]
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
column_names_with_SMEB_ = [e for e in column_names_with_SMEB_ if e not in unwanted_SMEB]
columns_to_melt = column_names_with_SMEB_.copy()

column_names_with_SMEB_.insert(0,'q_sbd')
column_names_with_SMEB_.insert(0,'month2')


# Generates an incomplete data set with relevant columns and melts set.
# Subdistricts for which the SMEB is not complete are kept, and NAs are only removed after.
clean_series_with_NA = clean_series[column_names_with_SMEB_]
melted_data_with_NA = pd.melt(clean_series_with_NA, id_vars=['month2','q_sbd'], value_vars=columns_to_melt).dropna()

# Write to file.
melted_data_with_NA.to_csv("melt_created.csv", sep='\t')

