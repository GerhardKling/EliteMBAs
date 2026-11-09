********************************************************************************
*IMPORT DATA
********************************************************************************
*IND_DETAIL data merged into IND_DATA.dta
*IND_EDU data merged into IND_EDU_DATA.dta
**IND_DATA.dta and EDU_DATA.dta merged into IND_MERGED.dta
*IND_EMPLOYMENT into IND_EMPLOYMENT.dta
***IND_MERGED.dta and IND_EMPLOYMENT.dta merged into IND_EMP_MERGED.dta
*Company data from SP_list to SP_list.dta
*Company data until 2016: FIRM_CRSP_COMPUSTAT to FIRM.dta
**SP_list.dta and FIRM.dta merged into ALL_FIRM.dta

*Hence, we obtain the IND_EMP_MERGED.dta which is an Individual-career panel
*And the ALL_FIRM.dta which is a firm-year panel

*NOTE: there are two time dimensions START and END dates for positions
*Idea: merge twice: (1) matching start time, (2) matching end time
*For continued positions, use current value of firm variable
*Firm data from 1999 to 2016 - extended with data from Bloomberg

*>>>>>> DATA MERGED INTO: FINAL_DATA.dta

*Change directory
cd "C:\Users\s01gk9\Documents\Aberdeen\US_elites\Resubmission\Zip file\Import"
clear

*************************************************
*INDIVIDUAL DETAILS DATA
*************************************************
global var "A B C D E F G H I J K L M N O"
foreach y of global var {

clear
insheet using IND_DETAIL_`y'.csv

*Variables and labels
drop directorvisible

label var directorname "Full name of director"
rename directorname NAME
label var forename1 "Forename, director"
rename forename1 FORENAME
label var surname "Surname, director"
rename surname LASTNAME
label var age "Age in years, director"
rename age AGE

tostring dod, replace
gen ALIVE=1 if dod==""
replace ALIVE=0 if ALIVE==. 
label var ALIVE "Dummy is one if director is alive, director"

drop dob dod

gen FEMALE=1 if gender=="F"
replace FEMALE=0 if FEMALE==.
label var FEMALE "Dummy is one for female, director"

drop gender 

gen AMERICAN=1 if nationality=="American"
replace AMERICAN=0 if AMERICAN==.
label var AMERICAN "Dummy is one for American, director"

gen BRITISH=1 if nationality=="British"
replace BRITISH=0 if BRITISH==.   
label var BRITISH "Dummy is one for British, director"

rename nationality NATION
label var NATION "Nationality, director"

rename directorid ID
label var ID "Director ID"

rename networksize NETSIZE
label var NETSIZE "Size of network, director"

save IND_DETAIL_`y'.dta, replace

}

*>>>>>>>>>>>>>> Merge individual data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
use IND_DETAIL_A.dta, clear

global var "B C D E F G H I J K L M N O"
foreach y of global var {
	append using IND_DETAIL_`y'
	}
	
*>>>>>>>>>>>>>> Save individual data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
save IND_DATA.dta, replace
*>>>>>>>>>>>>>> Save individual data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	

	
*************************************************
*INDIVIDUAL EDUCATION DATA
*************************************************	
global var "A B C D E F G H I J K L M N O"
foreach y of global var {

clear
insheet using IND_EDU_`y'.csv

drop fulltextdescription

label var directorname "Full name of director"
rename directorname NAME

label var companyname "Name of university, education"
rename companyname UNI

label var companyid "University identifier, education"
rename companyid UNI_ID

label var qualification "Type of qualification, education"
rename qualification QAL

rename directorid ID
label var ID "Director ID"

gen AWARD_YEAR=int(awarddate/10000)
label var AWARD_YEAR "Year of qualification, education"

drop awarddate

save IND_EDU_`y'.dta, replace
}

*>>>>>>>>>>>>>> Merge individual data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
use IND_EDU_A.dta, clear

global var "B C D E F G H I J K L M N O"
foreach y of global var {
	append using IND_EDU_`y'
	}
	
*>>>>>>>>>>>>>> Save individual data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
save IND_EDU_DATA.dta, replace
*>>>>>>>>>>>>>> Save individual data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	


*>>>>>>>>>>>> COMBINING INDIVIDUAL DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*ISSUES
**One individual can have several qualifications
**Classification: BSc, MSc or PhD

