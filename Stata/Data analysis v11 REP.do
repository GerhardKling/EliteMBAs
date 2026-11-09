********************************************************************************
*DATA ANALYSIS
********************************************************************************
*Version v11
**Replication of data analyses

*Change directory
cd "C:\Users\s01gk9\Documents\Aberdeen\US_elites\Resubmission\Zip file\Import"

*Open merged dataset
use FINAL_DATA_v2.dta, clear

*==============================================================================*
*DATA MANAGEMENT
*==============================================================================*

********************************************************************************
*MOVING TO CEO POSITION
********************************************************************************
sort ID POS_NUM
by ID: egen WAS_CFO = max(CFO)
by ID: egen WAS_COO = max(COO)
by ID: egen WAS_NED = max(NED)
by ID: egen WAS_CEO = max(CEO)

label var WAS_CFO "Was a CFO at least once in career"
label var WAS_COO "Was a COO at least once in career"
label var WAS_NED "Was a NED at least once in career"
label var WAS_CEO "Was a CEO at least once in career"

********************************************************************************
*OBSERVATIONS WITHOUT ID
********************************************************************************
*Note remove data with no ID
drop if ID == .

*===============>>>>>>>>>>>>>>> CHANGE TO DISCRETE SURVIVAL DATA <<<<<<<<<<<<<==
*Check data structure: TABLE 1
br ID POS_NUM NAME AGE AGE_START TENURE START END

*Expand data based on TENURE + 1
gen TENURE_PLUS_ONE = TENURE + 1
expand TENURE_PLUS_ONE

*Define survival time in position
*Note our structure is based on different positions; thus, survival time restarts in new position
bysort ID POS_NUM AGE_START: gen SURVIVAL = _n 
label var SURVIVAL "Survival time in position"

*Create EXIT variable to label the end in a position
bysort ID POS_NUM AGE_START: gen EXIT = 1 if _n==_N
replace EXIT = 0 if EXIT == .
label var EXIT "Exit point using the label 0 for being in a position and 1 for the time of exit"

*Change EXIT in 2019 if person remains in position: is ALIVE or moves to other post
bysort ID: egen MAX_POS_NUM = max(POS_NUM)
label var MAX_POS_NUM "Maximum number of posts; determine whether CEO remains in 2019"

*Adjust EXIT
bysort ID POS_NUM AGE_START: replace EXIT = 0 if END == 2019 & POS_NUM == MAX_POS_NUM & ALIVE == 1

*Modify AGE to reflect age at the time and not current (2019) age
*We use AGE_START and SURVIVAL to construct current age
rename AGE AGE_2019 
label var AGE_2019 "Last age of person recorded in the database; usually 2019 if alive"

gen AGE = AGE_START + SURVIVAL - 1
label var AGE "Age of individual; at time t"

*Re-check data structure
*NOTE: tset the data is not needed for discrete time models as in our case
br ID POS_NUM MAX_POS_NUM NAME AGE AGE_START TENURE START END SURVIVAL EXIT ALIVE AGE AGE_START if ID == 356

*Construct YEAR variable linked to survival in position
*It refers to the START year and survival time
*ID 514715: START is wrong: not 2010 but 2000
replace START = 2000 if ID == 514715
*ID 770591: START is wrong: not 2006 but 2004 for position 2
replace START = 2004 if ID == 770591 & POS_NUM == 2
*ID 861871: START is wrong: not 2009 but 2002 for position 2
replace START = 2002 if ID == 861871 & POS_NUM == 2
*ID 1145202: START is wrong: not 2012 but 2004
replace START = 2004 if ID == 1145202

gen YEAR = START + SURVIVAL - 1
label var YEAR "Constructed from START year in posiiton and survival time; needed to match with firm data"

*Check the data structure
br NAME COMP_NAME REV START END YEAR SURVIVAL AGE

*************SAVE FOR ANALYSIS**************************************************
save SURVIVAL_DATA.dta, replace



*===============>>>>>>>>>>>>>>> ADJUST FIRM DATA <<<<<<<<<<<<<==================
*We use Bloomberg to cover the whole period until 2020
*Compustat is limited to 2016
*We also need to match based on YEAR constructed from SURVIVAL time
*Convert Bloomberg tickers back using replace new = subinstr(new, "  US Equity", "", .)

*Change directory: Bloomberg
cd "C:\Users\s01gk9\Documents\Aberdeen\US_elites\Resubmission\Zip file\Bloomberg"

*===========* Import all firm-level variables from Bloomberg *=================*
global var "TA EBIT REV TE MV ROIC ROE ROA MTB"
foreach y of global var {
	*import csv file
	insheet using `y'.csv, clear

	*Count data and expand
	gen count = _n
	expand 22
	sort count
	by count: gen YEAR = 1998 + _n
	drop count

	gen VAR = v2 if YEAR == 1999

	forvalues i = 3/23 {
		replace VAR = v`i' if YEAR == 1997 + `i'
		}

	*TICKER identifier
	rename v1 TICKER

	*Sort
	sort TICKER YEAR

	*Change variable name
	rename VAR `y'
	

	*Drop variables
	drop v*

	*Save data
	save `y'.dta, replace
	}
  
*===========* Merge firm-level variables from Bloomberg      *=================*  
use TA.dta, clear

