/*
Calculating MPI and its constituent measures 
By: Bikalpa Baniya
2019 Summer interns from Oberlin College

This is the second of three do files used to calculate the MPM numbers from GMD. This do file compiles the 
the datasets to calculate the MPM. The four steps in this files are
1) Saving variables required to load the survey and calculate the measures 
2) Making excpeptions because not all surveys are alike 
3) Computing measures required for MPM
4) Calculating weights 

External files used
UNESCO.dta - The dataset was downloaded from the following link and is used to calcuate edu attainment
http://data.uis.unesco.org/

******The methodologies and variables adheres to Minh's code to produce the numbers for PSPR 2018*********

This the list of countries in the SSA. We have excluded ERI GNQ SOM ZWE because datalibweb does not pull data from GMD 
BDI BEN BFA BWA CAF CIV CMR COD COG COM CPV ETH GAB GHA GIN GMB GNB KEN LBR LSO MDG MLI MOZ MRT MUS MWI NAM NER NGA RWA SDN SEN SLE SSD STP SWZ TCD TGO TZA UGA ZAF ZMB SYC AGO 

List of countries from PSPR18:       BDI BEN CIV CMR COD COG ETH GHA GIN GMB GNB LBR LSO MDG MOZ MRT MWI NER RWA SEN SLE STP SYC TCD TGO TZA UGA ZAF ZMB 
List of countries not in the PSPR18: AGO BFA BWA CAF COM CPV ERI SWZ GAB GNQ KEN MLI MUS NAM NGA SDN SOM SSD ZWE
*/


global out "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\03.Output\Do file 2 output"
global data "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\03.Output\Do file 1 output"
global input "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\02.Inputs"