use IND_EDU_DATA.dta, clear
sort ID AWARD_YEAR
by ID: gen QUAL_NUM=_n
label var QUAL_NUM "Order of qualification starting with first degree, education"
by ID: egen QUAL_COUNT=count(ID)
label var QUAL_COUNT "Total number of qualifications, education"

*Undergraduate
gen BBA=1 if QAL=="BBA"
replace BBA=1 if QAL=="BSBA"
replace BBA=0 if BBA==.
label var BBA "Bachelor of Business Administration, education"
gen BSc=1 if QAL=="BS"
replace BSc=1 if QAL=="BS (Hons)"
replace BSc=1 if QAL=="BSc"
replace BSc=1 if QAL=="BSEE"
replace BSc=1 if QAL=="BE"
replace BSc=1 if QAL=="BS (magna Cum Laude)"
replace BSc=0 if BSc==.
label var BSc "Bachelor of Science, education"
gen BA=1 if QAL=="BA"
replace BA=1 if QAL=="BA (Hons)"
replace BA=1 if QAL=="AB"
replace BA=1 if QAL=="BA (magna cum laude)"
replace BA=1 if QAL=="BA (Cum Laude)"
replace BA=0 if BA==.
label var BA "Bachelor of Arts, education"

*Masters
gen MSc=1 if QAL=="MS"
replace MSc=0 if MSc==.
label var MSc "Master of Science, education"
gen MA=1 if QAL=="MA"
replace MA=0 if MA==.
label var MA "Master of Arts, education"
gen MBA=1 if QAL=="MBA"
replace MBA=1 if QAL=="Executive MBA"
replace MBA=0 if MBA==.
label var MBA "Master of Business Administration, education"

*Doctorate
gen JD=1 if QAL=="JD"
replace JD=1 if QAL=="JD (Cum Laude)"
replace JD=0 if JD==.
label var JD "Doctoral degree in law, education"
gen PhD=1 if QAL=="PhD"
replace PhD=0 if PhD==.
label var PhD "Doctoral degree, education"
gen MD=1 if QAL=="MD"
replace MD=0 if MD==.
label var MD "Doctoral of Medicine, education"

*Professional qualifications
gen ACCOUNT=1 if QAL=="Certified Public Accountant"
replace ACCOUNT=1 if QAL=="CPA"
replace ACCOUNT=1 if QAL=="Chartered Accountant"
replace ACCOUNT=0 if ACCOUNT==.
label var ACCOUNT "Certified public accountant, education"
gen CFA=1 if QAL=="Chartered Financial Analyst"
replace CFA=0 if CFA==.
label var CFA "Chartered Financial Analyst, education"

*Other or general categories
gen O_BACHELOR=1 if QAL=="Bachelor's Degree"
replace O_BACHELOR=1 if QAL=="Diploma"
replace O_BACHELOR=1 if QAL=="Graduated"
replace O_BACHELOR=1 if QAL=="Attended"
replace O_BACHELOR=1 if QAL=="Studied"
replace O_BACHELOR=1 if QAL=="Degree"
replace O_BACHELOR=0 if O_BACHELOR==.
label var O_BACHELOR "Other Bachelor degree, education"

gen O_MASTER=1 if QAL=="Masters Degree"
replace O_MASTER=0 if O_MASTER==.
label var O_MASTER "Other Masters degree, education"

*>>>>>>>>>>>> MORE WORK NEEDED TO CLASSIFY <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
tabulate QAL, sort
*Up to Diploma
*>>>>>>>>>>>> MORE WORK NEEDED TO CLASSIFY <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*>>>>>>>>>>>> DEGREE CLASSIFICATION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Focus on four degree classes
gen UG=1 if BBA==1 | BSc==1 | BA==1 | O_BACHELOR==1
replace UG=0 if UG==.
label var UG "Undergraduate degree class, education"

gen PG=1 if MA==1 | MSc==1 | MBA==1 | O_MASTER==1
replace PG=0 if PG==.
label var PG "Postgraduate degree class, education"

gen DOCTOR=1 if JD==1 | PhD==1 | MD==1 
replace DOCTOR=0 if DOCTOR==.
label var DOCTOR "Doctorate degree class, education"