global var "EBIT REV TE MV ROIC ROE ROA MTB"
foreach y of global var {
	merge TICKER YEAR using `y'.dta
	drop _merge
	sort TICKER YEAR
	}
  
*Label variables  
label var TA "Total assets in USD million, company"
label var EBIT "Earnings before interest and taxes in USD million, company"
label var REV "Revenues in USD million, company"
label var TE "Total common equity in USD million, company"
label var MV "Market value of common equity in USD million, company"
label var ROIC "Return on invested capital, company"
label var ROE "Return on common equity, company"
label var ROA "Return on total assets, company"
label var MTB "Market-to-book ratio, company"

*Save merged data and move to Import folder
cd "C:\Users\s01gk9\Documents\Aberdeen\US_elites\Resubmission\Zip file\Import"

sort TICKER YEAR
save BLOOMBERG.dta, replace

*Merge with survival data
use SURVIVAL_DATA.dta, clear

*Remove Compustat variables
drop TA EBI REV EQUITY MV TURN ROA MB LEV ///
TA_END EBI_END REV_END EQUITY_END MV_END TURN_END ROA_END MB_END LEV_END

*Merge
sort TICKER YEAR

merge TICKER YEAR using BLOOMBERG.dta
drop _merge

*Sort based on individuals
sort ID POS_NUM AGE_START

*Drop observations with no individual data
drop if ID==.

*Save merged data
save SURVIVAL_DATA.dta, replace

*==============>>>>>>>>>>>>>>> FIXING BOARD SURVIVAL TIME <<<<<<<<<<<<<=========
*To determine the survival time in boards, we developed a Python script
*There are too many challenges in Stata to address duplicates due to multiple positions

use BOARD_SURVIVAL.dta, clear

sort ID YEAR

save BOARD_SURVIVAL.dta, replace

use SURVIVAL_DATA.dta, clear
sort ID YEAR

merge ID YEAR using BOARD_SURVIVAL.dta

*Label
label var BOARD_SURVIVAL "Survival time in boardroom"
drop _merge index

*Sort by ID and YEAR
sort ID YEAR

*Save merged data
save SURVIVAL_DATA.dta, replace

*Drop observation with no individual data
drop if ID == .


*==========>>>>>>>>>>>> INTERIM DATA SAVE  <<<<<<<<<<<<<========================
save INTERIM.dta, replace

*==========>>>>>>>>>>>> INTERIM DATA SAVE  <<<<<<<<<<<<<========================


*===============>>>>>>>>>>>>>>> TECH versus BANKING <<<<<<<<<<<<<===============
use INTERIM.dta, clear

*Defining banking & financial services
gen BANKING = INDUSTRY3
label var BANKING "Financial industry, narrow definition"

gen BANKING_b = INDUSTRY3 + INDUSTRY36
label var BANKING_b "Financial industry including Speciality & Other Finance, broader definition"

*Defining the tech industry
gen TECH = INDUSTRY22 + INDUSTRY35 
label var TECH "Core tech industry including Information Technology Hardware and Software & Computer Services, narrow definition"

gen TECH_b = TECH + INDUSTRY27 
label var TECH_b "Non-core tech including Media & Entertainment, broader definition"

gen TECH_bb = TECH_b + INDUSTRY30
label var TECH_bb "Non-core tech including Pharmaceuticals and Biotechnology, broader definition"

save INTERIM.dta, replace



*==================>>>>>>>>>>>>>>>>> INDUSTRY COMPARISON <<<<<<<<<<<============
*Compared number of companies over time
*NOTE: data on individuals - double counting of companies
*Panel A: Individuals
*All firms in the sample
tabstat BANKING BANKING_b TECH TECH_b TECH_bb if YEAR >= 1998, by(YEAR) s(sum)

*Panel B: Companies
sort COMP_ID YEAR
duplicates drop COMP_ID YEAR, force

*All firms in the sample
tabstat BANKING BANKING_b TECH TECH_b TECH_bb if YEAR >= 1998, by(YEAR) s(sum)

tabstat REV EBIT if BANKING == 1 & YEAR >= 1998, by(YEAR) s(median)
tabstat REV EBIT if TECH == 1 & YEAR >= 1998, by(YEAR) s(median)

tabstat REV EBIT if BANKING == 1 & YEAR >= 1998, by(YEAR) s(sum)
tabstat REV EBIT if TECH == 1 & YEAR >= 1998, by(YEAR) s(sum)

*==================>>>>>>>>>>>>>>>>> INDUSTRY COMPARISON <<<<<<<<<<<============
*Restore dataset



use INTERIM.dta, clear

*==================>>>>>>>>>>>>>>>>> CAREER FOUNDATION <<<<<<<<<<<==============
*LAW
list ROLENAME if strpos(ROLENAME, "legal")
*The search tern "legal" gives: Paralegal
*The search term "Legal" covers most roles

gen legal_titles = ROLENAME if strpos(ROLENAME, "Legal") | strpos(ROLENAME, "Attorney") | strpos(ROLENAME, "Law")
tabulate legal_titles, sort
drop legal_titles

gen LAW = 1 if strpos(ROLENAME, "Legal") | strpos(ROLENAME, "legal") | strpos(ROLENAME, "Attorney") | strpos(ROLENAME, "Law")
replace LAW = 0 if LAW==.
label var LAW "Law expert, career foundation"


preserve

collapse (mean) LAW, by(YEAR) 
drop if YEAR < 1977
line LAW YEAR, xtitle("Year") ytitle("Share of legal experts")

restore


*FIN
*Note: careful with Account Manager
gen fin_titles = ROLENAME if strpos(ROLENAME, "Finance") | strpos(ROLENAME, "CFO") ///
| strpos(ROLENAME, "Control") | strpos(ROLENAME, "Accounting") | strpos(ROLENAME, "Accountant")
tabulate fin_titles, sort
drop fin_titles

gen FIN = 1 if strpos(ROLENAME, "Finance") | strpos(ROLENAME, "CFO") ///
| strpos(ROLENAME, "Control") | strpos(ROLENAME, "Accounting") | strpos(ROLENAME, "Accountant")
replace FIN = 0 if FIN == .
label var FIN "Finance expert, career foundation"

preserve

collapse (mean) FIN, by(YEAR) 
drop if YEAR < 1977
line FIN YEAR, xtitle("Year") ytitle("Share of finance experts")

restore


*TECH
*Note: Technology, IT experts

list ROLENAME if strpos(ROLENAME, "Net")


gen TECH_F = 1 if strpos(ROLENAME, "IT") | strpos(ROLENAME, "Soft") | strpos(ROLENAME, "Hard") ///
| strpos(ROLENAME, "Tech")
replace TECH_F = 0 if TECH_F == .
label var TECH_F "Tech, career foundation"


*==================>>>>>>>>>>>>>>>>> CAREER FOUNDATION <<<<<<<<<<<==============




/*

*==================>>>>>>>>>>>>>>>>> CHANGING THE GUARD <<<<<<<<<<<=============
*Boardroom survival
tabstat BOARD_SURVIVAL if TECH ==1 & YEAR >= 1998, by(YEAR)
tabstat BOARD_SURVIVAL if BANKING ==1 & YEAR >= 1998, by(YEAR)

*Demographics of the elite
sum POS_COUNT TENURE IND_TENURE NETSIZE FEMALE AMERICAN QUAL_COUNT ///
if TECH ==1 & YEAR >= 1998 & BOARD == 1 

sum POS_COUNT TENURE IND_TENURE NETSIZE FEMALE AMERICAN QUAL_COUNT ///
if BANKING ==1 & YEAR >= 1998 & BOARD == 1
*==================>>>>>>>>>>>>>>>>> CHANGING THE GUARD <<<<<<<<<<<=============

*/


/*
*==================>>>>>>>>>>>>>>>>> MBA <<<<<<<<<<<============================
*>>>>>>>>>>>>>>>>> The rise of MBAs <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
preserve

collapse (mean) MBA, by(YEAR) 
drop if YEAR < 1977
line MBA YEAR, xtitle("Year") ytitle("Share of MBAs")

restore

*>>>>>>>>>>>>>>>>> MBAs and CEOs <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
**singinficantly more MBAs among CEOs
**Tier 1 MBAs are more dominant among top executives
tabulate WAS_CEO MBA, row chi2
tabulate WAS_CEO SUPER_ELITE, row chi2

*Share of MBAs among CEOs
preserve

collapse (mean) MBA if WAS_CEO==1, by(YEAR) 
drop if YEAR < 1977
line MBA YEAR, xtitle("Year") ytitle("Share of MBAs among CEOs")

restore

*Share of Tier 1 MBAs among CEOs
preserve

collapse (mean) SUPER_ELITE if WAS_CEO==1, by(YEAR) 
drop if YEAR < 1977
line SUPER_ELITE YEAR, xtitle("Year") ytitle("Share of Tier 1 MBAs among CEOs")

restore

*>>>>>>>>>>>>>>>>> Becoming a CEO: Logit models <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
qui: {
*MBA effect
logit WAS_CEO MBA
estimates store A
*Career foundations
logit WAS_CEO MBA TECH LAW FIN
estimates store B
*Controls: individual
logit WAS_CEO MBA TECH LAW FIN AGE IND_TENURE FEMALE AMERICAN QUAL_COUNT
estimates store C
*Controls: Networks
logit WAS_CEO MBA TECH LAW FIN AGE IND_TENURE FEMALE AMERICAN QUAL_COUNT NETSIZE BOARD POS_COUNT
estimates store D
}

estimates table A B C D, star b(%9.3f) stats(N aic bic)



*/

********************************************************************************
*Analysis Version 8: MBA paper
********************************************************************************
*Restore dataset
use INTERIM.dta, clear

*===============================================================================
*REFINED DEFINITIONS OF TOP MANAGEMENT ROLES (START)
*===============================================================================
*From version v7

*==========>>>>>>>>>>>> REFINE DEFINITION CEO <<<<<<<<<<<<<=====================
*CEO: refine definitions
tabulate ROLENAME if CEO==1, sort 

*Step 1: Remove Regional CEOs
gen REG_CEO =  strpos(lower(ROLENAME), "regional ceo") > 0 & CEO==1
label var REG_CEO "Regional CEO position, employment"
qui: tabulate ROLENAME if REG_CEO==1, sort
replace CEO=0 if REG_CEO==1

*Step 2: Remove Co-CEOs
gen CO_CEO =  strpos(lower(ROLENAME), "co-ceo") > 0 & CEO==1
label var CO_CEO "Co-CEO position, employment"
qui: tabulate ROLENAME if CO_CEO==1, sort
replace CEO=0 if CO_CEO==1

*Step 3: Remove Deputy CEOs
gen DEP_CEO =  strpos(lower(ROLENAME), "deputy ceo") > 0 & CEO==1
label var DEP_CEO "Deputy CEO position, employment"
qui: tabulate ROLENAME if DEP_CEO==1, sort
replace CEO=0 if DEP_CEO==1

*Step 4: Remove Interim CEOs
gen INT_CEO =  strpos(lower(ROLENAME), "interim ceo") > 0 & CEO==1
label var INT_CEO "Interim CEO position, employment"
qui: tabulate ROLENAME if INT_CEO==1, sort
replace CEO=0 if INT_CEO==1

*Step 5: Remove Acting CEOs
gen ACT_CEO =  strpos(lower(ROLENAME), "acting ceo") > 0 & CEO==1
label var ACT_CEO "Acting CEO position, employment"
qui: tabulate ROLENAME if ACT_CEO==1, sort
replace CEO=0 if ACT_CEO==1

*CEO: refined definitions after removing five types
tabulate ROLENAME if CEO==1, sort 


*==========>>>>>>>>>>>> REFINE DEFINITION CFO <<<<<<<<<<<<<=====================
*CFO: refine definitions
tabulate ROLENAME if CFO==1, sort 

*Step 1: Remove Regional CFOs
gen REG_CFO =  strpos(lower(ROLENAME), "regional cfo") > 0 & CFO==1
label var REG_CFO "Regional CFO position, employment"
qui: tabulate ROLENAME if REG_CFO==1, sort
replace CFO=0 if REG_CFO==1

*Step 2: Remove Interim CFOs
gen INT_CFO =  strpos(lower(ROLENAME), "interim cfo") > 0 & CFO==1
label var INT_CFO "Interim CFO position, employment"
qui: tabulate ROLENAME if INT_CFO==1, sort
replace CFO=0 if INT_CFO==1

*Step 3: Remove Acting CFOs
gen ACT_CFO =  strpos(lower(ROLENAME), "acting cfo") > 0 & CFO==1
label var ACT_CFO "Acting CFO position, employment"
qui: tabulate ROLENAME if ACT_CFO==1, sort
replace CFO=0 if ACT_CFO==1

*Step 4: Remove Deputy CFOs
gen DEP_CFO =  strpos(lower(ROLENAME), "deputy cfo") > 0 & CFO==1
label var DEP_CFO "Deputy CFO position, employment"
qui: tabulate ROLENAME if DEP_CFO==1, sort
replace CFO=0 if DEP_CFO==1

*Step 5: Remove Assistant CFOs
gen ASS_CFO =  strpos(lower(ROLENAME), "assistant cfo") > 0 & CFO==1
label var ASS_CFO "Assistant CFO position, employment"
qui: tabulate ROLENAME if ASS_CFO==1, sort
replace CFO=0 if ASS_CFO==1

*CFO: refined definitions after removing five types
tabulate ROLENAME if CFO==1, sort 


*==========>>>>>>>>>>>> REFINE DEFINITION COO <<<<<<<<<<<<<=====================
*COO: refine definitions
tabulate ROLENAME if COO==1, sort 

*Step 1: Remove Coordinator (Coordination)
gen COR_COO =  strpos(lower(ROLENAME), "coordinat") > 0 & COO==1
label var COR_COO "Coordinator - NOT COO, employment"
qui: tabulate ROLENAME if COR_COO==1, sort
replace COO=0 if COR_COO==1

*Step 2: Remove Regional COOs
gen REG_COO =  strpos(lower(ROLENAME), "regional coo") > 0 & COO==1
label var REG_COO "Regional COO, employment"
qui: tabulate ROLENAME if REG_COO==1, sort
replace COO=0 if REG_COO==1

*Step 3: Remove Co-COOs
gen CO_COO =  strpos(lower(ROLENAME), "co-coo") > 0 & COO==1
label var CO_COO "Co-COO, employment"
qui: tabulate ROLENAME if CO_COO==1, sort
replace COO=0 if CO_COO==1

*Step 4: Remove Assistant COOs
gen ASS_COO =  strpos(lower(ROLENAME), "assistant coo") > 0 & COO==1
label var ASS_COO "Assistant COO, employment"
qui: tabulate ROLENAME if ASS_COO==1, sort
replace COO=0 if ASS_COO==1

*Step 5: Remove Acting COOs
gen ACT_COO =  strpos(lower(ROLENAME), "acting coo") > 0 & COO==1
label var ACT_COO "Acting COO, employment"
qui: tabulate ROLENAME if ACT_COO==1, sort
replace COO=0 if ACT_COO==1

*Step 6: Remove Interim COOs
gen INT_COO =  strpos(lower(ROLENAME), "interim coo") > 0 & COO==1
label var INT_COO "Interim COO, employment"
qui: tabulate ROLENAME if INT_COO==1, sort
replace COO=0 if INT_COO==1

*COO: refined definitions after removing six types
tabulate ROLENAME if COO==1, sort 


*==========>>>>>>>>>>>> REFINE DEFINITION CTO <<<<<<<<<<<<<=====================
*Includes Chief Information Officer (CIO)
*CTO definition
**NOTE: smaller group of people
gen CTO =  strpos(ROLENAME, "CTO") > 0 | strpos(lower(ROLENAME), "technology officer") > 0 ///
| strpos(ROLENAME, "CIO") > 0 | strpos(ROLENAME, "chief information officer") > 0
label var CTO "CTO, employment"
tabulate ROLENAME if CTO==1, sort 

*Step 1: Remove Regional CTOs
gen REG_CTO =  strpos(lower(ROLENAME), "regional cto") > 0 & CTO==1
label var REG_CTO "Regional CTO, employment"
qui: tabulate ROLENAME if REG_CTO==1, sort
replace CTO=0 if REG_CTO==1

*CTO: refined definitions after removing one type
tabulate ROLENAME if CTO==1, sort 

*Add most common job titles
replace CTO=1 if strpos(ROLENAME, "Vice President - Research & Development")==1
replace CTO=1 if strpos(ROLENAME, "Director - Research")==1
replace CTO=1 if strpos(ROLENAME, "Vice President - Research")==1
replace CTO=1 if strpos(ROLENAME, "Director - Research/Development")==1
replace CTO=1 if strpos(ROLENAME, "Senior VP - Research & Development")==1
replace CTO=1 if strpos(ROLENAME, "Senior VP - Research")==1
replace CTO=1 if strpos(ROLENAME, "Senior Director - Research & Developm")==1
replace CTO=1 if strpos(ROLENAME, "Head of Research")==1
replace CTO=1 if strpos(ROLENAME, "Executive VP - Research & Development")==1
replace CTO=1 if strpos(ROLENAME, "Vice President - Clinical Research")==1
replace CTO=1 if strpos(ROLENAME, "Research Director ")==1
replace CTO=1 if strpos(ROLENAME, "ED - Research ")==1
replace CTO=1 if strpos(ROLENAME, "Division Senior VP - Research & Devel")==1
replace CTO=1 if strpos(ROLENAME, "Research and Development Director")==1
replace CTO=1 if strpos(ROLENAME, "Head of Research & Development")==1

*CTO: refined definitions after adding job titles
tabulate ROLENAME if CTO==1, sort 

*==========>>>>>>>>>>>> REFINE DEFINITION HR <<<<<<<<<<<<<======================
*Corporate Directors of Human Resources
gen HR =  strpos(lower(ROLENAME), "human resources") > 0
label var HR "Corporate Directors of Human Resources, employment"
tabulate ROLENAME if HR==1, sort 

*Remove lesser roles
replace HR=0 if ROLENAME=="Human Resources Officer"
replace HR=0 if ROLENAME=="Regional Chief Human Resources Officer"
replace HR=0 if ROLENAME=="Human Resources Coordinator"

*==========>>>>>>>>>>>> REFINE DEFINITION CMO <<<<<<<<<<<<<=====================
gen CMO =  strpos(lower(ROLENAME), "cmo") > 0 | strpos(lower(ROLENAME), "chief marketing officer") > 0
label var CMO "Chief Marketing Officers, employment"
tabulate ROLENAME if CMO==1, sort 

*===============================================================================
*REFINED DEFINITIONS OF TOP MANAGEMENT ROLES (END)
*===============================================================================

*==========>>>>>>>>>>>> REFINE DEFINITION MBAs <<<<<<<<<<<<<====================
*It is useful to define the types we want to compare
**Elite MBA is 1, Non-elite MBA is 2, and No MBA is 3
gen MBA_TYPES=1 if SUPER_ELITE==1
replace MBA_TYPES=2 if SUPER_ELITE==0 & US_ELITE==1
replace MBA_TYPES=3 if SUPER_ELITE==0 & US_ELITE==0 & GLOBAL_ELITE==1
replace MBA_TYPES=4 if SUPER_ELITE==0 & US_ELITE==0 & GLOBAL_ELITE==0 & MBA==1
replace MBA_TYPES=5 if MBA==0
label var MBA_TYPES "US super-elite MBA programs is 1, US elite MBA programs is 2, Global elite MBA programs is 3, Other MBA is 4, and no MBA is 5"

*Overview types of MBAs
tabstat MBA, by(MBA_TYPES) s(N)
tabstat MBA if MBA==1, by(MBA_TYPES) s(N) 


*==================>>>>>>>>>>>>>>>>> CAREER FOUNDATION <<<<<<<<<<<==============
*LAW
*list ROLENAME if strpos(ROLENAME, "legal")
*The search tern "legal" gives: Paralegal
*The search term "Legal" covers most roles

gen legal_titles = ROLENAME if strpos(ROLENAME, "Legal") | strpos(ROLENAME, "Attorney") | strpos(ROLENAME, "Law")
*tabulate legal_titles, sort
drop legal_titles

gen LAW = 1 if strpos(ROLENAME, "Legal") | strpos(ROLENAME, "legal") | strpos(ROLENAME, "Attorney") | strpos(ROLENAME, "Law")
replace LAW = 0 if LAW==.
label var LAW "Law expert, career foundation"

*FIN
*Note: careful with Account Manager
gen fin_titles = ROLENAME if strpos(ROLENAME, "Finance") | strpos(ROLENAME, "CFO") ///
| strpos(ROLENAME, "Control") | strpos(ROLENAME, "Accounting") | strpos(ROLENAME, "Accountant")
*tabulate fin_titles, sort
drop fin_titles

gen FIN = 1 if strpos(ROLENAME, "Finance") | strpos(ROLENAME, "CFO") ///
| strpos(ROLENAME, "Control") | strpos(ROLENAME, "Accounting") | strpos(ROLENAME, "Accountant")
replace FIN = 0 if FIN == .
label var FIN "Finance expert, career foundation"

*TECH
*Note: Technology, IT experts
*list ROLENAME if strpos(ROLENAME, "Net")

gen TECH_F = 1 if strpos(ROLENAME, "IT") | strpos(ROLENAME, "Soft") | strpos(ROLENAME, "Hard") ///
| strpos(ROLENAME, "Tech")
replace TECH_F = 0 if TECH_F == .
label var TECH_F "Tech, career foundation"

*==================>>>>>>>>>>>>>>>>> CAREER FOUNDATION <<<<<<<<<<<==============


*==================>>>>>>>>>>>>>>>>> TMT DEFINITION <<<<<<<<<<<=================
*Step 1: Definition of the TMT
**Based on variables capturing CEO, CFO and COO positions
gen TMT=1 if CEO==1 | CFO==1 | COO==1 | CTO==1| HR==1| CMO==1 & SP_500==0
replace TMT=0 if TMT==.
label var TMT "Top Management Team, including CEO, CFO, COO, CTO, HR and CMO positions in a non S&P500 company"

gen TMT_SP=1 if CEO==1 | CFO==1 | COO==1 | CTO==1| HR==1| CMO==1 & SP_500==1
replace TMT_SP=0 if TMT_SP==.
label var TMT_SP "Top Management Team, including CEO, CFO, COO, CTO, HR and CMO positions in S&P500 company"
*==================>>>>>>>>>>>>>>>>> TMT DEFINITION <<<<<<<<<<<=================

*===============================================================================
*UPDATE WAS_CEO AND RELATED VARIABLES (START)
*===============================================================================
/*NOTE: CEO definiton includes S&P500 and other companies, 
whereas TMT splits the sample. I adjust that here*/
gen CEO_SP=CEO if SP_500==1
replace CEO_SP=0 if CEO_SP==.
label var CEO_SP "CEO position at S&P500 company, employment"

replace CEO=0 if CEO_SP==1
label var CEO "CEO position at non-S&P500 company, employment"

/*Revise variables for "was in position"*/
drop WAS_CEO WAS_CFO WAS_COO WAS_NED
sort ID POS_NUM
by ID: egen WAS_CFO = max(CFO)
by ID: egen WAS_COO = max(COO)
by ID: egen WAS_NED = max(NED)
by ID: egen WAS_CEO = max(CEO)
by ID: egen WAS_TMT = max(TMT)
by ID: egen WAS_CEO_SP = max(CEO_SP) 
by ID: egen WAS_TMT_SP = max(TMT_SP)

label var WAS_CFO "Was a CFO at least once in career"
label var WAS_COO "Was a COO at least once in career"
label var WAS_NED "Was a NED at least once in career"
label var WAS_CEO "Was a CEO at least once in career"
label var WAS_TMT "Was a member of the TMT at least once in career"
label var WAS_CEO_SP "Was a CEO at least once in career at S&P500 company"
label var WAS_TMT_SP "Was a member of the TMT at least once in career at S&P500 company"
*===============================================================================
*UPDATE WAS_CEO AND RELATED VARIABLES (END)
*===============================================================================


*==================>>>>>>>>>>>>>>>>> FOREIGN <<<<<<<<<<<========================
gen FOREIGN=1 if AMERICAN==0 & NATION!=""
replace FOREIGN=0 if FOREIGN==.
label var FOREIGN "Foreign national if known"
*==================>>>>>>>>>>>>>>>>> FOREIGN <<<<<<<<<<<========================


*===============================================================================
*VARIABLES RELATED TO TIMING (START)
*===============================================================================
*>>> Determine award year for MBAs
**Starts with first qualifocation and moves to second and third
gen MBA_YEAR=AWARD_YEAR if MBA_1==1
replace MBA_YEAR=AWARD_YEAR_2 if MBA_2==1 & MBA_YEAR==.
replace MBA_YEAR=AWARD_YEAR_3 if MBA_3==1 & MBA_YEAR==.
replace MBA_YEAR=. if MBA_YEAR==0
label var MBA_YEAR "Year of graduation from MBA programme."

*>>> First post after graduation
sort ID POS_NUM YEAR
*Checking the first position in its first year
gen FIRST_POST=1 if START>=MBA_YEAR & POS_NUM==1 
*Generate a blocker for directors
bysort ID: egen BLOCKER=max(FIRST_POST)
sort ID POS_NUM YEAR

*Checking subsequent positions: only flagged if previous position was not flagged
*replace FIRST_POST=1 if START>=MBA_YEAR & FIRST_POST[_n-1]!=1 & ID==ID[_n-1]
replace FIRST_POST=1 if START>=MBA_YEAR & BLOCKER!=1

*Replace missing values
replace FIRST_POST=0 if FIRST_POST==.

*Remove BLOCKER
drop BLOCKER

*Label
label var FIRST_POST "First position after completing an MBA"

*>>> The years to the top
**When did the individual enter the database?
sort ID POS_NUM YEAR
gen YEAR_ENTER=START if POS_NUM==1
bysort ID: egen MAX=max(YEAR_ENTER)
replace YEAR_ENTER=MAX
drop MAX

sort ID POS_NUM YEAR
label var YEAR_ENTER "The year the individual entered the database"

/*We determine the first time the individual joined the top management team of 
any company (FIRST_YEAR_TMT) or S&P 500 companies (FIRST_YEAR_TMT_SP).*/
gen FIRST_YEAR_TMT=START if TMT==1
bysort ID: egen MIN=min(FIRST_YEAR_TMT)
replace FIRST_YEAR_TMT=MIN
drop MIN

sort ID POS_NUM YEAR
label var FIRST_YEAR_TMT "The year the individual entered the TMT of a non S&P500 company"

gen FIRST_YEAR_TMT_SP=START if TMT_SP==1
bysort ID: egen MIN=min(FIRST_YEAR_TMT_SP)
replace FIRST_YEAR_TMT_SP=MIN
drop MIN

sort ID POS_NUM YEAR
label var FIRST_YEAR_TMT_SP "The year the individual entered the TMT of an S&P500 company"

**Finally, we determine YEARS_TO_TMT and YEARS_TO_TMT_SP 
gen YEARS_TO_TMT=FIRST_YEAR_TMT-YEAR_ENTER
label var YEARS_TO_TMT "Years taken to join the TMT of a non S&P500 company since entering the database"

gen YEARS_TO_TMT_SP=FIRST_YEAR_TMT_SP-YEAR_ENTER
label var YEARS_TO_TMT_SP "Years taken to join the TMT of an S&P500 company since entering the database"

*>>> First position is CEO
gen CEO_FIRST=FIRST_POST*CEO
label var CEO_FIRST "First post after MBA is a CEO position at non S&P500 company"

gen CEO_FIRST_SP=FIRST_POST*CEO_SP
label var CEO_FIRST_SP "First post after MBA is a CEO position at S&P500 company"

/*We determine the first time the individual became the CEO of an S&P 500 
company (FIRST_YEAR_CEO).*/

gen FIRST_YEAR_CEO=START if CEO==1 
bysort ID: egen MIN=min(FIRST_YEAR_CEO)
replace FIRST_YEAR_CEO=MIN
drop MIN

sort ID POS_NUM YEAR
label var FIRST_YEAR_CEO "The year the individual became the CEO of a non-S&P 500 company"

gen FIRST_YEAR_CEO_SP=START if CEO_SP==1 
bysort ID: egen MIN=min(FIRST_YEAR_CEO_SP)
replace FIRST_YEAR_CEO_SP=MIN
drop MIN

sort ID POS_NUM YEAR
label var FIRST_YEAR_CEO_SP "The year the individual became the CEO of S&P 500 company"

/*We determine the time it took to reach the first CEO position, 
comparing FIRST_YEAR_CEO with YEAR_ENTER*/
gen YEARS_TO_CEO_SP=FIRST_YEAR_CEO_SP-YEAR_ENTER 
label var YEARS_TO_CEO_SP "Years taken to became the CEO of an S&P 500 company since entering the database"

gen YEARS_TO_CEO=FIRST_YEAR_CEO-YEAR_ENTER 
label var YEARS_TO_CEO_SP "Years taken to became the CEO of a non-S&P 500 company since entering the database"

/*Compare FIRST_YEAR_CEO_SP with FIRST_YEAR_TMT_SP*/
gen WAITING_TIME_CEO_SP=FIRST_YEAR_CEO_SP-FIRST_YEAR_TMT_SP
label var WAITING_TIME_CEO_SP "Years spent as a non-CEO member of the TMT of an S&P 500 company before appointment as CEO"


*=======================| Career longevity |====================================
*CEO survival time labelled SURVIVAL_CEO 
gen SURVIVAL_CEO=SURVIVAL if CEO==1
label var SURVIVAL_CEO "CEO survival time in years"

*NOTE
/*In the past, we have used a Python script to correct BOARD_SURVIVAL time due 
to boundary conditions. I ignore these issues in this analysis and look at 
SURVIVAL with an if qualifier. This should be sufficient for an initial 
assessment based on means and percentiles.*/

*BOARD survival time labelled SURVIVAL_BOARD
gen SURVIVAL_BOARD=SURVIVAL if BOARD==1
label var SURVIVAL_BOARD "Board survival time in years"

*TMT survival time labelled SURVIVAL_TMT_SP
gen SURVIVAL_TMT_SP=SURVIVAL if TMT_SP==1
label var SURVIVAL_TMT_SP "TMT survival time in years at S&P500 companies"
*=======================| Career longevity |====================================


*===============================================================================
*VARIABLES RELATED TO TIMING (END)
*===============================================================================


*==========>>>>>>>>>>>> INTERIM DATA SAVE  <<<<<<<<<<<<<========================
save INTERIM_v2.dta, replace
*==========>>>>>>>>>>>> INTERIM DATA SAVE  <<<<<<<<<<<<<========================



use INTERIM_v2.dta, clear


*==========>>>>>>>>>>>> DISCUSS SAMPLE  <<<<<<<<<<<<<===========================
*MBAs (all types) in the sample: see conclusion
tabstat MBA

*Number of companies in the sample
codebook COMP_ID if YEAR>=2000 & YEAR<=2018

*Number of individuals
codebook ID if YEAR>=2000 & YEAR<=2018

*Unique roles
codebook ROLENAME if YEAR>=2000 & YEAR<=2018

*Educational records
tabulate QAL


*>>>>>>>>>>>>>>>>>>>>>>> Descriptive Analysis <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
*===========================| MBAs in sample |==================================
/*CEOs or members of TMTs at any company*/
gen WAS_CEO_ANY = 1 if WAS_CEO==1 | WAS_CEO_SP==1
replace WAS_CEO_ANY = 0 if WAS_CEO_ANY==.
label var WAS_CEO_ANY "CEO position at any company, employment"

gen WAS_TMT_ANY = 1 if WAS_TMT==1 | WAS_TMT_SP==1
replace WAS_TMT_ANY = 0 if WAS_TMT_ANY==.
label var WAS_TMT_ANY "Top Management Team, including CEO, CFO, COO, CTO, HR and CMO positions at any company"

*MBAs in whole sample
sum LAW FIN TECH_F MBA if YEAR>=2000 & YEAR<=2018 

*MBAs among former and current CEOs
sum LAW FIN TECH_F MBA if YEAR>=2000 & YEAR<=2018 & WAS_CEO_ANY==1 


*===========================| Figure 1 |========================================
*Whole sample
preserve

collapse (mean) LAW FIN TECH_F MBA, by(YEAR) 
drop if YEAR < 2001

*Show percentages
tabstat LAW FIN TECH_F MBA, by(YEAR) 

*Indexing
gen t=_n
tsset t

global var "LAW FIN TECH_F MBA"
foreach y of global var {
	gen new=100 if t==1
	replace new=l.new*(1+d.`y'/l.`y') if new==.
	drop `y'
	rename new `y'
	}

