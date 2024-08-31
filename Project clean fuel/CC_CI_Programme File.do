
cd "D:\REVIEWER\DATA\DHS WD\WASHPROJECTINCUBATOR\PHASE1\AAPHASE1FILES\Fairlie"
clear all
use wash_sample,clear
*clonevar hv022=strata
note
svyset [pw=wt], psu(psu) strata(strata)

*** Generating the Concentration Index *** 
codebook water_mdg toilet_mdg wash1,compact
svyset [pw=wt], psu(psu) strata(strata)
sort wealthscores
conindex water_mdg, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy  
/*Rural Urban Analyses*/
conindex water_mdg, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy  
conindex water_mdg if rural_loc==1, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy  
conindex water_mdg if rural_loc==0, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy  

*Improved Sanitation
cls 
conindex toilet_mdg, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy 
conindex toilet_mdg if rural_loc==1, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy 
conindex toilet_mdg if rural_loc==0, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy 

*Handwashing
cls
conindex wash1, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy 
conindex wash1 if rural_loc==1, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy 
conindex wash1 if rural_loc==0, rankvar(wealthscores)  limits(0 1) bounded  erreygers svy

****************************************************************************
*******************CONCENTRATION CURVES************************************
cd "D:\REVIEWER\DATA\DHS WD\WASHPROJECTINCUBATOR\PHASE1\AAPHASE1FILES\Fairlie"
clear all
use wash_sample,clear
*clonevar hv022=strata
note
svyset [pw=wt], psu(psu) strata(strata)
la var water_mdg "Safe drinking water"
la var toilet_mdg "Improved sanitation"
la var wash1      "Handwashing hygiene"

*National
lorenz estimate water_mdg toilet_mdg wash1, pvar(wealthscores)
lorenz graph, diagonal(lpattern(dash)) overlay xlabel(0(20)100, labsize(small)) ylabel(0(0.2)1, labsize(small) angle(90)) ///
    xtitle("Percentage of households (poorest to richest)") ytitle("Cumulative Share of WASH uptake")


*Rural
lorenz estimate water_mdg toilet_mdg wash1 if rural_loc==1, pvar(wealthscores)
lorenz graph, diagonal(lpattern(dash)) overlay xlabel(0(20)100, labsize(small)) ylabel(0(0.2)1, labsize(small) angle(90)) ///
    xtitle("Percentage of households (poorest to richest)") ytitle("Cumulative Share of WASH uptake")

*urban
lorenz estimate water_mdg toilet_mdg wash1 if rural_loc==0, pvar(wealthscores)
lorenz graph, diagonal(lpattern(dash)) overlay xlabel(0(20)100, labsize(small)) ylabel(0(0.2)1, labsize(small) angle(90)) ///
    xtitle("Percentage of households (poorest to richest)") ytitle("Cumulative Share of WASH uptake")
 
/*Combining the three graphs*/
* Step 1: Generate each Lorenz plot and save them

* National Lorenz Plot
lorenz estimate water_mdg toilet_mdg wash1, pvar(wealthscores)
lorenz graph, diagonal(lpattern(dash)) overlay xlabel(0(20)100, labsize(small)) ylabel(0(0.2)1, labsize(small) angle(90)) ///
    xtitle("Percentage of households (poorest to richest)") ytitle("Cumulative Share of WASH uptake")
graph save lorenz_national.gph, replace

* Rural Lorenz Plot
lorenz estimate water_mdg toilet_mdg wash1 if rural_loc==1, pvar(wealthscores)
lorenz graph, diagonal(lpattern(dash)) overlay xlabel(0(20)100, labsize(small)) ylabel(0(0.2)1, labsize(small) angle(90)) ///
    xtitle("Percentage of households (poorest to richest)") ytitle("Cumulative Share of WASH uptake")
graph save lorenz_rural.gph, replace

* Urban Lorenz Plot
lorenz estimate water_mdg toilet_mdg wash1 if rural_loc==0, pvar(wealthscores)
lorenz graph, diagonal(lpattern(dash)) overlay xlabel(0(20)100, labsize(small)) ylabel(0(0.2)1, labsize(small) angle(90)) ///
    xtitle("Percentage of households (poorest to richest)") ytitle("Cumulative Share of WASH uptake")
graph save lorenz_urban.gph, replace

* Step 2: Combine the plots using graph combine
	
graph combine lorenz_national.gph lorenz_urban.gph lorenz_rural.gph, ///
    row(2)  ycommon xcommon title("Combined Lorenz Plots for National, Rural, and Urban")	

* Step 3: Clean up by deleting the intermediate graphs
erase lorenz_national.gph
erase lorenz_rural.gph
erase lorenz_urban.gph


