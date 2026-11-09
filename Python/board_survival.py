"""
Determines board survival time
"""

import pandas as pd

#Load data from STATA
file = 'SURVIVAL_DATA.dta'

#Convert STATA dta to Pandas DataFrame
df = pd.read_stata(file)

#Work with sub-sample for trial
#Comment out later
# df = df[:100]

#Sort DataFrame
df = df[['ID', 'YEAR', 'BOARD', 'SP_500']]
df = df.sort_values(by=['ID', 'YEAR'])

#Define condition based on board membership in S&P500 firm
df.loc[(df['BOARD'] == 1) & (df['SP_500'] == 1), 'CON'] = 1  

#Set missing values for condition to zero
df.loc[df['CON'].isnull(), 'CON'] = 0

#Identifies duplicate years due to multiple positions with 0
df['YEAR_CHANGE'] = df['YEAR'] - df['YEAR'].shift(1)

#Change value to 1 if moving between individuals
df.loc[df['ID'] != df['ID'].shift(1), 'YEAR_CHANGE'] = 1 

#Remove duplicate values
df.loc[df['YEAR_CHANGE'] == 0, 'CON'] = 0

#Determine board survival time
df['BOARD_SURVIVAL'] = df.groupby('ID')['CON'].cumsum()
    
#Sort DataFrame and focus on new variable
df = df[['ID', 'YEAR', 'BOARD_SURVIVAL']]
df = df.sort_values(by=['ID', 'YEAR'])    
    
#Save as STATA file
df.to_stata('BOARD_SURVIVAL.dta')     
    
    
    