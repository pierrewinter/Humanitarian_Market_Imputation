# Sequential imputation of NA by increasingly coarse methods.
# Dependencies are hack4good_impact_create_melt.py and a .csv "data.csv" acquired through .xlsx "reach_syr_dataset_market_monitoring_redesign_august2019", sheet "Subdistrict_Time_Series" as distributed by IMPACT Initiatives.

import pandas as pd
import itertools
import numpy as np
import math
import statistics


def impute_coarse(df, date_column, geo_column, consumable_column):
    """
    Sequentially imputes NA.
    """
    # Ffill time-based for certain sbd and certain object.
    df_ffill = df.groupby([geo_column, consumable_column]).apply(lambda x: x.fillna(method='ffill'))
    df_ffill_II = df_ffill.groupby([date_column, consumable_column]).apply(lambda x: x.fillna(method='ffill'))
    df_ffill_III = df_ffill_II.groupby([date_column]).apply(lambda x: x.fillna(method='ffill'))
    df_ffill_III['year'] = df_ffill_III[date_column].apply(lambda x: x.split('-')[0])
    df_ffill_IV = df_ffill_III.groupby(['year', consumable_column]).apply(lambda x: x.fillna(method='ffill'))
    df_ffill_V = df_ffill_IV.groupby([consumable_column]).apply(lambda x: x.fillna(method='ffill'))
    df_bfill_V = df_ffill_IV.groupby([consumable_column]).apply(lambda x: x.fillna(method='bfill'))

    return df_bfill_V


# Import .csv, complete data. The matrix is created in hack4good_impact_create_melt.py.
melt_series = pd.read_csv("melt_created.csv", sep='\t', header=0)
melt_series = melt_series.drop(['Unnamed: 0'], axis=1)

# Import .csv, incomplete data.
clean_series = pd.read_csv("data.csv", sep=',', header=0)

# Create a dataframe that contains all combinations of month2, q_sbd and variable.
month_unique = clean_series['month2'].unique()
subdistrict_unique = clean_series['q_sbd'].unique()

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

all_unique = [month_unique, subdistrict_unique, column_names_with_SMEB_]
all_comb = list(itertools.product(*all_unique))

columns = ['month2', 'q_sbd', 'variable']

comb_df = pd.DataFrame(all_comb, columns=columns)

# Remove duplicates in melt_series, ie. for multiple observers. Note: these duplicates should in fact be considered and e.g. averaged.
melt_series = melt_series.drop_duplicates(subset = ['month2', 'q_sbd', 'variable'], keep="first")

# Merge the complete df with all available prices.
merge_combination = pd.merge(comb_df, melt_series, how='left', left_on=['month2', 'q_sbd', 'variable'],
                      right_on=['month2', 'q_sbd', 'variable'])

# Execute imputation.
supercoarse_df = impute_coarse(merge_combination, 'month2', 'q_sbd', 'variable')

# Drop year.
supercoarse_df = supercoarse_df[['month2', 'q_sbd', 'variable', 'value']]

# Unpivot to original format
unpivot_df = supercoarse_df.set_index(['month2', 'q_sbd', 'variable'])['value'].unstack().reset_index()

# To. csv.
unpivot_df.to_csv("ffill_imputation.csv", sep=',', index=False)

