set more off

capture log close
set logtype text
log using FinalProj_merge_logoutput.log, replace

/* --------------------------------------

AUTHOR: Radhika Purandare, Nancy Le


PURPOSE: Replicate Daw and Sommers - 
Association of the Affordable Care Act Dependent Coverage Provision With Prenatal Care Use and Birth Outcomes - Merging Data

DATE CREATED: November 23, 2023
UPDATED: December 2, 2023

--------------------------------------- */

************************************************************
**   Bring in, merge, and clean the data
************************************************************

use src/natl2009.dta, clear

* merge years of data
foreach file in 2011 2012 2013 {
		display "Using CDC natality `file' file"
		append using src/natl`file'.dta 
}

//not including 2010 as dependent coverage not mandated until September 23, 2010; considered a "washout period". 2011-2013 as post-policy period



*generating sif_ymonth on natality dataset to use as key for merge

gen sif_ymonth = ym(dob_yy, dob_mm)
format sif_ymonth %tm

save dta/appendedntl.dta, replace
clear


*import unemployment data
import delimited using src/UNRATE.csv, clear 


*generating sif_ymonth on unemployment dataset to use as key for merge
gen sif_date = date(date, "YMD")
format sif_date %td

gen sif_ymonth = mofd(sif_date)
format sif_ymonth %tm


save dta/unemployment.dta, replace

*merge unemployment data onto natality data
use dta/appendedntl.dta, replace
merge m:1 sif_ymonth using dta/unemployment.dta

// remove data based on the 1989 revision of the US Standard Birth Certificate (not revised with 2003 certificate), and remove irrelevant ages

drop if revision=="S" | mager < 24 | mager > 28 | mager == 26 

*data check
tabulate revision, missing // check that there are no missing values and that there is only "A" revision values
tabulate mager, missing // check no missing values and only relevant age bands



save dta/ntl-unemp.dta, replace