twoway (line LAW YEAR) (line FIN YEAR) (line TECH_F YEAR) (line MBA YEAR), ///
xtitle("Year") ytitle("Share of experts") ///
legend(label(1 "Law") label(2 "Finance") label(3 "Technology") label(4 "MBA"))

*Save figures
graph export Fig_1_career_foundations.png, as(png) replace

restore


*CEOs
preserve

collapse (mean) LAW FIN TECH_F MBA if WAS_CEO==1, by(YEAR) 
drop if YEAR < 2001

*Show percentages
tabstat LAW FIN TECH_F MBA, by(YEAR) 

*Indexing
gen t=_n
tsset t

global var "LAW FIN TECH_F MBA"
foreach y of global var {
	gen new=100 if t==1
	replace new=l.new*(1+d.`y'/l.`y') if new==.
	drop `y'
	rename new `y'
	}

twoway (line FIN YEAR) (line TECH_F YEAR) (line MBA YEAR), ///
xtitle("Year") ytitle("Share of experts among CEOs") ///
legend(label(1 "Finance") label(2 "Technology") label(3 "MBA"))

*Save figures
graph export Fig_2_career_foundations_ceo.png, as(png) replace

restore
*===========================| Figure 1 |========================================



*===========================| TABLE 1 |=========================================
*Subsample of current and former CEOs
tabstat WAS_CEO_ANY if YEAR>=2000 & YEAR<=2018
tabstat FEMALE if YEAR>=2000 & YEAR<=2018 & WAS_CEO_ANY==1
tabstat FOREIGN if YEAR>=2000 & YEAR<=2018 & WAS_CEO_ANY==1
tabstat SUPER_ELITE US_ELITE GLOBAL_ELITE MBA if YEAR>=2000 & YEAR<=2018 & WAS_CEO_ANY==1

*Subsample of current and former members of the TMT (excluding current and former CEOs)
tabstat WAS_TMT_ANY if YEAR>=2000 & YEAR<=2018 & WAS_CEO_ANY==0
tabstat FEMALE if YEAR>=2000 & YEAR<=2018 & WAS_TMT_ANY==1 & WAS_CEO_ANY==0
tabstat FOREIGN if YEAR>=2000 & YEAR<=2018 & WAS_TMT_ANY==1 & WAS_CEO_ANY==0
tabstat SUPER_ELITE US_ELITE GLOBAL_ELITE MBA if YEAR>=2000 & YEAR<=2018 & WAS_TMT_ANY==1 & WAS_CEO_ANY==0

*Remaining sample
tabstat FEMALE if YEAR>=2000 & YEAR<=2018 & WAS_TMT_ANY==0
tabstat FOREIGN if YEAR>=2000 & YEAR<=2018 & WAS_TMT_ANY==0
tabstat SUPER_ELITE US_ELITE GLOBAL_ELITE MBA if YEAR>=2000 & YEAR<=2018 & WAS_TMT_ANY==0 

*===========================| TABLE 1 |=========================================

*>>>>>>>>>>>>>>>>>>>>>>> Descriptive Analysis <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

*Overlap of MBA categories
replace US_ELITE=0 if SUPER_ELITE==1
replace GLOBAL_ELITE=0 if SUPER_ELITE==1
replace GLOBAL_ELITE=0 if US_ELITE==1

*MBA for remaining MBAs
replace MBA=0 if SUPER_ELITE==1 | US_ELITE==1 | GLOBAL_ELITE==1


*=======================| H1 |==================================================
/*Hypothesis 1: Elite MBA graduates are more likely to be appointed to the TMT 
of an S&P 500 company or one of its main divisions than executives with 
a non-elite MBA or no MBA.*/
*=======================| H1 |==================================================
/*
*Super elite MBA are more common among Americans and Males
gen SUPER_ELITExFEMALE = SUPER_ELITE*FEMALE
gen SUPER_ELITExAMERICAN = SUPER_ELITE*AMERICAN
*/

*===========================| TABLE 2 (H1) |====================================
*Control for year effects
qui: {
*Elite MBA effect
logit WAS_TMT SUPER_ELITE US_ELITE GLOBAL_ELITE MBA 
estimates store A
*Controls: individual
logit WAS_TMT SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store B	
*Elite MBA effect
logit WAS_TMT_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA 
estimates store C
*Controls: individual
logit WAS_TMT_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store D
}

estimates table A B C D, star b(%9.3f) stats(N aic bic)
*===========================| TABLE 2 (H1) |====================================


*=======================| H2 |==================================================
/*Hypothesis 2: Elite MBA graduates are more likely to be appointed CEO of an 
S&P 500 company or one of its main divisions than executives with a non-elite 
MBA or no MBA.*/
*=======================| H2 |==================================================
*Discussion
tabstat WAS_CEO_SP if SUPER_ELITE==1
tabstat WAS_CEO_SP if MBA==1
tabstat WAS_CEO_SP if MBA==0 & SUPER_ELITE==0 & GLOBAL_ELITE==0 & US_ELITE==0

*Selection effect
logit SUPER_ELITE FEMALE AMERICAN

*===========================| TABLE 3 (H2) |====================================
*Control for year effects
qui: {
*Elite MBA effect
logit WAS_CEO SUPER_ELITE US_ELITE GLOBAL_ELITE MBA 
estimates store E
*Controls: individual
logit WAS_CEO SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store F	
*Elite MBA effect
logit WAS_CEO_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA 
estimates store G
*Controls: individual
logit WAS_CEO_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store H
}

estimates table E F G H, star b(%9.3f) stats(N aic bic)
*===========================| TABLE 3 (H2) |====================================


*=======================| H3 |==================================================
/*Hypothesis 3: Elite MBA graduates secure their first appointment to the TMT 
of an S&P 500 company or one of its main divisions earlier than executives with 
a non-elite MBA or no MBA.*/
*=======================| H3 |==================================================

*===========================| TABLE 4 (H3) |====================================
qui: {
reg YEARS_TO_TMT SUPER_ELITE US_ELITE GLOBAL_ELITE MBA
estimates store I
reg YEARS_TO_TMT SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store J
reg YEARS_TO_TMT_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA
estimates store K
reg YEARS_TO_TMT_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store L
}

estimates table I J K L, star b(%9.3f) stats(N r2_a)
*===========================| TABLE 4 (H3) |====================================


*=======================| H4 |==================================================
/*Hypothesis 4: Elite MBA graduates secure their first appointment as CEO of 
an S&P 500 company or one of its main divisions earlier than executives 
with a non-elite MBA or no MBA.*/
*=======================| H4 |==================================================


*===========================| TABLE 5 (H4) |====================================
qui: {
reg YEARS_TO_CEO SUPER_ELITE US_ELITE GLOBAL_ELITE MBA
estimates store M
reg YEARS_TO_CEO SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store N
reg YEARS_TO_CEO_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA
estimates store O
reg YEARS_TO_CEO_SP SUPER_ELITE US_ELITE GLOBAL_ELITE MBA AGE IND_TENURE AMERICAN FEMALE QUAL_COUNT DOCTOR
estimates store P
}

estimates table M N O P, star b(%9.3f) stats(N r2_a)
*===========================| TABLE 5 (H4) |====================================



*===========================| DISCUSSION IN PAPER |=============================
codebook ID
/*p14: 106,874 executives included in our sample*/

codebook ID if YEAR==1980
/*p17: Employment records for 1,348 individuals date back to 1980*/

codebook TICKER COMP_NAME COMP_ID
/*p17: Our sample therefore includes 795 companies >>> with company IDs*/

tabulate QAL
/*p18: Our sample includes some 1,084,399 educational records*/

codebook ROLENAME
/*p20: Classifying 6,050 different roles proved time consuming*/

codebook SECTOR
/*North American Industry Classification System codes (NAICS_CODE), 
resulting in a classification of companies into 42 industries*/

*>>>See lines: 880-883: note the change in MBA definition due to overlaps
/*p21: the entire sample exhibits a considerable proportion of MBAs (28.4%), as 
against functional experts in law (0.5%), finance (5.5%), and technology (1.7%). 
Moreover, in the subsample of current and former CEOs, MBAs are especially 
dominant, accounting for 36.7% of all cases, as against 2.8% for those with a 
finance background, and very few technology or legal experts, just 0.2% 
and 0.05% respectively*/

*===========================| DISCUSSION IN PAPER |=============================



*===========================| VARIABLES |=======================================
*Variable names and definitions
**Panel A: Individual Details
des ID NAME FORENAME LASTNAME NATION  AMERICAN BRITISH FEMALE ALIVE AGE

**Panel B: Education
des UNI QAL UNI_ID AWARD_YEAR QUAL_COUNT BBA BSc BA MSc MA JD PhD MD ACCOUNT ///
CFA O_BACHELOR O_MASTER UG PG DOCTOR PROF OTHER_EDU MBA SUPER_ELITE US_ELITE ///
GLOBAL_ELITE

**Panel C: Positions
des YEAR ROLENAME NED CEO CFO COO WAS_CFO WAS_COO WAS_NED WAS_CEO POS_NUM ///
POS_COUNT BOARD INSIDE OUTSIDE TENURE IND_TENURE SURVIVAL BOARD_SURVIVAL ///
NETSIZE

**Panel D: Company
des COMP_NAME COMP_ID ISIN TICKER CUSIP ACTIVE DISTRESS SIC_CODE NAICS_CODE ///
SP_500 ENTER_SP LEAVE_SP TA EBIT REV TE MV ROIC ROE ROA MTB
*===========================| VARIABLES |=======================================




*===============================================================================
*RESUBMISSION: ADDITIONAL ANALYSES
*===============================================================================

*===============================| TRENDS |======================================
*Increase in female leaders
*Increase in international leaders
**Foreign nationals are more likely CEOs than other TMT members
drop if YEAR < 2000 | YEAR > 2018

gen FEMALE_CEO = FEMALE * WAS_CEO
label var FEMALE_CEO "Female that was a CEO in any company"

gen FEMALE_TMT = FEMALE * WAS_TMT
label var FEMALE_TMT "Female that was a TMT member in any company"

tabstat FEMALE, by(YEAR)
tabstat FEMALE_CEO if WAS_CEO==1, by(YEAR)
tabstat FEMALE_TMT if WAS_TMT==1, by(YEAR)

tabstat FEMALE if MBA==1, by(YEAR)
tabstat FEMALE if GLOBAL_ELITE==1, by(YEAR)
tabstat FEMALE if US_ELITE==1, by(YEAR)
tabstat FEMALE if SUPER_ELITE==1, by(YEAR)


gen FOREIGN_CEO = FOREIGN * WAS_CEO
label var FOREIGN_CEO "Foreign national that was a CEO in any company"

gen FOREIGN_TMT = FOREIGN * WAS_TMT
label var FOREIGN_TMT "Foreign national  that was a TMT member in any company"

tabstat FOREIGN, by(YEAR)
tabstat FOREIGN_CEO if WAS_CEO==1, by(YEAR)
tabstat FOREIGN_TMT if WAS_TMT==1, by(YEAR)

sum FOREIGN_CEO if WAS_CEO==1
sum FEMALE_CEO if WAS_CEO==1
/*
`On commencing this study, we had anticipated seeing more evidence of the 
admission into corporate circles of women and non-US nationals, but these 
represent just 6.46% and 4.64% of our CEO pool'.
*/
sum FEMALE_TMT if WAS_TMT==1
/*p26: Amongst the wider TMT membership featured in our sample, female 
representation remains low at 11.54%. */
sum FEMALE_CEO if WAS_CEO==1
sum FEMALE_CEO if WAS_CEO==1 & YEAR==2000
sum FEMALE_CEO if WAS_CEO==1 & YEAR==2018
/*p26: Only a small percentage of our sample (6.46%) is comprised of female 
CEOs, although more positively we witnessed a significant increase in female 
CEOs during our study period from 4.59% in 2000 to 9.59% in 2018.*/ 
sum  FOREIGN_CEO if WAS_CEO==1 & YEAR==2000
sum  FOREIGN_CEO if WAS_CEO==1 & YEAR==2018
/*p30: On commencing this study, we had anticipated seeing more evidence of 
the admission into corporate circles of women and non-US nationals, but these 
represent just 6.46% and 4.64% of our CEO pool. While we did witness an increase 
in the representation of both, by 2018 they comprised just 9.59% and 5.39% of our 
CEO pool respectively (...). Women remain poorly represented within wider TMTs 
at just 11.54%, with female executives' share of global MBAs unchanged over our 
study period.*/

*===============================| TRENDS |======================================


*===============================| PERFORMANCE |=================================
gen CEO_SUPER_ELITE = (CEO==1 & SUPER_ELITE==1)
gen CEO_US_ELITE = (CEO==1 & US_ELITE==1)
gen CEO_GLOBAL_ELITE = (CEO==1 & GLOBAL_ELITE==1)
gen CEO_MBA = (CEO==1 & MBA==1)

gen CEO_MBA_TYPE = 1 if CEO_SUPER_ELITE==1
replace CEO_MBA_TYPE = 2 if CEO_US_ELITE==1
replace CEO_MBA_TYPE = 3 if CEO_GLOBAL_ELITE==1
replace CEO_MBA_TYPE = 4 if CEO_MBA==1
replace CEO_MBA_TYPE = 5 if CEO==1 & MBA==0 & GLOBAL_ELITE==0 & US_ELITE==0 & SUPER_ELITE==0

*Winsorization
global var "ROA ROE ROIC MTB"
foreach y of global var {
	egen p5=pctile(`y'), p(5)
	egen p95=pctile(`y'), p(95)
	replace `y'=p5 if `y'<p5 & `y'!=.
	replace `y'=p95 if `y'>p95 & `y'!=.
	drop p5 p95
	}

tabstat ROA ROE ROIC MTB, by(CEO_MBA_TYPE) s(p25 median p75) 
graph box ROE, noout over(CEO_MBA_TYPE)

*Controls
gen SIZE=ln(TA)
label var SIZE "Log of total assets, firm size"

gen DEBT=TA-TE
label var DEBT "Total debt"

gen LEV=DEBT/TE
label var LEV "Financial leverage, debt to equity ratio"


qui: {
xi: qreg ROE i.CEO_MBA_TYPE SIZE LEV i.YEAR i.SECTOR
estimates store R1
xi: qreg ROA i.CEO_MBA_TYPE SIZE LEV i.YEAR i.SECTOR
estimates store R2
xi: qreg ROIC i.CEO_MBA_TYPE SIZE LEV i.YEAR i.SECTOR
estimates store R3
xi: qreg MTB i.CEO_MBA_TYPE SIZE LEV i.YEAR i.SECTOR
estimates store R4 
	}


estimates table R1 R2 R3 R4, star b(%9.3f) stats(N r2_p) drop(_IYEAR* _ISECTOR*)

*===============================| PERFORMANCE |=================================


*===============================| FORTUNE500 |==================================
*Include Fortune 500 rankings in 2018
sort TICKER
merge TICKER using "Fortune.dta"
drop _merge

*MBAs in TMTs based on Fortune 500 rankings
sum FEMALE FOREIGN SUPER_ELITE US_ELITE GLOBAL_ELITE MBA if WAS_TMT_SP==1 & FORTUNE<=20
sum FEMALE FOREIGN SUPER_ELITE US_ELITE GLOBAL_ELITE MBA if WAS_TMT_SP==1 & FORTUNE>20

*T-tests: comparing means
gen FORTUNE_20 = (FORTUNE<=20)
label var FORTUNE_20 "Companies ranked in the top 20 based on Fortune 500"

*FEMALE significant
ttest FEMALE if WAS_TMT_SP==1, by(FORTUNE_20)
*FOREIGN not significant
ttest FOREIGN if WAS_TMT_SP==1, by(FORTUNE_20)
*SUPER_ELITE not significant
ttest SUPER_ELITE if WAS_TMT_SP==1, by(FORTUNE_20)
*US_ELITE not significant
ttest US_ELITE if WAS_TMT_SP==1, by(FORTUNE_20)
*GLOBAL_ELITE significant
ttest GLOBAL_ELITE if WAS_TMT_SP==1, by(FORTUNE_20)
*MBA not significant
ttest MBA if WAS_TMT_SP==1, by(FORTUNE_20) 

*Additional tables
tabstat FEMALE FOREIGN SUPER_ELITE US_ELITE GLOBAL_ELITE MBA if WAS_TMT_SP==1, ///
by(FORTUNE_20) s(mean)
*===============================| FORTUNE500 |==================================
