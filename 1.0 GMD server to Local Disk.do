/*
This is the first of four do files used to calculate the MPM numbers from GMD. This file simply 
stores the relevant data to a local folder so that we do not have to access datalibweb again. 
Storage of the files vastly reduces any processing time while making corrections. 


External files used:
PSPR2018_MPM - This file countains the countries and the surveys used to construct the PSPR18 MPM.



This the list of countries in the SSA. We have excluded ERI GNQ SOM ZWE because datalibweb does not pull data from GMD 
{BDI BEN BFA BWA CAF CIV CMR COD COG COM CPV ETH GAB GHA GIN GMB GNB KEN LBR LSO MDG MLI MOZ MRT MUS MWI NAM NER NGA RWA SDN SEN SLE SSD STP SWZ TCD TGO TZA UGA ZAF ZMB SYC AGO 

List of countries from PSPR18:       BDI BEN CIV CMR COD COG ETH GHA GIN GMB GNB LBR LSO MDG MOZ MRT MWI NER RWA SEN SLE STP SYC TCD TGO TZA UGA ZAF ZMB 
List of countries not in the PSPR18: AGO BFA BWA CAF COM CPV ERI SWZ GAB GNQ KEN MLI MUS NAM NGA SDN SOM SSD ZWE
*/



//global countries ="BDI BEN CIV CMR COD COG ETH GHA GIN GMB GNB LBR LSO MDG MOZ MRT MWI NER RWA SEN SLE STP SYC TCD TGO TZA UGA ZAF ZMB AGO BFA BWA CAF COM CPV SWZ GAB KEN MLI MUS NAM NGA SDN SSD"
global countries ="BDI BEN";
global out "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\MPM using latest surverys\03.Output\Do file 1 output"




foreach ccc of glo countries {
	
	//saving the items required for this country to load survey from datalibweb

	clear 
	
	datalibweb, country(`ccc') latesty type(GMD) mod(ALL) files 
	
    
	loc a =  r(filename) //Here r(surveyid) give us the name of the file stored on the backend of datalibweb. "help datalibweb" will gives more information
	display "`a'"
	//Saving the survey into a local file. 
	save "$out\\`a'", replace
	macro drop _all 
	//Dropping all macros to ensure the next country does not use it. Although they can be redefined 
	//this is a simply a just in case thing
}

clear
//Loading CPI information through datalibweb. Although the required cpi variables are present in the surveys they might not always be 
//up to data. However, the one below which we pull from datalibweb should be up to date. 
qui datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v03_M) filename(Final_CPI_PPP_to_be_used.dta)
save "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\MPM using latest surverys\02.Inputs\Final_CPI_PPP_to_be_used.dta",replace 