gen PROF=1 if ACCOUNT==1 | CFA==1 
replace PROF=0 if PROF==.
label var PROF "Professional degree class, education"

*Drop cases with no qualification
drop if QAL==""

*Unclassified degrees
gen OTHER_EDU=1 if UG==0 & PG==0 & DOCTOR==0 & PROF==0
replace OTHER_EDU=0 if OTHER_EDU==.
label var OTHER_EDU "Unclassified degrees, education"
*>>>>>>>>>>>> DEGREE CLASSIFICATION <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


*>>>>>>>>>>>> ONE INDIVIDUAL IN ONE ROW <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Focus on first three qualifications
*Subsequent qualifications tend to be certificates
drop if QUAL_NUM>3

*One row for each individual
*Shifting second and third qualification to same row as first
global var "UNI QAL UNI_ID AWARD_YEAR BBA BSc BA MSc MA MBA JD PhD MD ACCOUNT CFA O_BACHELOR O_MASTER UG PG DOCTOR PROF OTHER_EDU"
foreach y of global var {
	sort ID QUAL_NUM
	by ID: gen `y'_2=`y'[_n+1] if QUAL_NUM==1
	by ID: gen `y'_3=`y'[_n+2] if QUAL_NUM==1
	}
global var "UNI_ID AWARD_YEAR BBA BSc BA MSc MA MBA JD PhD MD ACCOUNT CFA O_BACHELOR O_MASTER UG PG DOCTOR PROF OTHER_EDU"
foreach y of global var {	
	replace `y'_2=0 if `y'_2==.
	replace `y'_3=0 if `y'_3==.	
	}
*Drop lines
drop if QUAL_NUM!=1
drop QUAL_NUM
*>>>>>>>>>>>> ONE INDIVIDUAL IN ONE ROW <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*>>>>>>>>>>>>>> SAVE MODIFIED EDUCATION DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sort ID
save IND_EDU_DATA.dta, replace
*>>>>>>>>>>>>>> SAVE MODIFIED EDUCATION DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*>>>>>>>>>>>>>> MERGE INDIVIDUAL DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
use IND_DATA.dta, clear
sort ID
merge ID using IND_EDU_DATA.dta
drop _merge

*>>>>>>>>>>>>>> SAVE COMBINED DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Combines all IND_EDU and IND_DETAIL datasets
sort ID
save IND_MERGED.dta, replace
*>>>>>>>>>>>>>> SAVE COMBINED DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<




*>>>>>>>>>>>>>> EMPLOYMENT RECORDS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Link between individual data and firm data
*Data converted from Excel file: Individual_employment_BX.xlsx
*IND_EMPLOYMENT.csv

clear
insheet using IND_EMPLOYMENT.csv

*Director name is the same as in other datasets
label var directorname "Full name of director"
rename directorname NAME

*Company name refers to employer and not education
label var companyname "Name of employer, company"
rename companyname COMP_NAME

*The variable brdposition has four categories - differs from BoardEx data description
gen OUTSIDE=1 if brdposition=="Outside"
replace OUTSIDE=0 if OUTSIDE==.
label var OUTSIDE "Dummy for outside / independent director, employment"

gen INSIDE=1 if brdposition=="Inside"
replace INSIDE=0 if INSIDE==.
label var INSIDE "Dummy for insider as director, employment"

gen BOARD=1 if brdposition=="Yes" | brdposition=="Outside" | brdposition=="Inside"
replace BOARD=0 if BOARD==.
label var BOARD "Dummy whether individual has board position, employment"

drop brdposition 

*>>>>>>>>>> WORK NEEDED<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Type of role in company
*There are more than 6000 roles
*ISSUE: CEO not always clearly labelled
*Focus on three most important positions: CEO, CFO and COO
gen CEO =  strpos(lower(rolename), "ceo") > 0
label var CEO "CEO position, employment"

qui: tabulate rolename if CEO==1, sort

gen CFO =  strpos(lower(rolename), "cfo") > 0
label var CFO "CFO position, employment"
 
qui: tabulate rolename if CFO==1, sort

gen COO =  strpos(lower(rolename), "coo") > 0
label var COO "COO position, employment"
 
qui: tabulate rolename if COO==1, sort

