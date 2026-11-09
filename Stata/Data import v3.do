*************************************************
*IMPORT DATA v3 (second part)
*************************************************
*Version v3
**Start with FINAL_DATA.dta >>> outputs FINAL_DATA_v2a.dta
**Classification of MBAs
**M7 Super-elite MBA Programs (the self-selecting super-elite)
**US Elite MBA Programs (top 25)
**Global Elite MBA Programs (top 50)

*Change directory
cd "C:\Users\s01gk9\Documents\Aberdeen\US_elites\Resubmission\Zip file\Import"

use FINAL_DATA.dta, clear

*>>>>>>>>>>>>>>>>>>>>>>> MBA as second or third qualification <<<<<<<<<<<=======
sum MBA*

*MBAs are common as a second qualification

rename MBA MBA_1
label var MBA_1 "MBA, first qualification"
label var MBA_2 "MBA, second qualification"
label var MBA_3 "MBA, third qualification"

gen MBA=1 if MBA_1==1 | MBA_2==1 | MBA_3==1
replace MBA=0 if MBA==.
label var MBA "Master of Business Administration, education"
sum MBA


*>>>>>>>>>>>>>>>>>>>>>>> M7 Super-elite MBA Programs <<<<<<<<<<<===============================================================================================================
local super_elite_list `""University of Pennsylvania" "Harvard Business School" "Stanford" "Columbia Business School" "University of Chicago" "MIT" "Northwestern University""'

/*
Harvard Business School (FT rank 2)
Columbia Business School (FT rank 4)
Wharton School, University of Pennsylvania (FT rank 1)
Booth School of Business, University of Chicago (FT rank 5)
Sloan School of Management, Massachusetts Institute of Technology (FT rank 6)
Stanford University Graduate School of Business (FT rank 3)
Kellogg School of Management, Northwestern University (FT rank 8)
*/

gen SUPER_ELITE = .
label var SUPER_ELITE "M7 Super-elite MBA Programs (the self-selecting super-elite)"

foreach x of local super_elite_list {
	qui: replace SUPER_ELITE=1 if SUPER_ELITE==. & regexm(UNI, "`x'")==1 & MBA_1==1
	qui: replace SUPER_ELITE=1 if SUPER_ELITE==. & regexm(UNI_2, "`x'")==1 & MBA_2==1
	*Check for second qualifications
	display "`x'"
	count if regexm(UNI_2,"`x'")==1
	qui: replace SUPER_ELITE=1 if SUPER_ELITE==. & regexm(UNI_3, "`x'")==1 & MBA_3==1
}
qui: replace SUPER_ELITE=0 if SUPER_ELITE==.


*>>>>>>>>>>>>>>>>>>>>>>> US Elite MBA Programs (top 25) <<<<<<<<<<<============================================================================================================
local us_elite_list `""University of Pennsylvania" "Harvard Business School" "Stanford" "Columbia Business School" "University of Chicago" "MIT" "Yale School of Management" "Northwestern University" "Dartmouth College" "New York University" "University of California Berkeley" "Duke University" "University of Michigan" "Cornell University" "UCLA" "University of Virginia" "Georgetown University" "Carnegie Mellon" "University of North Carolina" "Emory University" "University of Maryland" "University of Texas at Austin" "Rice University" "University of Southern California" "Vanderbilt University""'

/*
University of Pennsylvania: Wharton
Harvard Business School
Stanford Graduate School of Business
Columbia Business School
University of Chicago: Booth
MIT: Sloan
Yale School of Management
Northwestern University, Kellogg School of Management
Dartmouth College: Tuck
New York University: Stern
University of California at Berkeley: Haas
Duke University's Fuqua School of Business
University of Michigan: Ross
Cornell University: Johnson
UCLA Anderson School of Management
University of Virginia: Darden
Georgetown University: McDonough
Carnegie Mellon: Tepper
University of North Carolina: Kenan-Flagler
Emory University: Goizueta
University of Maryland: Smith
University of Texas at Austin: McCombs
Rice University: Jones
University of Southern California: Marshall
Vanderbilt University: Owen
*/

gen US_ELITE = .
label var US_ELITE "US Elite MBA Programs (top 25)"

foreach x of local us_elite_list {
	qui: replace US_ELITE=1 if US_ELITE==. & regexm(UNI, "`x'")==1 & MBA_1==1
	qui: replace US_ELITE=1 if US_ELITE==. & regexm(UNI_2, "`x'")==1 & MBA_2==1
	*Check for second qualifications
	display "`x'"
	count if regexm(UNI_2,"`x'")==1
	qui: replace US_ELITE=1 if US_ELITE==. & regexm(UNI_3, "`x'")==1 & MBA_3==1
}
qui: replace US_ELITE=0 if US_ELITE==.



