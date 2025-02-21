set more off

capture log close
set logtype text
log using FinalProj_d-d_logoutput.log, replace

/* --------------------------------------

AUTHOR: Radhika Purandare, Nancy Le


PURPOSE: Replicate Daw and Sommers - 
Association of the Affordable Care Act Dependent Coverage Provision With Prenatal Care Use and Birth Outcomes - DiDs and t-tests

DATE CREATED: November 23, 2023
UPDATED: December 10, 2023

--------------------------------------- */



************************************************************
**   Bring in cleaned data with constructed variables
************************************************************


use dta/ntl-unemp-const.dta, replace


****************************************************************
****UNADJUSTED DiD for Table 1 (differential change exposure)
****************************************************************



***DIFFERENTIAL CHANGE EXPOSURE MINUS CONTROL; tests for confounding***
foreach variable in mager mar hisp race_cat1 race_cat2 race_cat3 edu_cat1 edu_cat2 edu_cat3 first_lb multiple_deliv fagecomb {
	display "Regressing `variable' outcome variable - unadjusted"
	regress `variable' treat after treatXafter, r 
}



****************************************************************
****UNADJUSTED DIFFERENCES for regression table, by(after)
****************************************************************


//for each loop for unadjusted differences w/ 95% CI, control and exposure groups; this is not the DiD estimates

foreach variable in pay_type1 pay_type2 pay_type3 early_pc adequate_care_v2 csection preterm_v2 lbwt nicu {
	display "T-test `variable' outcome variable - unadjusted"
	display "control group"
	ttest `variable' if treat==0, by(after)
	display "exposure group"
	ttest `variable' if treat==1, by(after)
}


****************************************************************
****DIFFERENCE IN DIFFERENCE (unadjusted and adjusted) for regression table
****************************************************************

*difference-in-differences - unadjusted for covariates

foreach variable in pay_type1 pay_type2 pay_type3 early_pc adequate_care_v2 csection preterm_v2 lbwt nicu {
	display "Regressing `variable' outcome variable - unadjusted"
	regress `variable' treat after treatXafter, r 
}

*difference-in-differences - adjusted for covariates

foreach variable in pay_type1 pay_type2 pay_type3 early_pc adequate_care_v2 csection preterm_v2 lbwt nicu {
	display "Regressing `variable' outcome variable - adjusted"
	regress `variable' treat after treatXafter i.dob_mm mager i.mar i.mracerec i. meduc i. first_lb i. multiple_deliv unrate fagecomb, r 
}

log close
exit