*Note: some individuals have multiple positions
qui: tabulate rolename if COO==1 & CFO==1, sort
*Keep rolename 
rename rolename ROLENAME
label var ROLENAME "Name of position, employment"

*>>>>>>>>>> WORK NEEDED<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Limited information in full text description 
drop fulltextdescription 

gen NED=1 if ned=="Yes"
replace NED=0 if NED==.
label var NED "Non-executive director"
drop ned

*Identifier to match individual records
rename directorid ID
label var ID "Director ID"

*FRIST: Company identifiers for matching samples
label var isin  "Company identifier ISIN code, company"
rename isin ISIN

*SECOND: Company identifiers for matching samples
label var companyid  "Company ID, company"
rename companyid COMP_ID

*THIRD: Company identifiers for matching samples
label var ticker  "Company identifier ticker symbol, company"
rename ticker TICKER

*Almost all US
drop hocountryname 

*Industry dummies
tabulate sector, gen(INDUSTRY)
drop sector

*Industry: numeric measure
gen SECTOR=.
forvalues i=1/42 {
	replace SECTOR=`i' if INDUSTRY`i'==1
	}
label var SECTOR "Industry indicator, numeric, company"	
	

*All companies are quoted
drop orgtype 

*Start and end dates of position
gen C=datestartrole if datestartrole!="N"
destring C, replace

gen START=int(C/10000)
drop C datestartrole 
label var START "Year position started, employment"

gen C=dateendrole if dateendrole!="N" & dateendrole!="C"
destring C, replace

gen END=int(C/10000)
replace END=2019 if dateendrole=="C"
label var END "Year position ended, labelled 2019 if continued, employment"
drop C dateendrole 

*Duplicates in data
*Observations before dropping duplicates
sum ID
duplicates drop ID COMP_ID START END ROLENAME, force
*478623 observations deleted

*Drop if start or end date are unknonw
*29319 observations deleted
drop if START==.
drop if END==.

*Create career trajectories
*DISCUSS: data structure refers to individuals and their career trajectories
*Panel data structure: with director ID and POS_NUM
*Matching based on start and end dates
sort ID START
by ID: gen POS_NUM=_n
by ID: egen POS_COUNT=count(ID)
label var POS_NUM "Order of position, starting with first start date, employment"
label var POS_COUNT "Total number of positions, employment"

*Tenure in position
gen TENURE=END-START
label var TENURE "Tenure in position in years, employment"

*Industry experience
*Any change of industry sets the clock back 
sort ID POS_NUM
by ID: gen IND_TENURE=sum(TENURE) if SECTOR==SECTOR[_n-1]
by ID: replace IND_TENURE=TENURE if SECTOR!=SECTOR[_n-1] & IND_TENURE==.
label var IND_TENURE "Industry experience in years, employment"

*Only worked in one position
replace IND_TENURE=TENURE if POS_NUM==1 & POS_COUNT==1 & IND_TENURE==.

*>>>>>>>>>>>>>> SAVE EMPLOYMENT RECORDS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sort ID
save IND_EMPLOYMENT.dta, replace
*>>>>>>>>>>>>>> SAVE EMPLOYMENT RECORDS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



*>>>>>>>>>>>>>> MERGE EMPLOYMENT RECORDS AND INDIVIDUAL DATA <<<<<<<<<<<<<<<<<<<
use IND_EMPLOYMENT.dta, clear
sort ID

merge ID using IND_MERGED.dta
drop _merge

*Remove individuals without employment records
drop if POS_NUM==.
*17473 observations deleted

sort ID POS_NUM

*Age refers to current age in 2018
*Derive age at the start of position
gen AGE_START=AGE+START-2018
label var AGE_START "Age at start of position, employment"

*Change order
order ID POS_NUM NAME COMP_NAME ROLENAME COMP_ID ISIN TICKER OUTSIDE INSIDE BOARD NED CEO CFO COO AGE AGE_START

*>>>>>>>>>>>>>> SAVE MERGED RECORDS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sort ID POS_NUM
save IND_EMP_MERGED.dta, replace
*>>>>>>>>>>>>>> SAVE MERGED RECORDS <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



*>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> COMPANY DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Thus far, we merged IND_DETAIL, IND_EDU and Individual_employment_BX

