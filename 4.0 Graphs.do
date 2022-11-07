clear

global data "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\03.Output\Do file 3 output"
global input "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\02.Inputs"


import excel "$input\\countryname", firstrow clear 
tempfile _countryname 
save `_countryname',replace //Now `data' contains the code and year. 

use "$data\\MPM_Total", clear

merge 1:1 file code year using "$data\\MPM_Child.dta", gen(merge_children)
merge 1:1 file code year using "$data\\MPM_Adult.dta", gen(merge_adult)

//adding countryname 
merge 1:1 code using "`_countryname'", gen(merge_countryname)
keep if merge_countryname == 3


export excel using "\\WBGMSAFR1001\AFR_Database\SSAPOV-Harmonization\Bikalpa\MPM\Child poverty note\03.Output\Do file 4 output\Data for child pov note.xls", firstrow(variables) replace
tempfile _final_raw_data
save `_final_raw_data', replace

scatter Child_mdpoor_i1 Adult_mdpoor_i1, mlabel(code)



/*
clear 
**Geographical Represenation 
*Installing the required commands

ssc install spmap
ssc install shp2dta
ssc install mif2dta

*Loading the map

shp2dta using "$input\\Africa.shp", database("$input\\Africadb.dta") coordinates("$input\\Africacoord.dta") genid(id) replace
use "$input\\Africadb.dta", clear

*Cleaning the countryname name 

rename COUNTRY countryname
rename CODE code
replace countryname = "Gambia, The" if countryname == "Gambia"
replace countryname= "São Tomé and Príncipe" if countryname == "Sao Tome and Principe"
replace countryname = "Congo, Dem. Rep." if countryname == "Democratic Republic of Congo"
replace countryname = "Congo, Rep." in 48
*Dropping the North African countries 
drop if countryname == "Algeria" | countryname == "Egypt" | countryname == "Tunisia" | countryname == "Libya" | countryname == "Morocco" | countryname == "Ceuta"
 
save "Africadb.dta", replace


*Merging the current dataset
merge m:1 countryname using "`_final_raw_data'"


 *Map with the data
spmap Total_af_i_m0_1 using "$input\\Africacoord.dta" , id(id) fcolor(BuRd)  title("Multidimensional Poverty Heatmap", size(*0.8)) legenda(on) legtitle("Level of Deprivation") 


 
