set more off

capture log close
set logtype text
log using FinalProj_constructv2-5_logoutput.log, replace

/* --------------------------------------

AUTHOR: Radhika Purandare, Nancy Le


PURPOSE: Replicate Daw and Sommers - 
Association of the Affordable Care Act Dependent Coverage Provision With Prenatal Care Use and Birth Outcomes - Constructing Variables - v3 w/ new adjusted expected visits

DATE CREATED: November 23, 2023
UPDATED: December 11, 2023

--------------------------------------- */

************************************************************
**   Bring in cleaned data
************************************************************



use dta/ntl-unemp.dta



************************************************************
**   Constructing primary outcome variables
************************************************************


***********************************************************
* ACCESS TO CARE OUTCOME VARIABLES (early prenatal care and adequate prenatal care)
***********************************************************


*****************************
*1) early prenatal care outcome (first visit in first trimester)
	//first trimester is to the end of the 13th week of pregnancy
	//using precare_rec (month prenatal care began recode) = 1 (1st to 3rd 	month) as first trimester
	//anything above 1 is inadequate care
*****************************


replace precare_rec = . if precare_rec==5 // replace unknowns as missing for prenatal care recoded variable

*1a) early prenatal care but using paper's definition (visit in first 3 months)
gen early_pc = precare_rec==1
replace early_pc = . if precare_rec==.


*1b) early prenatal care but for APCNU index (includes 4th month of pregnancy)
gen early_pc_apcnu = precare >=01 & precare <=04
replace early_pc_apcnu = . if precare == 99


*****************************
*2) adequate prenatal care 
	//(adequate prenatal care = a first trimester visit + 80% of expected visits) ***USING APCNU GUIDELINES FOR EXPECTED VISITS***
*****************************

*****************************
* clean existing variables
*****************************

// # of prenatal visits (uprevis)
replace uprevis = . if uprevis == 99 // replace unknowns as missing for # of prenatal visits recoded variable


// month prenatal care began (precare) // replace unknowns as missing for month prenatal care began
replace precare = . if precare == 99


*****************************
* generate variable for expected # visits
*****************************

***  generate unadjusted expected visits (ev) & adjusted expected visits (unadj_ev) based on APCNU clinical guidelines (monthly prenatal visit starting at 1.5 months for 28 weeks, then )

replace combgest = . if combgest == 99

//generate unadjusted expected visits
generate unadj_ev = 0
replace unadj_ev = (combgest-1)/4 if combgest <=28 
replace unadj_ev = 7 + (combgest - 1 - 28)/2 if combgest >28 & combgest <=36
replace unadj_ev = 11 + (combgest- 1 -36)/1 if combgest > 36
replace unadj_ev = . if combgest==. 
//subtracting an extra 1 from combgest bc they expect 1 for the 0th month



*** expected visits adjusted for month of prenatal care initiation;
gen ev = 0
replace ev = unadj_ev 
replace ev = ((unadj_ev) - 1*(precare) + 1) if precare >=1 
replace ev = unadj_ev - ((precare-7)*(2)) if precare >=8
replace ev = unadj_ev - ((precare - 8)*4) if precare >=9
replace ev = . if unadj_ev == . 
replace ev = unadj_ev if precare == .
//adding an additional one to first adjusted ev bc no expected visit for current month; e.g., 40 week pregnancy w/ prenatal care initiation of month 4 has expected visits==11; adjusted by subtracting 3 visits expected from month 0 to month 3


** generate % of expected visits
gen evpercent = (uprevis/ev)*100

** calculation of adequacy based on index
gen met_ev_80 = evpercent >=80 
//indicator variable, met_ev==1 meaning met 80% of number of expected visits based on gestational age / APCNU index

replace met_ev_80 = . if ev == . | uprevis == . 



*****************************
* generate variable for adequate prenatal care
*****************************

//generate variable for adequate prenatal care; 1 if had a first trimester visit (synonymous with previous early_pc variable)

gen adequate_care = early_pc==1 & met_ev_80 == 1
replace adequate_care = . if met_ev_80 == . | early_pc == . 


//version of adequate care using visit within 4 months; not just 3 months
gen adequate_care_v2 = early_pc_apcnu ==1 & met_ev_80 == 1
replace adequate_care_v2 = . if met_ev_80 == . | early_pc_apcnu == . 


//adequate prenatal care defined as having a visit in first trimester and at least 80% of the expected # of visits based on gestational age and clinical guidelines 



//check if code ends up making sense
order combgest unadj_ev precare ev uprevis evpercent met_ev_80 early_pc adequate_care

browse combgest unadj_ev precare ev uprevis evpercent met_ev_80 early_pc adequate_care


*****************************
*3) payment source of birth is an existing variable in dataset (pay_rec)
*****************************

*****************************
*secondary outcomes: cesarean delivery (me_rout==4), preterm birth (born <37 weeks), low birth weight (dbwt == <2500g), and infant neonatal intensive care unit (NICU) admission (ab_nicu)
*****************************


*****************************
*cesarean delivery outcome
*****************************

replace me_rout = "." if me_rout=="9"
gen csection = me_rout =="4"

*****************************
*premature birth
*****************************
//option 1 *** <37 weeks with recoded variable
replace gestrec3 = . if gestrec3 == 3
gen preterm_v1 = gestrec3==1
replace preterm_v1 = . if gestrec3==.


//option 2 ***<37 weeks with gestation recode; more bands; USING THIS ONE
replace gestrec10 = . if gestrec10 == 99
gen preterm_v2 = gestrec10 <= 05
replace preterm_v2 = . if gestrec10== . 