*>>>>>>>>>>>>> S&P 500 list <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
clear
insheet using SP_list.csv

*Company name refers to employer and not education
label var companyname "Name of employer, company"
rename companyname COMP_NAME

*Company identifiers for matching samples
label var companyticker  "Company identifier ticker symbol, company"
rename companyticker TICKER

*Company identifiers for matching samples
label var globalcompanykeyindexconstituent  "Company identifier global company key index constituent, company"
rename globalcompanykeyindexconstituent GLOBAL_KEY

*Company identifiers for matching samples
label var companycusip  "Company identifier CUSIP, company"
rename companycusip CUSIP

*Dummy for S&P500 company
gen SP_500=1
label var SP_500 "Company is constituent of the S&P500, company"

*Industry classification
label var companysiccode  "Industry classification SIC, company"
rename companysiccode SIC_CODE

*Industry classification
label var companynaicscode  "Industry classification NAICS, company"
rename companynaicscode NAICS_CODE

*Year company entered S&P 500 index
gen ENTER_SP=int(effectivefromdate/10000)
label var ENTER_SP "Year company entered S&P 500 index, company"

*Year company left S&P 500 index
gen LEAVE_SP=int(effectivethrudate/10000)
replace LEAVE_SP=2019 if LEAVE_SP==.
label var LEAVE_SP "Year company left S&P 500 index, if not left set 2019, company"

drop effectivefromdate effectivethrudate

*>>>>>>>>>>>>>>>>>>>> SAVE S&P LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Match by ticker symbol
sort TICKER
save SP_list.dta, replace
*>>>>>>>>>>>>>>>>>>>> SAVE S&P LIST <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


*>>>>>>>>>>>>> FIRM_CRSP_COMPUSTAT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Construct firm-year panel
*Based on financial statements
*CHECK: ticker uses tickersymbol and not companyticker

clear
insheet using FIRM_CRSP_COMPUSTAT.csv

drop industryformat levelofconsolidationcompanyannua populationsource dataformat isocurrencycode

*Panel of firm-years
drop datadate
label var datayearfiscal  "Year of financial statement, firm-year"
rename datayearfiscal YEAR

*Company identifiers for matching samples
label var standardandpoorsidentifier  "Company identifier S&P identifier, company"
rename standardandpoorsidentifier SP_KEY

*Company name refers to employer and not education
label var companyname "Name of employer, company"
rename companyname COMP_NAME

*Company identifiers for matching samples
label var tickersymbol "Company identifier ticker symbol, company"
rename tickersymbol TICKER

*Whether company is active
gen ACTIVE=1 if activeinactivestatusmarker=="A"
replace ACTIVE=0 if ACTIVE==.
label var ACTIVE "Dummy is one if company is active, company"
drop activeinactivestatusmarker

*Accounting measures
rename assetstotal TA
label var TA "Total assets in USD million, company"

rename earningsbeforeinterest EBI
label var EBI "Earnings before interest in USD million, company"

rename salesturnovernet REV
label var REV "Net turnover, revenue in USD million, company"

rename stockholdersequityparent EQUITY 
label var EQUITY "Total equity in USD million, company"

rename marketvaluetotalfiscal MV
label var MV "Market value of equity in USD million, company"

*Derived performance measures
gen TURN=REV/TA
label var TURN "Turnover ratio defined as sales to total assets, company"

gen ROA=EBI/TA
label var ROA "Return on assets defined as earnings before interest to total assets, company"

gen MB=MV/EQUITY if EQUITY>0
replace MB=0 if EQUITY<0
label var MB "Market-to-book ratio defined as market value of equity to book value of equity, company"

gen DISTRESS=1 if EQUITY<0
replace DISTRESS=0 if DISTRESS==.
label var DISTRESS "Dummy to indicate companies in default, company"

gen LEV=(TA-EQUITY)/EQUITY if EQUITY>0
replace LEV=0 if EQUITY<0
label var LEV "Financial leverage defined as debt relative to equity, company" 

*>>>>>>>>>>>>>>>>>>>> SAVE FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Match by ticker symbol
sort TICKER
save FIRM.dta, replace
*>>>>>>>>>>>>>>>>>>>> SAVE FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


*>>>>>>>>>>>>>>>>>>>> MERGE FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Merge S&P list data and firm-year panel data
*Start with larger panel data as S&P list variables are constant over time