local flist : dir "$data" files "*.dta", nofail respectcase
foreach file of local flist {
	clear 
	**********************
	***Saving variables***
	**********************
	
	use "$data\\`file'", clear
	gen str file = "`file'"
	display "`file'"
	//datalibweb, country(`c') y(`y') surveyid(`surv') type(GMD) mod(ALL) vermast(0`vm') veralt(0`va') files 
	local c = substr(file,1,3)
	local y = substr(file,5,4)

	
	//Saving the primary education age to compute the edu enroll measure 
	//time is selected as 2015 because this value does not change and the UNESCO data has limited years
	use "$input\\UNESCO.dta",clear
	keep if indicator == "Official entrance age to primary education (years)" & location =="`c'" & time ==2015
	display value[1]
	local lbage =value[1]
	local ubage =value[1]+8
	clear 
	
	
	//Loading cpi2011 and icp2011 values 
	////Loading CPI information through datalibweb. Although the required cpi variables are present in the surveys they might not always be 
	//up to data. However, the one below which we pulled from datalibweb should be up to date.
	use "$input\\Final_CPI_PPP_to_be_used.dta",clear
	tostring year, replace
	keep if code == "`c'" & year == "`y'"
	display code[1] year[1]
	loc cpi2011 = cpi2011[1]  //Retriving the cpi, which should now be the first observation of the cpi2011 variable 
	loc icp2011 = icp2011[1]
	display "`cpi2011' `icp2011'"
	clear 
	
	************************
	***Making excpeptions***
	************************
	//Loaing the required surveys and making any required corrections 
	use "$data\\`file'", clear
	display "Correction start `c' `y'"
	*Correction in the data 
	if "`c'" =="SYC"{
		drop hhnew  //because we will be creating this below in the weight section. The current value is wrong 
		rename atschool school //to ensure this is consisent with other surverys 
		rename popw popw1 //because the current value is wrong and we will be recreating the variable 
	}
	//if "`c'" =="GNB" drop educat7 //educat7 does not contain any data 
	display "Correction end"
	
	
	**************************
	***Computing indicators***
	**************************
	
	//Calculating the measures required to create the MPM
	*1a) Education attainment
	local eduflag = 0    //eduflag record that the variable required for edu attain dep is calculated
	local eduage = 15    //This is the cutoff used for PSPR18 but it can be debated   
	cap su educat7
	if r(N)>0 {
		//If educat7 exists, use it 
		gen temp2 = 1 if age>=`eduage' & age~=. & educat7>=3 & educat7~=.
	}
	else {
		cap su educat5
		//If educat7 does not exist but educat5 does, use it 
		if r(N)>0 {
			gen temp2 = 1 if age>=`eduage' & age~=. & educat5>=3 & educat5~=.
		}
		else {	
			cap su educat4
			//If educat 5 does not exists but educat4 does, use it 
			if r(N)>0 {
				gen temp2 = 1 if age>=`eduage' & age~=. & educat4>=2 & educat4~=.
			}
			else { 
				//The required variable is not created
				local eduflag = 1					
			}
		}
	}
	
	if `eduflag'==0 {			
		//If the educat variables are avaialbe, do this
		bys hhid: egen temp3 = sum(temp2) 
		gen dep_educ_com = 0
		replace dep_educ_com = 1 if temp3==0  //If deprived dep_educ_com is 1 
	}
	else {
		gen dep_educ_com = .
	}
	drop temp2 temp3 //Dropping these because we need them for other indicators
	la var dep_educ_com "Deprived if Households with NO adults `eduage'+ with no primary completion"
	
	
	/*1b) Education enrollemnt
	School has a lot of misssing observations. Sometimes more than 50% of the data is missing*/
	cap des school
	if _rc==0 {
		gen temp2 = 1 if age>=`lbage' & age<=`ubage' & school==0 //depr when school==0
		bys hhid: egen temp3 = sum(temp2)	
		gen dep_educ_enr = 0
		replace dep_educ_enr = 1 if temp3>0 & temp3~=.	
		drop temp2 temp3 //Dropping these because we need them for other indicators
	}
	else {
		gen dep_educ_enr = .
	}
	la var dep_educ_enr "Deprived if Households has at least one school-aged child not enrolling in school"

	
	*2a) Electricity 
	cap des electricity
	if _rc==0 gen dep_infra_elec = electricity==0 if electricity~=.
	else 	  gen dep_infra_elec = .
	la var dep_infra_elec "Deprived if HH has No access to electricity"
	

	*2b) Sanitation 
	//Here if imp_sn_rec is avaiable, use it. Otherwise use improved_sanitation to calculate deprivation
	cap des imp_wat_rec
	cap des imp_san_rec
	if _rc==0 {
		gen dep_infra_imps = imp_san_rec==0 if imp_san_rec!=.		
	}
	else{
		cap des improved_sanitation
		if _rc==0 {
			gen dep_infra_imps = improved_sanitation==0 if improved_sanitation!=.
		}
		else{
			gen dep_infra_imps = .		
		}
	}
	la var dep_infra_imps "Deprived if HH has No access to improved sanitation"


	*2c) Drinking water
	//Here if imp_wat_rec is avaiable, use it. Otherwise use improved_water to calculate deprivation
	cap des imp_wat_rec
	if _rc==0 {
		gen dep_infra_impw = imp_wat_rec==0 if imp_wat_rec!=.
	}
	else{
		cap des improved_water
		if _rc==0 {
			gen dep_infra_impw = improved_water==0 if improved_water!=.
		} 
		else{
			gen dep_infra_impw = . 
		}
	}
	la var dep_infra_impw "Deprived if HH has No access to improved drinking water"
	
	*3) Monetary deprivation 
	gen double welfare_ppp = welfare/`cpi2011'/`icp2011'/365
	gen dep_poor1 = welfare_ppp< 1.90 if welfare_ppp~=.
	drop if welfare==.
	la var dep_poor1 "Poor household at $1.9"
	
	
	
	*************************
	***Calculating weights***
	*************************

	//Calculating the required weight. If "weight_p" is persent use that if not use "weight"
	display "Weight start"
	local weight_flag = 0 //Checking that we are using popw when it is present
	cap isid hhid  //Checking if hhid uniquely identifies the observation
	if _rc==0 {
		cap des weight_p
		if _rc==0 gen double popw = weight_p
		else gen double popw = weight
	}
	else {
		cap des weight_p
		if _rc==0 { 
			drop if weight_p==.
			bys hhid: egen double popw = total(weight_p)
		}
		else { 
			drop if weight==.	
			bys hhid: egen double popw = total(weight)
		}							
		//duplicates drop hhid, force
	}
	bys hhid: gen hhnew = _N
	gen double weight_final = popw/hhnew
	drop if weight_final==.
	display "Weight end"
	
	
	//Saving the prepared dataset to calculate the MPM. 
	keep hhid dep_infra_elec popw weight_final hhnew welfare dep_poor1 dep_educ_enr dep_educ_com dep_infra_imps dep_infra_impw welfare_ppp age
	save "$out\\prepped-`file'", replace
}