cd "D:\REVIEWER\DATA\DHS WD\WASHPROJECTINCUBATOR\PHASE1\AAPHASE1FILES\Fairlie"
clear all
use wash_sample,clear
*clonevar hv022=strata
 codebook water_mdg toilet_mdg wash1,compact
svyset [pw=wt], psu(psu) strata(strata)

********************LOOPING THROUGH********************************************
***************Calculating the concentration index for each country************
*Water 
* Create an Excel file to store results
putexcel set "concentration_indices_results.xlsx", replace

* Write header row to Excel
putexcel A1 = "Country" B1 = "Number of Observations" C1 = "Index Value" D1 = "Standard Error" E1 = "p-value"

* Define the starting row for results in Excel
local row = 2

* Loop through each country (assuming country1 ranges from 1 to 33)
forvalues i = 1/33 {
    * Calculate concentration index for the current country
    conindex water_mdg if country1 == `i', rankvar(wealthscores) limits(0 1) bounded erreygers svy
    
    * Display results to see what's being stored
    return list
    
    * Retrieve results from conindex command
    local num_obs = r(Nunique)  // Number of observations
    local index_value = r(CI)  // Concentration index value
    local std_error = r(CIse)  // Standard error
    local p_value = r(RSS)   // p-value

    * Write the results to Excel
    putexcel A`row' = `i' B`row' = `num_obs' C`row' = `index_value' D`row' = `std_error' E`row' = `p_value'
    
    * Increment row for the next country
    local row = `row' + 1
}

* Save the Excel file
putexcel save

*************************************************************************************************SANITATION CONCENTRATION INDICES**************************************
clear all
use washreg21st,clear
 codebook water_mdg toilet_mdg wash1,compact
svyset [pw=wt], psu(psu) strata(strata)


/***LOOPING THROUGH******/

* Create an Excel file to store results
putexcel set "concentration_indices_sanitation.xlsx", replace

* Write header row to Excel
putexcel A1 = "Country" B1 = "Number of Observations" C1 = "Index Value" D1 = "Standard Error" E1 = "p-value"

* Define the starting row for results in Excel
local row = 2

* Loop through each country (assuming country1 ranges from 1 to 33)
forvalues i = 1/33 {
    * Calculate concentration index for the current country
    conindex toilet_mdg if country1 == `i', rankvar(wealthscores) limits(0 1) bounded erreygers svy
    
    * Display results to see what's being stored
    return list
    
    * Retrieve results from conindex command
    local num_obs = r(Nunique)  // Number of observations
    local index_value = r(CI)  // Concentration index value
    local std_error = r(CIse)  // Standard error
    local p_value = r(RSS)   // p-value

    * Write the results to Excel
    putexcel A`row' = `i' B`row' = `num_obs' C`row' = `index_value' D`row' = `std_error' E`row' = `p_value'
    
    * Increment row for the next country
    local row = `row' + 1
}

* Save the Excel file
putexcel save



*************************************************************************************
*************Hanwashing Hygiene***************************************************
**************************************************************************************
clear all
use wash_sample,clear
*clonevar hv022=strata
 codebook water_mdg toilet_mdg wash1,compact
svyset [pw=wt], psu(psu) strata(strata)

* Create an Excel file to store results
putexcel set "concentration_indices_Hygiene.xlsx", replace

* Write header row to Excel
putexcel A1 = "Country" B1 = "Number of Observations" C1 = "Index Value" D1 = "Standard Error" E1 = "p-value"

* Define the starting row for results in Excel
local row = 2

* Loop through each country (assuming country1 ranges from 1 to 33)
forvalues i = 1/33 {
    * Calculate concentration index for the current country
    conindex wash1  if country1 == `i', rankvar(wealthscores) limits(0 1) bounded erreygers svy
    
    * Display results to see what's being stored
    return list
    
    * Retrieve results from conindex command
    local num_obs = r(Nunique)  // Number of observations
    local index_value = r(CI)  // Concentration index value
    local std_error = r(CIse)  // Standard error
    local p_value = r(RSS)   // p-value

    * Write the results to Excel
    putexcel A`row' = `i' B`row' = `num_obs' C`row' = `index_value' D`row' = `std_error' E`row' = `p_value'
    
    * Increment row for the next country
    local row = `row' + 1
}

* Save the Excel file
putexcel save


/*INTEGRATING MACRO LEVEL INSTRUMENT*/
cd "D:\REVIEWER\DATA\DHS WD\WASHPROJECTINCUBATOR\PHASE1\AAPHASE1FILES\Fairlie"
clear all
use wash_sample,clear
*clonevar hv022=strata
lookfor country
fre country1
egen tag=tag(country)
fre tag
fre year_interview
outsheet country year_interview using Macro.xls if tag==1,replace
shell Macro.xls