*>>>>>>>>>>>>>>>>>>>>>>> Global Elite MBA Programs (top 50) <<<<<<<<<<<========================================================================================================
local global_elite_list `""University of Pennsylvania" "Harvard Business School" "Stanford" "Columbia Business School" "University of Chicago" "MIT" "Yale School of Management" "Northwestern University" "Dartmouth College" "New York University" "University of California Berkeley" "Duke University" "University of Michigan" "Cornell University" "UCLA" "University of Virginia" "Georgetown University" "Carnegie Mellon" "University of North Carolina" "Emory University" "University of Maryland" "University of Texas at Austin" "Rice University" "University of Southern California" "Vanderbilt University" "London Business School" "INSEAD" "IESE" "IMD" "IE Business School" "University of Oxford" "University of Cambridge" "CEIBS" "HEC" "HKUST" "Esade" "Bocconi" "Manchester" "Rotterdam" "Warwick" "Imperial College" "University of Toronto" "Indian School of Business" "City University London" "Cranfield" "Nanyang Business School" "University of Rochester" "National University of Singapore" "Washington University" "Indiana University""'



/*
University of Pennsylvania: Wharton
Harvard Business School
Stanford Graduate School of Business
London Business School
INSEAD
Columbia Business School
University of Chicago: Booth
MIT: Sloan
IESE Business School
Yale School of Management
Northwestern University, Kellogg School of Management
Dartmouth College: Tuck
New York University: Stern
IMD Business School
University of California at Berkeley: Haas
Duke University's Fuqua School of Business
IE Business School
University of Michigan: Ross
University of Oxford: Said
University of Cambridge: Judge
Cornell University: Johnson
UCLA Anderson School of Management
University of Virginia: Darden
CEIBS
HEC Paris
HKUST Business School
Esade Business School
SDA Bocconi School of Management
Georgetown University: McDonough
Carnegie Mellon: Tepper
Alliance Manchester Business School
Rotterdam School of Management, Erasmus University
University of North Carolina: Kenan-Flagler
Emory University: Goizueta
Warwick Business School
University of Maryland: Smith
University of Texas at Austin: McCombs
Rice University: Jones
Imperial College Business School
University of Toronto: Rotman
Indian School of Business
City University London: Bayes (ex Cass)
University of Southern California: Marshall
Cranfield School of Management
Vanderbilt University: Owen
Nanyang Business School, NTU Singapore
University of Rochester: Simon Business School
National University of Singapore Business School
Washington University: Olin
Indiana University: Kelley
*/

gen GLOBAL_ELITE = .
label var GLOBAL_ELITE "Global Elite MBA Programs (top 50)"

foreach x of local global_elite_list {
	qui: replace GLOBAL_ELITE=1 if GLOBAL_ELITE==. & regexm(UNI, "`x'")==1 & MBA_1==1
	qui: replace GLOBAL_ELITE=1 if GLOBAL_ELITE==. & regexm(UNI_2, "`x'")==1 & MBA_2==1
	*Check for second qualifications
	display "`x'"
	count if regexm(UNI_2,"`x'")==1
	qui: replace GLOBAL_ELITE=1 if GLOBAL_ELITE==. & regexm(UNI_3, "`x'")==1 & MBA_3==1
}
qui: replace GLOBAL_ELITE=0 if GLOBAL_ELITE==.




*>>>>>>>>>>>>>>>>>>>>>>> Save data <<<<<<<<<<<==================================
*Sample overview
sum SUPER_ELITE US_ELITE GLOBAL_ELITE if MBA==1



*Version 2 final dataset
save FINAL_DATA_v2a.dta, replace
