//option 3 ***TESTING THIS ONE - premature as <34 weeks
gen preterm_v3 = gestrec10 <= 04
replace preterm_v3 = . if gestrec10== . 

//option 4 ****TESTING THIS ONE - setting imputed values to missing w/ <34 wks
gen preterm_v4 = gestrec10 <= 04
replace preterm_v4 = . if gestrec10== . 
replace preterm_v4 = . if gest_imp==1

//option 5 ****TESTING THIS ONE - setting imputed values to missing w/ <37 wks
gen preterm_v5 = gestrec10 <= 05
replace preterm_v5 = . if gestrec10== . 
replace preterm_v5 = . if gest_imp==1



*****************************
*low birth weight
*****************************

gen lbwt = dbwt <=2500

*****************************
*infant NICU admission 
*****************************
replace ab_nicu = "." if ab_nicu=="U"
replace ab_nicu = "1" if ab_nicu=="Y"
replace ab_nicu = "0" if ab_nicu=="N"
gen nicu = ab_nicu == "1"



***********************************************************************
****Diff in Diff *********************************
****Generate DiD variables for Both Tables*************
***********************************************************************

**generate indicator variables for treatment v control and before v after**

gen after=(dob_yy>=2011) // post-variable to reflect "after" ACA dependent coverage provision time period (after 2011)

gen treat = mager <= 25
//generate treatment variable (24-25 y/o women); 0 is control group (27-28 y/o)


*generate interaction term
gen treatXafter = treat*after

***********************************************************************
****Diff in Diff *********************************
****Generate variables for Summary Stats Table*************
***********************************************************************


//replacing American Indian / Alaskan Native and Asian / Pacific Islander as 0 for "Other"

replace mracerec = 0 if mracerec==3 | mracerec==4
tab mracerec, gen(race_cat)

//generate mother hispanic origin indicator variable

replace mracehisp = . if mracehisp == 9
gen hisp = mracehisp >= 1 & mracehisp <=5
replace hisp = . if mracehisp == .

//replace unknown as missing for marital status
replace mar = . if mar==9
replace mar = 0 if mar>1

//replace unknown as missing for father's combined age
replace fagecomb = . if fagecomb == 99

//generate categorical var for mother's educ 
replace meduc = . if meduc == 9

//generate educ var (diff from paper but intuitive)
//generate mom_ed = . 
//replace mom_ed = 0 if meduc <=2 // less than high school
//replace mom_ed = 1 if meduc ==3  // high school
//replace mom_ed = 2 if meduc >=4 & meduc != . // any postsecondary

//generate educ var
generate mom_ed = . 
replace mom_ed = 0 if meduc <=2 // less than high school
replace mom_ed = 1 if meduc ==3 | meduc == 4 // high school
replace mom_ed = 2 if meduc >=5 & meduc != . // any postsecondary

tab mom_ed, gen(edu_cat)



// gen var for first live birth 
replace lbo_rec = . if lbo_rec == 9
gen first_lb = lbo_rec == 1
replace first_lb = . if lbo_rec == .


//gen var for multiple delivery
//gen multiple_deliv = illb_r11==00
gen multiple_deliv = dplural >1


***********************************************************************
****TABLE 1: Summary Stats Table*************
***********************************************************************

*****************************
*number of obs 
*****************************

count if treat==1 & after==1
count if treat==1 & after==0

count if treat==0 & after==1
count if treat==0 & after==0


*****************************
**inspect differences between control (27-28 y/o women) and tx (24-25 y/o) groups pre-policy and post-policy
*****************************


tabstat mager mar hisp race_cat1 race_cat2 race_cat3 edu_cat1 edu_cat2 edu_cat3 first_lb multiple_deliv fagecomb if treat==1, by(after)

tabstat mager mar hisp race_cat1 race_cat2 race_cat3 edu_cat1 edu_cat2 edu_cat3 first_lb multiple_deliv fagecomb if treat==0, by(after)


*****************************
**confidence intervals for estimates; both pre- and post-pol for exposure v control groups
*****************************


foreach variable in mager mar hisp race_cat1 race_cat2 race_cat3 edu_cat1 edu_cat2 edu_cat3 first_lb multiple_deliv fagecomb {
	display "Confidence interval for `variable' estimate - post-pol, exposure group"
	ci means `variable' if treat==1 & after==1
	display "Confidence interval for `variable' estimate - pre-pol, exposure group"
	ci means `variable' if treat==1 & after==0
	display "Confidence interval for `variable' estimate - post-pol, control group"
	ci means `variable' if treat==0 & after==1
	display "Confidence interval for `variable' estimate - pre-pol, control group"
	ci means `variable' if treat==0 & after==0
}


***********************************************************************
****PART 2: Regression Table*************
***********************************************************************

*generate categorical variable for payment type
tab pay_rec, gen(pay_type)


*regression table; exposure v control; pay_type1 is Medicaid
tabstat pay_type1 pay_type2 pay_type3 early_pc adequate_care early_pc_apcnu adequate_care_v2 met_ev_80 csection preterm_v2 lbwt nicu if treat==1, by(after)


tabstat pay_type1 pay_type2 pay_type3 early_pc adequate_care early_pc_apcnu adequate_care_v2 met_ev_80 csection preterm_v2 lbwt nicu if treat==0, by(after)




save dta/ntl-unemp-const.dta, replace


log close
exit
