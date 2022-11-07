/*
Calculating MPI and its constituent measures 
By: Bikalpa Baniya
2019 Summer interns from Oberlin College

This is the final of three files required to calucate the MPM from GMD. It does the 
calculation required to create the constituent measures and the MPM index. The steps are
-Load required excel sheets 
-Assign and adjust weights 
-Calculate the MPM 
-Produce this final spreadsheet


External files used
PSPR2018_MPM - Has country name, code and MPM index from PSPR18
MPM tables PSPR2018 - Numbers from the 2018 PSPR
*/

clear

global data "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\03.Output\Do file 2 output"
global out "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\03.Output\Do file 3 output\test"


**************************
***Loading excel sheets***
**************************

//Saving the required files to add info and creating a temp file to save our results 
clear 
tempfile alldata
save `alldata', replace emptyok //This will be our output file


clear 
local flist : dir "$data" files "*.dta", nofail respectcase
foreach file of local flist {
	
	use "$data\\`file'", clear
	gen str file = "`file'"
	
	//This ensures that we are only looking at adult 
	keep if age > 18
	
	
	//The PSPR indicators computes deprivation at the household level. However, our survey as of right now stores data at the 
	//individual level. Information on deprivation for a given household is already stored in variables like 
	//dep_educ_com, dep_educ_enr, dep_infra_elec, dep_infra_impw, dep_infra_imps, dep_poor1 for all members of the household. So we 
	//can simply use one of the observation and drop the rest of the observations in that household. We are using force here because 
	//individuals in the hh have different values for some variables and STATA gives an error is we use duplicate alone. 
	duplicates drop hhid, force
	
	// We do this because some countries' hhid are int. So appeneding at the end will give us an error
	cap tostring hhid, replace force format(%19.0f) 

	//missing obs for some HHs. This is to ensure that these household are not considered. Adjustment will 
	//be made later. 
	gen touse = dep_educ_com*dep_educ_enr*dep_infra_elec*dep_infra_impw*dep_infra_imps*dep_poor1~=.
	
	
	
	*******************************
	***Assign and adjust weights***
	*******************************
	
	//Dimensions and indicators setup	
	//Allocating the indicators to different macors to save us from repeated typing. 
	local edu		dep_educ_com dep_educ_enr
	local infra		dep_infra_elec dep_infra_imps dep_infra_impw
	local pov		dep_poor1
	local dims edu infra pov 
	

	
	//MPI - equal weight for each dimension, and indicators within each dimension	
	//Assigning weight to the different indicators. They might change for different hh 
	//according to avability of data within the measures. 
	//Here wordcount ensures that ndim is dynamic. As hh might not have all indicators computed. 
	local pov welfare_ppp
	local ndim = "`=wordcount("`dims'")'" 
	foreach dim of local dims {
		local nvar = "`=wordcount("``dim''")'"
		foreach var in ``dim'' {
			gen w_`var' = 1/(`ndim'*`nvar')
		}
	}
	
	

	
	//Weight adjustment according to avability of data. We do this because the indicators might be missing in 
	//some cases and we have to reassign the weights
	//Weight adjustment - Education - dep_educ_com dep_educ_enr
	*gen tmp_edu = dep_educ_com*dep_educ_enr
	// 1 0
	replace w_dep_educ_com = 1/3 if dep_educ_com~=. & dep_educ_enr==.
	replace w_dep_educ_enr = 0   if dep_educ_com~=. & dep_educ_enr==.
	replace touse = 1            if dep_educ_com~=. & dep_educ_enr==.
	// 0 1
	replace w_dep_educ_enr = 1/3 if dep_educ_com==. & dep_educ_enr~=.
	replace w_dep_educ_com = 0   if dep_educ_com==. & dep_educ_enr~=.
	replace touse = 1            if dep_educ_com==. & dep_educ_enr~=.
	
	//Weight adjustment - Infrastructure - dep_infra_elec dep_infra_imps dep_infra_impw
	//0 1 1
	replace w_dep_infra_elec  = 0                  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	replace w_dep_infra_imps  = (1/9) + 0.5*(1/9)  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	replace w_dep_infra_impw = (1/9) + 0.5*(1/9)   if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	replace touse = 1                              if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw~=.
	
	//1 0 1
	replace w_dep_infra_elec  = (1/9) + 0.5*(1/9)  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_imps  = 0                  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_impw = (1/9) + 0.5*(1/9)   if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	replace touse = 1                              if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw~=.
	
	//1 1 0
	replace w_dep_infra_elec  = (1/9) + 0.5*(1/9)  if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_imps  = (1/9) + 0.5*(1/9)  if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_impw = 0                   if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	replace touse = 1                              if dep_infra_elec~=. & dep_infra_imps~=. & dep_infra_impw==.
	
	//1 0 0
	replace w_dep_infra_elec  = (1/9) + 2*(1/9)    if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	replace w_dep_infra_imps  = 0                  if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	replace w_dep_infra_impw = 0                   if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	replace touse = 1                              if dep_infra_elec~=. & dep_infra_imps==. & dep_infra_impw==.
	
	//0 0 1
	replace w_dep_infra_elec  = 0                  if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_imps  = 0                  if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	replace w_dep_infra_impw = (1/9) + 2*(1/9)     if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	replace touse = 1                              if dep_infra_elec==. & dep_infra_imps==. & dep_infra_impw~=.
	
	//0 1 0
	replace w_dep_infra_elec  = 0                  if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_imps  = (1/9) + 2*(1/9)    if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	replace w_dep_infra_impw = 0                   if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	replace touse = 1                              if dep_infra_elec==. & dep_infra_imps~=. & dep_infra_impw==.
	
	********************************
	***Calcuate the MPM headcount***
	********************************
	
	
	
	//reverse dummy because it is noted as deprived. We reverses the variables to mean that the hh are not deprived 
	//We do this because it is how y_ij is defined in Page 111 4B.1 in the PSPR
	foreach var of varlist dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw {
		replace `var' = 1 - `var'
	}
	
	//Defining the deprivation point for indicators. This is z_j in formlulae 4B.1 in PSPR18
	local pline 1.9	
	local depr  dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw  welfare_ppp
	local zline 1            1            1              1              1              `pline'	
	
	

	
	//Now calcualting the poverty headcount below. 
	tokenize `zline'
	local c = 1
	foreach ind of local depr {
		local alpha=0 
		gen g_i_`alpha'_`ind' = ((1- `ind'/``c'')^`alpha') * (`ind'<``c'')
		gen wg_i_`alpha'_`ind' = g_i_`alpha'_`ind'*w_`ind'
		
		local c = `c' + 1
	}
	
	

	
	
	//We are looking at the case where alpha is zero 
	egen wci_0 = rowtotal(wg_i_0_*) //This is A
	gen mdpoor_i1 = (wci_0>=1/3) if wci_0~=. //This is H 
	gen af_i_m0_1 = mdpoor_i1*wci_0 //This is M = H*A
	
	

	
	
	//Reverse dummy to note deprived 
	foreach var of varlist dep_educ_com dep_educ_enr dep_infra_elec dep_infra_imps dep_infra_impw {
		replace `var' = 1 - `var'
	}
	
	
	//Is this person deprived in both measures 
	gen poor_both = 0 if mdpoor_i1 !=. & dep_poor1 !=.
	replace poor_both = 1 if mdpoor_i1 ==1 & dep_poor1 ==1 & mdpoor_i1 !=. & dep_poor1!=.
	
	
	//Is this person not deprived in any measure
	gen not_poor_both = 0 if mdpoor_i1 !=. & dep_poor1 !=.
	replace not_poor_both = 1 if mdpoor_i1 == 0 & dep_poor1 == 0 & mdpoor_i1 !=. & dep_poor1 !=.
	
	//Is this person deprived only in moneterary
	gen poor_mon_only = 0 if mdpoor_i1 !=. & dep_poor1 !=.
	replace poor_mon_only = 1 if mdpoor_i1 == 0 & dep_poor1 == 1 & mdpoor_i1 !=. & dep_poor1 !=.
	
	//Is this person deprived only in moneterary
	gen poor_multi_only = 0 if mdpoor_i1 !=. & dep_poor1 !=.
	replace poor_multi_only = 1 if mdpoor_i1 == 1 & dep_poor1 == 0 & mdpoor_i1 !=. & dep_poor1 !=.
	
	
	append using `alldata', force
	save `alldata', replace
}

