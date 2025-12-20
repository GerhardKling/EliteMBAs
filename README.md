# EliteMBAs
The repository provides codes and sample data used in the paper 'Elite MBAs in the Making of Top Business Careers'.

# README FILE
## 1. Compiling the merged dataset from raw data
### 1.1 Open "Data_import.do" (Stata do file)
### 1.2 (Line 25) Change the path to the folder with raw data (see point 1.3)
### 1.3 The folder "Import" contains all csv files (raw data) for merging
>>> RUN Data_import.do
>>> OUTPUT FINAL_DATA.dta
### 1.4 Open "Data_import_v3.do" (Stata do file)
### 1.5 (Line 12) Change the path to the folder with raw data (see point 1.3)
>>> RUN Data_import_v3.do
>>> OUTPUT FINAL_DATA_v2a.dta

## 2. Data analysis
### 2.1 Open "Data analysis v11 REP.do" (Stata do file)
### 2.2 (Line 8) Change the path to the folder with FINAL_DATA_v2.dta (the "Import" folder)
### 2.3 (Line 103) Change the path to the folder "Bloomberg"
### 2.4 (Line 163) Change the path to the folder "Import"
### 2.5 (Line 190) To determine the survival time in boards, we developed a Python script (see folder "Python")

3. Python script
The Python script calculates survival times. These are needed to construct the time dimension.
See point 2.5 for further details.