use FIRM.dta, clear

merge TICKER using SP_list.dta
drop _merge

*>>>>>>>>>>>>>>>>>>>> SAVE ALL FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sort TICKER YEAR
save ALL_FIRM.dta, replace
*>>>>>>>>>>>>>>>>>>>> SAVE ALL FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<



*>>>>>>>>>>>>>>>>>>>> COMBINE INDIVIDUAL AND FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<
*>>>>>>>>>>>>>>>>>>>> FIRST MERGER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

use IND_EMP_MERGED.dta, clear

*Merge START date with year
*Consider boundary condition
gen YEAR=START if START>=1999 & START<=2016
replace YEAR=2016 if START>2016
replace YEAR=1999 if START<1999

*Sort data
sort TICKER YEAR

merge TICKER YEAR using ALL_FIRM.dta

*Sort for checking consistency of data
sort ID POS_NUM

drop YEAR _merge

*>>>>>>>>>>>>>>>>>>>> SAVE AFTER MERGE WITH START <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
save IND_EMP_MERGED.dta, replace
*>>>>>>>>>>>>>>>>>>>> SAVE AFTER MERGE WITH START <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


*>>>>>>>>>>>>>>>>>>>> CHANGE VARIABLES IN FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Change variable names in ALL_FIRM.dta for second match
*Set of variables that could change

use ALL_FIRM.dta, clear

global var "TA EBI REV EQUITY MV ACTIVE TURN ROA MB DISTRESS LEV"
foreach y of global var {
	rename `y' `y'_END
	}

*>>>>>>>>>>>>>>>>>>>> SAVE RENAMED VARIABLES <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sort TICKER YEAR
save ALL_FIRM.dta, replace
*>>>>>>>>>>>>>>>>>>>> SAVE AFTER MERGE WITH START <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	


*>>>>>>>>>>>>>>>>>>>> COMBINE INDIVIDUAL AND FIRM DATA <<<<<<<<<<<<<<<<<<<<<<<<<
*>>>>>>>>>>>>>>>>>>>> SECOND MERGER <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Firm data from 1999 to 2016
*Career data from 1955 to 2018

use IND_EMP_MERGED.dta, clear

*Merge END date with year
*Consider boundary condition
gen YEAR=END if END>=1999 & END<=2016
replace YEAR=2016 if END>2016
replace YEAR=1999 if END<1999

*Sort data
sort TICKER YEAR

merge TICKER YEAR using ALL_FIRM.dta

*Sort for checking consistency of data
sort ID POS_NUM

drop YEAR _merge

*>>>>>>>>>>>>>>>>>>>> SAVE FINAL DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
sort ID POS_NUM
save FINAL_DATA.dta, replace
*>>>>>>>>>>>>>>>>>>>> SAVE FINAL DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


*>>>>>>>>>> COMPENSATION DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*>>>>>>>>>> Compensation data <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*Import Org_Summary_BX.csv
clear
insheet using Org_Summary_BX.csv

*Check and adjust variables
drop rowtype

*Identifier
*Several records for directors - not unique
rename directorid ID
label var ID "Director ID"

*Generate year variable from annual report date
gen REM = mod(annualreportdate, 10000)
gen YEAR = (annualreportdate - REM)/10000
label var YEAR "Year of annual report; compensation data"
drop REM annualreportdate

*Time in post, company and other companies
rename timeretirement TIME_RETIRE
label var TIME_RETIRE "Time to retirement"
rename timerole TIME_ROLE
label var TIME_ROLE "Time in role; similar to TENURE"
rename timebrd TIME_BOARD
label var TIME_BOARD "Time on board"
rename timeinco TIME_COMP 
label var TIME_COMP "Time in company" 
rename avgtimeothco TIME_OTHER
label var TIME_OTHER "Average time in other companies"