*************************
***Result Presentation***
*************************


use `alldata', clear
//collapse (mean) dep_poor1 mdpoor_i1 poor_both not_poor_both [aw=weight_final], by(file)
collapse (mean) dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec  dep_infra_imps dep_infra_impw mdpoor_i1 af_i_m0_1 poor_both not_poor_both poor_mon_only poor_multi_only [aw=weight_final], by(file)


//Rounding out the variables
local deplist dep_poor1 dep_educ_com dep_educ_enr dep_infra_elec  dep_infra_imps dep_infra_impw mdpoor_i1 af_i_m0_1 poor_both not_poor_both poor_mon_only poor_multi_only 
foreach var of local deplist{
	gen `var'_1 = round(`var' * 100, 0.01)
	drop `var'
	rename `var'_1 Adult_`var' 
}

la var Adult_poor_both "Adult deprived in both monetary and nonmonetary"
la var Adult_not_poor_both "Adult not deprived in either monetary and nonmonetary"
la var Adult_dep_poor1 "Adult deprived in monetary"
la var Adult_dep_educ_com "Adult Deprived in education completion"
la var Adult_dep_educ_enr "Adult Deprived in education attainment"
la var Adult_dep_infra_elec "Adult Deprived in electricity"
la var Adult_dep_infra_imps "Adult Deprived in sanitation"
la var Adult_dep_infra_impw "Adult Deprived in drinking water"
la var Adult_mdpoor_i1 "Adult deprived in nonmonetary"
la var Adult_poor_multi_only "Adult deprived in multidimensionaly only"
la var Adult_poor_mon_only "Adult deprived in monetary only"
la var Adult_af_i_m0_1 "Adult M"

gen code = substr(file,9,3)
gen year = substr(file,13,4)

save "$out\\MPM_adult_data", replace
