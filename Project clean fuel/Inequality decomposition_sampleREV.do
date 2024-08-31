//Decomposition anaysis//
cd "D:\REVIEWER\DATA\DHS WD\WASHPROJECTINCUBATOR\PHASE1\AAPHASE1FILES"
dir 
use wash_sample,clear
clonevar hv022=strata
svyset [pw=wgt], psu(hv001) strata(hv022)									// Declaring Survey data

*svyset [pw=wt], psu(psu) strata(strata)

	rename wealthscores x																// Wealth index score: to use as continuos variable of wealth
		sort x, stable															// Arranging in inreasing order

	macro drop _all														  		// Taking of all Macros in memory

	clear matrix														        // Taking off all matrices from memory


*** 2 Setting the Dependent variable 
	*global y "Stunting"    
     global y "water_mdg"
****4 Creating Macro for Dependent variables
	*tab reg, gen(reg_)
	global X "age_head2 sex_headf  head_educ2 head_educ3 head_educ4"
	
*drop if e(sample)!=1															// Drop observations with missings on X

	egen m_y = mean($y)		        											// Mean of variable of interest	


//Bootstrap	   
 
set matsize 1000																// Increasing matrice size to allow the increase in sample when booting

program drop Jakeboot
																				// Check any existing programme, start next line if programme not found i.e r(111)
capture program drop Jakeboot, rclass  
                              			// setting the program as r class
program define Jakeboot
conindex $y ,  rankvar(x)  erreygers bounded limits(0 1) loud  svy      		// Concentration index of variable of interest
sca EI=r(CI)                                                          			// saving its scalars

svy:  logistic $y $X                                                   			// Logistic equation to get the marginal effects
margin, dydx(*) post											      			// calculating Marginal effects
matrix dfdx=e(b)												      			// Saving a matrix of Marginal; effects


foreach x of global X {
	qui {
		mat b_`x'     = dfdx[1,"`x'"]			                     			// Collecting Matrix of marginal effects 
		sca b_`x'     = b_`x'[1,1]                                    			// Collecting  Scalars from regression abive
		sum `x' [aw=wgt]                                               			// Summarrising each X variable
		sca m_`x'     = r(mean)	                                     			// Taking the scalr of each summerised x variable
		conindex `x' [aw=wgt], rank(x) truezero robust                			// Taking the concentration index for each X variable
		sca elas_`x'  = (b_`x'*m_`x')/m_y		                      			// Elasticity of Y with respect to X 
		sca CI_`x'    = r(CI)			                             			// Collecting CI as scalar
		sca con_`x'   = 4*b_`x'*m_`x'*CI_`x'			              			// geting the contributions
		sca prcnt_`x' = 100*con_`x'/EI	                             			// getting the Percent contributions
		}
		
	di "`x' elasticity:", elas_`x'									  			// displaying the  elasticity of each X
	di "`x' concentration index:", CI_`x'                             			// displaying the CI of each X
	di "`x' contribution:", con_`x'                                   			// displaying the contribution of each X
	di "`x' percentage contribution:", prcnt_`x'                      			// displaying the percent of each contribution
matrix Aaa = nullmat(Aaa) \ ///										 			// Creating a null Matrix
(elas_`x',CI_`x', con_`x', prcnt_`x')								  			// collecting the stored scalars elas, C, contribution and Percent in matrix
}
end

*des age_head2 sex_headf  head_educ2 head_educ3 head_educ4
mwaaaaaa
bootstrap EI    , strata(hv022) nowarn reps(50) seed(100): Jakeboot 
estimates store EI_water

		# delimit ;
bootstrap CI_age_head2 CI_sex_headf CI_head_educ2 CI_head_educ3 CI_head_educ4 
		, strata(hv022) nowarn reps(50) seed(12345): Jakeboot
		;
		# delimit cr
*seed=12345	
estimates store CI_water
*des age_head2 sex_headf  head_educ2 head_educ3 head_educ4
		# delimit ;
bootstrap b_age_head2 b_sex_headf b_head_educ2 b_head_educ3 b_head_educ4 
		, strata(hv022) nowarn reps(50) seed(12345): Jakeboot
		;
		# delimit cr
		
		estimates store coef_water
*des age_head2 sex_headf  head_educ2 head_educ3 head_educ4		
		# delimit ;
bootstrap elas_age_head2 elas_sex_headf elas_head_educ2 elas_head_educ3 elas_head_educ4 
		, strata(hv022) nowarn reps(50) seed(12345): Jakeboot
		;
		# delimit cr
		
estimates store elas_water

*des age_head2 sex_headf  head_educ2 head_educ3 head_educ4		
		# delimit ;
bootstrap con_age_head2 con_sex_headf con_head_educ2 con_head_educ3 con_head_educ4 
		, strata(hv022) nowarn reps(50) seed(12345): Jakeboot
		;
		# delimit cr
		
 estimates store cont_water
 
*des age_head2 sex_headf  head_educ2 head_educ3 head_educ4
		# delimit ;
bootstrap prcnt_age_head2 prcnt_sex_headf prcnt_head_educ2 prcnt_head_educ3 prcnt_head_educ4
		, strata(hv022) nowarn reps(50) seed(12345): Jakeboot
		;
		# delimit cr
		
 estimates store prcnt_water
 
		# delimit ;
esttab CI_water  elas_water cont_water prcnt_water using Facility2014_boot.rtf, replace cells(b(star fmt(3)) se(par fmt(3))) style(fixed) starlevels("*" 0.10 "**" 0.05 "***" 0.01) nonum title(Table 1: Decomposition of inequality in stunting) mti( " Concentration Index"  " Elasticity" "Contribution" "(%)") coeflabel( _bs_1 "Age head" _bs_2 "Female head" _bs_3 "Head's education (Primary)" _bs_4 "Head's education (Secondary)" _bs_5 "Head's education (Tertiary)") nogap compress  legend 
		;
		# delimit cr