*Boards
rename totnolstdbrd BOARD_LIST
label var BOARD_LIST "Memberships of boards (listed companies) past/current"
rename totnounlstdbrd BOARD_UNLIST
label var BOARD_UNLIST "Memberships of boards (unlisted companies) past/current"
rename totnoothlstdbrd BOARD_OTHER
label var BOARD_OTHER "Memberships of boards (other) past/current"
rename totcurrnolstdbrd BOARD_LIST_C
label var BOARD_LIST_C "Memberships of boards (listed companies) current"
rename totcurrnounlstdbrd BOARD_UNLIST_C
label var BOARD_UNLIST_C "Memberships of boards (unlisted companies) current"
rename totcurrnoothlstdbrd BOARD_OTHER_C
label var BOARD_OTHER_C "Memberships of boards (other) current"

*Compensation data
rename salary SALARY 
label var SALARY "Base salary"
rename bonus BONUS
label var BONUS "Bonus payment"
rename other COMPENSATION_OTHER
label var COMPENSATION_OTHER "Other compensation"
rename totalcompensation COMPENSATION_TOTAL
label var COMPENSATION_TOTAL "Total compensation"

*Equity compensation
rename valtoteqheld VALUE_EQUITY
label var VALUE_EQUITY "Value of total equity held"
rename valltipheld VALUE_INCENTIVE
label var VALUE_INCENTIVE "Value of long-term incentive plans"
rename intvaloptheld VALUE_INTRINSIC
label var VALUE_INTRINSIC "Intrinsic value of options held,"
rename estvaloptheld VALUE_EQUITY_EST
label var VALUE_EQUITY_EST "Estimated value of options held"
rename toteqlinkedwlth VALUE_EQUITY_TOTAL
label var VALUE_EQUITY_TOTAL "Value of total equity linked compensation held"

*Company identifiers
label var ticker  "Company identifier ticker symbol, company"
rename ticker TICKER

*Board composition
rename genderratio BOARD_GENDER
label var BOARD_GENDER "Gender ratio on board"
rename nationalitymix BOARD_NATION
label var BOARD_NATION "Mix of nationalities"
rename numberdirectors BOARD_DIRECTORS
label var BOARD_DIRECTORS "Number of directors on board"

*Remove redundant variables
*See QUAL_COUNT for noquals (number of qualifications)
*See NETSIZE for networksize
drop boardname directorname noquals succession attrition networksize


*Match based on START and END time of role
*rolename
*Sort based on ID and YEAR
sort ID rolename YEAR
by ID rolename: gen n = _n

*Generate START year
gen START = YEAR if n==1
label var START "Year position started, employment"

*Generate END year
sort ID rolename YEAR
by ID rolename: egen MAX = max(TIME_ROLE)
gen END = YEAR if MAX == TIME_ROLE
label var END "Year position ended, labelled 2019 if continued, employment"

*Drop auxiliary variables
drop MAX

*Comvert data to START and END variables
global var "SALARY BONUS COMPENSATION_OTHER COMPENSATION_TOTAL VALUE_EQUITY VALUE_INCENTIVE VALUE_INTRINSIC VALUE_EQUITY_EST VALUE_EQUITY_TOTAL BOARD_GENDER BOARD_NATION BOARD_DIRECTORS"
foreach y of global var {
	gen FINAL = `y' if END!=.
	sort ID rolename YEAR
	by ID rolename:	egen MAX = max(FINAL)
	gen `y'_END = MAX
	drop MAX FINAL
	}

*Move END
sort ID rolename YEAR
by ID rolename:	egen MAX = max(END)
replace END = MAX
drop MAX

*Remove all n>2 observations
drop if n!=1

*Drop auxiliary variables
drop n rolename

*Generate position number
*Possible that position number does not match FINAL_DATA.dta due to missing data on salaries
*Better to match using START date or maybe TICKER
sort ID START
by ID: gen POS_NUM=_n
label var POS_NUM "Order of position, starting with first start date, employment"

*Drop position number
drop POS_NUM TICKER

*Save data for merging
*Use START to check whether post matches
sort ID START
save Org_Summary_BX.dta, replace


*>>>>>>>>>>>>>>>>>>>> UPDATE FINAL DATA <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
use FINAL_DATA.dta, clear
sort ID START

merge ID START using Org_Summary_BX.dta

*Save data: small matched sample
save FINAL_DATA_WITH_COMPENSATION.dta, replace


*>>>>>>>>>> EXPORT DATA TO PYTHON <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
use FINAL_DATA.dta, clear
sort ID START

*Obtain data as csv file (use in Python)
outsheet using FINAL_DATA.csv, comma replace
