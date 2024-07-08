/*******************************************************************************
Main estimates a la Jaeger, Ruist and Stuhler (2019) with unscaled figures 
from income side GVA 
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

foreach y in y_uns lWB_uns yWB_uns { 
	/*
	Static models 
	*/
	ivreghdfe S10.`y' (D10xsh = z`z') /// 
		[pw = weight] if  year >= 2012, /// 
		abs($FE) clus(locid) endog(D10xsh) first ffirst savefirst 
	est store IV`y'_stat
			
	reghdfe S10.`y' D10xsh /// 
		[pw = weight] if year >= 2012, /// 
		abs($FE) clus(locid)  
	est store OLS`y'_stat
		
	/*
	Dynamic models 
	*/
	ivreghdfe S10.`y' (D10xsh L10D10xsh = z`z' L10z`z') /// 
		[pw = weight] if year >= 2012, /// 
		abs($FE) clus(locid) endog(D10xsh L10D10xsh) first ffirst savefirst 
		est store IV`y'_dyn

	reghdfe S10.`y' D10xsh L10D10xsh /// 
		[pw = weight] if year >= 2012, /// 
		abs($FE) clus(locid)  
	est store OLS`y'_dyn
}

distinct locid 	
local nregion = string(r(ndistinct), "%12.0fc")
est restore OLSy_uns_stat
local obs = string(e(N), "%12.0fc") 
#delimit ;
	estout 	OLSy_uns_stat IVy_uns_stat OLSy_uns_dyn IVy_uns_dyn
			using "$tables/MainTableUNS.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh L10D10xsh)
	mlabels("(1)" "(2)" "(3)" "(4)",)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
				L10D10xsh "Lagged $\Delta$ Immigrant Share"
			)
	collabels(,none)
	type
	replace 
	style(tex)
	prehead(\begin{tabularx}{\textwidth}{l*{4}{Y}}\toprule )
	posthead( 	& \multicolumn{2}{c}{Static} 
				& \multicolumn{2}{c}{Dynamic} \\ 
				\cmidrule(lr){2-3} \cmidrule(lr){4-5}
				& OLS & IV & OLS & IV \\ 
				\cmidrule(lr){2-5}
				& \multicolumn{4}{c}{Labour Productivity} \\ 
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	postfoot(\midrule)
	prefoot(\addlinespace)
	;
	#delimit ;
	estout 	OLSlWB_uns_stat IVlWB_uns_stat OLSlWB_uns_dyn IVlWB_uns_dyn
			using "$tables/MainTableUNS.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh L10D10xsh)
	mlabels(,none)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
				L10D10xsh "Lagged $\Delta$ Immigrant Share"
			)
	collabels(,none)
	type
	append 
	style(tex)
	posthead( 	& \multicolumn{4}{c}{Labour Cost} \\ 
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
	postfoot(\midrule)
	;
#delimit ;
	estout 	OLSyWB_uns_stat IVyWB_uns_stat OLSyWB_uns_dyn IVyWB_uns_dyn
			using "$tables/MainTableUNS.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh L10D10xsh)
	mlabels(,none)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
				L10D10xsh "Lagged $\Delta$ Immigrant Share"
			)
	collabels(,none)
	type
	append 
	style(tex)
	posthead( 	& \multicolumn{4}{c}{Labour Share} \\ 
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
	postfoot(
		\addlinespace
		\midrule
		Obs. & \multicolumn{4}{c}{`obs'} \\
		Regions & \multicolumn{4}{c}{`nregion'} \\
		\bottomrule \end{tabularx}
		);
#delimit cr

/*******************************************************************************
Robustness: Labour Productivity Static
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

mat drop _all 
ivreghdfe S10.y (D10xsh = z) [aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (-1, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yH (D10xsh = z) ///
	[aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (1, r(estimate), r(lb), r(ub))   

ivreghdfe S10.y  (D10xsh = z) [aweight = weight] ///
	if year >= 2014, /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (2, r(estimate), r(lb), r(ub))   

ivreghdfe S10.y  (D10xsh = z) [aweight = weight], /// 
	abs($FE gor9d) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (3, r(estimate), r(lb), r(ub))   

ivreghdfe S10.y  (D10xsh = z) [aweight = weight], /// 
	abs($FE gor9d##year) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (4, r(estimate), r(lb), r(ub))   

ivreghdfe S10.y (D10xsh = z) /// 
	[aweight = weight] if !london, /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (5, r(estimate), r(lb), r(ub))   

ivreghdfe S10.y (D10xsh = z) ///
	[aweight = weight] if !scotland & !wales, /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (6, r(estimate), r(lb), r(ub))   

ivreghdfe S10.y  (D10xsh = z) /// 
	[aweight = weight] if !scotland & !wales & !london, /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (7, r(estimate), r(lb), r(ub))   

ivreghdfe S10.y $X (D10xsh = z) /// 
	[aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (8, r(estimate), r(lb), r(ub))   

use "$data/AnalysisDataTTWA.dta", clear 
ivreghdfe S10.y (D10xsh = z) [aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (9, r(estimate), r(lb), r(ub))   

mat colnames A = x b lb ub
svmat A, names(col)
count if !missing(x)
local n = r(N) + 1
replace x = 1 if _n == `n'
g n = 0 if _n == `n'
replace b = 0 if _n == `n'

#delimit ; 
twoway 
(scatter x b if (x > 0 | x < 0) & missing(n), col(black)) 
(scatter x b if !missing(n), col(none)) 
(rcap lb ub x if (x > 0 | x < 0) & missing(n), horizontal lcol(black))
(scatter x b if x == 0, col(black)) 
(rcap lb ub x if x == 0, horizontal lcol(black)), 
legend(off) xline(0, lc(black) lp(dash)) 
xtitle("Estimated Effect") ytitle("")
ylabel(	
		-1 "Baseline" 
		1 "GVA per Hour (2004-2015)" 
		2 "Productivity (2004-2015)" 
		3 "NUTS1 Fixed Effects"
		4 "NUTS1 x Year Fixed Effects"
		5 "Excluding London"
		6 "England"
		7 "England Excl.London"
		8 "Additional Controls"
		9 "Aggregated to TTWA"
		, 
		angle(0) labsize(large))
					; 
#delimit cr
graph export "$plots/yRobust.eps", replace 
drop x b lb ub

/*******************************************************************************
Robustness: Labour Productivity Dynamic
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

mat drop _all 
ivreghdfe S10.y (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (-1.15, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (-.85, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yH (D10xsh L10D10xsh = z L10z) ///
	[aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (1.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.y (D10xsh L10D10xsh = z L10z) [aweight = weight] ///
	if year >= 2014, /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (1.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (2.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.y  (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE gor9d) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (2.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (3.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.y  (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE gor9d##year) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (3.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (4.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.y (D10xsh L10D10xsh = z L10z) /// 
	[aweight = weight] if !london, /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (4.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (5.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.y (D10xsh L10D10xsh = z L10z) ///
	[aweight = weight] if !scotland & !wales, /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (5.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (6.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.y  (D10xsh L10D10xsh = z L10z) /// 
	[aweight = weight] if !scotland & !wales & !london, /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (6.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (7.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.y $X (D10xsh L10D10xsh = z L10z) /// 
	[aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (7.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (8.15, 1, r(estimate), r(lb), r(ub), `weak')  

use "$data/AnalysisDataTTWA.dta", clear 
ivreghdfe S10.y (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (8.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (7.15, 1, r(estimate), r(lb), r(ub), `weak')  

mat colnames A = x g b lb ub weak
svmat A, names(col)
count if !missing(x)
local n = r(N) + 1
replace x = 1 if _n == `n'
g n = 0 if _n == `n'
replace b = 0 if _n == `n'

#delimit ; 
twoway 
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 0, col(black) ms("o"))
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 0, col(red) ms("o"))  
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 1, col(black) ms("X") msize(huge))
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 1, col(red) ms("X") msize(huge))  
(scatter x b if !missing(n), col(none)) 
(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 0, horizontal lcol(black))
(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 1, horizontal lcol(red))
(scatter x b if x == 0, col(black)) 
(rcap lb ub x if x == 0, horizontal lcol(black)), 
legend(pos(6) order(1 "Immigrant Share" 2 "Lagged Immigrant Share") cols(1)) 
	xline(0, lc(black) lp(dash)) 
xtitle("Estimated Effect") ytitle("")
ylabel(	
		-1 "Baseline" 
		1 "GVA per Hour (2004-2015)" 
		2 "Productivity (2004-2015)" 
		3 "NUTS1 Fixed Effects"
		4 "NUTS1 x Year Fixed Effects"
		5 "Excluding London"
		6 "England"
		7 "England Excl.London"
		8 "Additional Controls"
		9 "Aggregated to TTWA"
		, 
		angle(0) labsize(large))
		;
#delimit cr
graph export "$plots/yRobustDyn.eps", replace 
drop x b lb ub weak

/*******************************************************************************
Robustness: Labour Share Static
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

mat drop _all 
ivreghdfe S10.yWB2 (D10xsh = z) [aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (-1, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yWB2  (D10xsh = z) [aweight = weight], /// 
	abs($FE gor9d) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (1, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yWB2  (D10xsh = z) [aweight = weight], /// 
	abs($FE gor9d##year) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (2, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yWB2  (D10xsh = z) /// 
	[aweight = weight] if !london, /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (3, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yWB2  (D10xsh = z) ///
	[aweight = weight] if !scotland & !wales, /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (4, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yWB2 (D10xsh = z) /// 
	[aweight = weight] if !scotland & !wales & !london, /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (5, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yWB2 $X (D10xsh = z) /// 
	[aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (6, r(estimate), r(lb), r(ub))   

ivreghdfe S10.yWB1 (D10xsh = z) /// 
	[aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (7, r(estimate), r(lb), r(ub))   

use "$data/AnalysisDataTTWA.dta", clear 
ivreghdfe S10.yWB2 (D10xsh = z) [aweight = weight], /// 
	abs($FE) clus(locid) 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (8, r(estimate), r(lb), r(ub))   

mat colnames A = x b lb ub
svmat A, names(col)
count if !missing(x)
local n = r(N) + 1
replace x = 1 if _n == `n'
g n = 0 if _n == `n'
replace b = 0 if _n == `n'

#delimit ; 
twoway 
(scatter x b if (x > 0 | x < 0) & missing(n), col(black)) 
(scatter x b if !missing(n), col(none)) 
(rcap lb ub x if (x > 0 | x < 0) & missing(n), horizontal lcol(black))
(scatter x b if x == 0, col(black)) 
(rcap lb ub x if x == 0, horizontal lcol(black)), 
legend(off) xline(0, lc(black) lp(dash)) 
xtitle("Estimated Effect") ytitle("")
ylabel(	
		-1 "Baseline" 
		1 "NUTS1 Fixed Effects"
		2 "NUTS1 x Time Fixed Effects"
		3 "Excluding London"
		4 "England"
		5 "England Excl.London"
		6 "Additional Controls"
		7 "COE Only Labour Share"
		8 "Aggregated to TTWA"
		,  
	   angle(0) labsize(large))
					; 
#delimit cr
graph export "$plots/yWB2Robust.eps", replace 
drop x b lb ub

/*******************************************************************************
Robustness: Labour Share Dynamic
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

mat drop _all 
ivreghdfe S10.yWB2 (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (-1.15, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (-.85, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yWB2  (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE gor9d) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (1.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yWB2  (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE gor9d##year) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (1.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (2.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yWB2  (D10xsh L10D10xsh = z L10z) /// 
	[aweight = weight] if !london, /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (2.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (3.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yWB2  (D10xsh L10D10xsh = z L10z) ///
	[aweight = weight] if !scotland & !wales, /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (3.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (4.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yWB2 (D10xsh L10D10xsh = z L10z) /// 
	[aweight = weight] if !scotland & !wales & !london, /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (4.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (5.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yWB2 $X (D10xsh L10D10xsh = z L10z) /// 
	[aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (5.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (6.15, 1, r(estimate), r(lb), r(ub), `weak')  

ivreghdfe S10.yWB1 (D10xsh L10D10xsh = z L10z) /// 
	[aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (6.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (7.15, 1, r(estimate), r(lb), r(ub), `weak')  

use "$data/AnalysisDataTTWA.dta", clear 
ivreghdfe S10.yWB2 (D10xsh L10D10xsh = z L10z) [aweight = weight], /// 
	abs($FE) clus(locid) first ffirst 
mat FIRST = e(first) 	
local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
lincom D10xsh, level(95)
mat A = nullmat(A) \ (7.85, 0, r(estimate), r(lb), r(ub), `weak')  
lincom L10D10xsh, level(95)
mat A = nullmat(A) \ (8.15, 1, r(estimate), r(lb), r(ub), `weak')  

mat colnames A = x g b lb ub weak 
svmat A, names(col)
count if !missing(x)
local n = r(N) + 1
replace x = 1 if _n == `n'
g n = 0 if _n == `n'
replace b = 0 if _n == `n'

#delimit ; 
twoway 
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 0, col(black) ms("o"))
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 0, col(red) ms("o"))  
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 1, col(black) ms("X") msize(huge))
(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 1, col(red) ms("X") msize(huge))  
(scatter x b if !missing(n), col(none)) 
(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 0, horizontal lcol(black))
(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 1, horizontal lcol(red))
(scatter x b if x == 0, col(black)) 
(rcap lb ub x if x == 0, horizontal lcol(black)), 
legend(pos(6) order(1 "Immigrant Share" 2 "Lagged Immigrant Share") cols(1)) 
	xline(0, lc(black) lp(dash)) 
xtitle("Estimated Effect") ytitle("")
ylabel(	
		-1 "Baseline" 
		1 "NUTS1 Fixed Effects"
		2 "NUTS1 x Time Fixed Effects"
		3 "Excluding London"
		4 "England"
		5 "England Excl.London"
		6 "Additional Controls"
		7 "COE Only Labour Share"
		8 "Aggregated to TTWA"
		,  
	   angle(0) labsize(large))
		;
#delimit cr
graph export "$plots/yWB2RobustDyn.eps", replace 
drop x b lb ub weak

/*******************************************************************************
Robustness: How to measure immigration shocks static
*******************************************************************************/
foreach y in y yWB2 {
	use "$data/AnalysisData.dta", clear 
	xtset locid year 
	
	su D10xsh if year >= 2012 
	local sdD10xsh = r(sd)
	foreach v of varlist D10xrat D10M L10D10xrat L10D10M { 
		su `v' if year >= 2012
		local sd = r(sd)
		g `v'_std = `v' / `sd' * `sdD10xsh'
	}
	
	mat drop _all 
	local i = 0 
	foreach x of varlist D10xsh D10xrat D10xrat_std D10M D10M_std { 
		ivreghdfe S10.`y' (`x' = z) [aweight = weight], /// 
			abs($FE) clus(locid) 
		lincom `x', level(95)
		mat A = nullmat(A) \ (`i', r(estimate), r(lb), r(ub))   
		local ++i
	}

	mat colnames A = x b lb ub
	svmat A, names(col)
	count if !missing(x)
	local n = r(N) + 1
	replace x = 1 if _n == `n'
	g n = 0 if _n == `n'
	replace b = 0 if _n == `n'

	#delimit ; 
	twoway 
		(scatter x b if (x > 0 | x < 0) & missing(n), col(black)) 
		(scatter x b if !missing(n), col(none)) 
		(rcap lb ub x if (x > 0 | x < 0) & missing(n), horizontal lcol(black))
		(scatter x b if x == 0, col(black)) 
		(rcap lb ub x if x == 0, horizontal lcol(black)), 
		legend(off) xline(0, lc(black) lp(dash)) 
		xtitle("Estimated Effect") ytitle("")
		ylabel(	
			0 "Immigrant Share" 
			1 "Immigrant Rate" 
			2 "Immigrant Rate (std)" 
			3 "Immigrant Cont.to Pop.Growth"
			4 "Immigrant Cont.to Pop.Growth (std)"
			, 
		angle(0) labsize(large))
	; 
	#delimit cr
	graph export "$plots/`y'Robust_ImmMeasure.eps", replace 
	drop x b lb ub n
}

/*******************************************************************************
Robustness: How to measure immigration shocks dynamic
*******************************************************************************/
foreach y in y yWB2 {
	use "$data/AnalysisData.dta", clear 
	xtset locid year 
	
	su D10xsh if year >= 2012 
	local sdD10xsh = r(sd)
	foreach v of varlist D10xrat D10M L10D10xrat L10D10M { 
		su `v' if year >= 2012
		local sd = r(sd)
		g `v'_std = `v' / `sd' * `sdD10xsh'
	}
	
	mat drop _all 
	local i = 0 
	foreach x of varlist D10xsh D10xrat D10xrat_std D10M D10M_std { 
		ivreghdfe S10.`y' (`x' L10`x' = z L10z) [aweight = weight], /// 
			abs($FE) clus(locid) first ffirst
		mat FIRST = e(first) 	
		local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
		lincom `x', level(95)
		mat A = nullmat(A) \ (`i' - .15, 0, r(estimate), r(lb), r(ub), `weak')   
		lincom L10`x', level(95)
		mat A = nullmat(A) \ (`i' + .15, 1, r(estimate), r(lb), r(ub), `weak')   
		local ++i
	}

	mat colnames A = x g b lb ub weak
	svmat A, names(col)
	count if !missing(x)
	local n = r(N) + 1
	replace x = 1 if _n == `n'
	g n = 0 if _n == `n'
	replace b = 0 if _n == `n'

	#delimit ; 
	twoway 
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 0, col(black) ms("o"))
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 0, col(red) ms("o"))  
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 1, col(black) ms("X") msize(huge))
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 1, col(red) ms("X") msize(huge))  
		(scatter x b if !missing(n), col(none)) 
		(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 0, horizontal lcol(black))
		(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 1, horizontal lcol(red))
		(scatter x b if x == 0, col(black)) 
		(rcap lb ub x if x == 0, horizontal lcol(black)), 
		legend(pos(6) order(1 "Immigrant Share" 2 "Lagged Immigrant Share") cols(1)) 
		xline(0, lc(black) lp(dash)) 
		xtitle("Estimated Effect") ytitle("")
		ylabel(	
			0 "Immigrant Share" 
			1 "Immigrant Rate" 
			2 "Immigrant Rate (std)" 
			3 "Immigrant Cont.to Pop.Growth"
			4 "Immigrant Cont.to Pop.Growth (std)"
			, 
		angle(0) labsize(large))
	; 
	#delimit cr
	graph export "$plots/`y'Robust_ImmMeasureDyn.eps", replace 
	drop x b lb ub n weak 
}

/*******************************************************************************
Different Weights: Static
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 
g uno = 1

foreach y in y yWB2 { 
	mat drop _all 
	local i = 0 
	foreach x of varlist weight jweight uno { 

		ivreghdfe S10.`y' (D10xsh = z) [aweight = `x'], /// 
			abs($FE) clus(locid) 
		lincom D10xsh, level(95)
		mat A = nullmat(A) \ (`i', r(estimate), r(lb), r(ub))   
		local ++i
	}

	foreach x in G J { 
		ivreghdfe S10.`y' (D10xsh = z) [aweight = w10`x'], /// 
			abs($FE) clus(locid) 
		lincom D10xsh, level(95)
		mat A = nullmat(A) \ (`i', r(estimate), r(lb), r(ub))   
		local ++i
	}

	mat colnames A = x b lb ub
	svmat A, names(col)
	count if !missing(x)
	local n = r(N) + 1
	replace x = 1 if _n == `n'
	g n = 0 if _n == `n'
	replace b = 0 if _n == `n'

	#delimit ; 
	twoway 
		(scatter x b if (x > 0 | x < 0) & missing(n), col(black)) 
		(scatter x b if !missing(n), col(none)) 
		(rcap lb ub x if (x > 0 | x < 0) & missing(n), horizontal lcol(black))
		(scatter x b if x == 0, col(black)) 
		(rcap lb ub x if x == 0, horizontal lcol(black)), 
		legend(off) xline(0, lc(black) lp(dash)) 
		xtitle("Estimated Effect") ytitle("")
		ylabel(	0 "2002 GVA Weight" 
			1 "2002 Jobs Weight" 
			2 "Unweighted" 
			3 "GVA Weights a la Lewis (2003)" 
			4 "Job Weights a la Lewis (2003)" 
			, 
		angle(0) labsize(large))
	; 
	#delimit cr
	graph export "$plots/`y'Robust_Weights.eps", replace 
	drop x b lb ub n
}


/*******************************************************************************
Different Weights: Dynamic
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 
g uno = 1
			
foreach y in y yWB2 { 
	mat drop _all 
	local i = 0 
	foreach x of varlist weight jweight uno { 

		ivreghdfe S10.`y' (D10xsh L10D10xsh = z L10z) [aweight = `x'], /// 
			abs($FE) clus(locid) first ffirst
		mat FIRST = e(first) 	
		local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
		lincom D10xsh, level(95)
		mat A = nullmat(A) \ (`i' - .15, 0, r(estimate), r(lb), r(ub), `weak')   
		
		lincom L10D10xsh, level(95)
		mat A = nullmat(A) \ (`i' + .15, 1, r(estimate), r(lb), r(ub), `weak')   
		
		local ++i
	}

	foreach x in G J { 
		ivreghdfe S10.`y' (D10xsh L10D10xsh = z L10z) [aweight = w10`x'], /// 
			abs($FE) clus(locid) first ffirst
		mat FIRST = e(first) 	
		local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 

		lincom D10xsh, level(95)
		mat A = nullmat(A) \ (`i' - .15, 0, r(estimate), r(lb), r(ub), `weak')   
		
		lincom L10D10xsh, level(95)
		mat A = nullmat(A) \ (`i' + .15, 1, r(estimate), r(lb), r(ub), `weak')   
		
		local ++i
	}
	
	mat colnames A = x g b lb ub weak
	svmat A, names(col)
	count if !missing(x)
	local n = r(N) + 1
	replace x = 1 if _n == `n'
	g n = 0 if _n == `n'
	replace b = 0 if _n == `n'

	#delimit ; 
	twoway 
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 0, col(black) ms("o"))
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 0, col(red) ms("o"))  
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 1, col(black) ms("X") msize(huge))
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 1, col(red) ms("X") msize(huge))  
		(scatter x b if !missing(n), col(none)) 
		(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 0, horizontal lcol(black))
		(rcap lb ub x if (x > 0 | x < 0) & missing(n) & g == 1, horizontal lcol(red))
		(scatter x b if x == 0, col(black)) 
		(rcap lb ub x if x == 0, horizontal lcol(black)), 
		legend(pos(6) order(1 "Immigrant Share" 2 "Lagged Immigrant Share") cols(1)) 
		xline(0, lc(black) lp(dash)) 
		xtitle("Estimated Effect") ytitle("")
		ylabel(	
			0 "2002 GVA Weight" 
			1 "2002 Jobs Weight" 
			2 "Unweighted" 
			3 "GVA Weights a la Lewis (2003)" 
			4 "Job Weights a la Lewis (2003)" 
			, 
		angle(0) labsize(large))
	; 
	#delimit cr
	graph export "$plots/`y'Robust_WeightsDyn.eps", replace 
	drop x g b lb ub n weak
}

/*******************************************************************************
Different Instruments: Static
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

foreach y in y yWB2 { 
	mat drop _all
	
	/*
	Baseline Instrument
	*/
	local i = 1 
	foreach z in z zLFS zLFSEU {
		ivreghdfe S10.`y' (D10xsh = `z') [aweight = weight], /// 
				abs($FE) clus(locid) 
		lincom D10xsh, level(95)
		mat A = nullmat(A) \ (`i', r(estimate), r(lb), r(ub))   
		local ++i 
	}
			
	mat colnames A = x b lb ub
	svmat A, names(col)
	count if !missing(x)
	local n = r(N) + 1
	replace x = 1 if _n == `n'
	g n = 0 if _n == `n'
	replace b = 0 if _n == `n'

	#delimit ; 
	twoway 
		(scatter x b if missing(n), col(black)) 
		(scatter x b if !missing(n), col(none)) 
		(rcap lb ub x if missing(n), horizontal lcol(black)),
		legend(off) xline(0, lc(black) lp(dash)) 
		xtitle("Estimated Effect") ytitle("")
		ylabel(	
			1 "Baseline"
			2 "National Changes"
			3 "EU Enlargements"
			, 
		angle(0) labsize(large))
	; 
	#delimit cr
	graph export "$plots/`y'Robust_Instrument.eps", replace 
	drop x b lb ub n
}

/*******************************************************************************
Different Instruments: Dynamic
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

foreach y in y yWB2 { 
	mat drop _all
	
	/*
	Baseline Instrument
	*/
	local i = 1 
	foreach z in z zLFS zLFSEU {
		ivreghdfe S10.`y' (D10xsh L10D10xsh = `z' L10`z') [aweight = weight], /// 
				abs($FE) clus(locid) first ffirst
		mat FIRST = e(first) 	
		local weak = FIRST["SWF", 1] < 10 | FIRST["SWF", 2] < 10 | e(idp) > .1 
		lincom D10xsh, level(95)
		mat A = nullmat(A) \ (`i' - .15, 0, r(estimate), r(lb), r(ub), `weak')   
		lincom L10D10xsh, level(95)
		mat A = nullmat(A) \ (`i' + .15, 1, r(estimate), r(lb), r(ub), `weak')   
		local ++i 
	}
			
	mat colnames A = x g b lb ub weak
	svmat A, names(col)
	count if !missing(x)
	local n = r(N) + 1
	replace x = 1 if _n == `n'
	g n = 0 if _n == `n'
	replace b = 0 if _n == `n'

	#delimit ; 
	twoway 
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 0, col(black) ms("o"))
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 0, col(red) ms("o"))  
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 0 & weak == 1, col(black) ms("X") msize(huge))
		(scatter x b if (x > 0 | x < 0) & missing(n) & g == 1 & weak == 1, col(red) ms("X") msize(huge))  
		(scatter x b if !missing(n), col(none)) 
		(rcap lb ub x if missing(n) & g == 0, horizontal lcol(black))
		(rcap lb ub x if missing(n) & g == 1, horizontal lcol(red)),
		legend(pos(6) order(1 "Immigrant Share" 2 "Lagged Immigrant Share") cols(1)) 
		xline(0, lc(black) lp(dash)) 
		xtitle("Estimated Effect") ytitle("")
		ylabel(	
			1 "Baseline"
			2 "National Changes"
			3 "EU Enlargements"
			, 
		angle(0) labsize(large))
	; 
	#delimit cr
	graph export "$plots/`y'Robust_InstrumentDyn.eps", replace 
	drop x g b lb ub n weak
}

/*******************************************************************************
Saturated IV
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

g country = 1 if england 
replace country = 2 if scotland 
replace country = 3 if wales 

/*
Discretise instrument 
*/
xtile zGRP = z, n(5)

foreach y in y yWB2 { 
	/*
	Regresion without covariates 
	*/
	ivreg2 S10.`y'  (D10xsh = z) [aweight = weight], clust(locid) 
	est store `y'NC
	reg D10xsh z [aweight = weight], clust(locid) 
	ovtest 
	local ovtest = r(F)
	predict xb, xb 
	su xb
	local xbmin = r(min)
	local xbmax = r(max)
	est restore `y'NC
	estadd scalar xbmin = `xbmin'
	estadd scalar xbmax = `xbmax'
	estadd scalar ovtest = `ovtest'
	est store `y'NC
	drop xb

	/*
	Regression without covariates, instrument discretised 
	*/
	ivreg2 S10.`y'  (D10xsh = i.zGRP) [aweight = weight], clust(locid) 
	est store `y'NCGRP
	reg D10xsh i.zGRP [aweight = weight], clust(locid) 
	predict xb, xb 
	su xb
	local xbmin = r(min)
	local xbmax = r(max)
	est restore `y'NCGRP
	estadd scalar xbmin = `xbmin'
	estadd scalar xbmax = `xbmax'
	est store `y'NCGRP
	drop xb
	
	/*
	Regresion with year fixed effects and instrument discretised
	*/
	ivreg2 S10.`y'  (D10xsh = i.zGRP##i.year) /// 
		i.year [aweight = weight], ///
		clust(locid) 
	est store `y'NCGRPT
	reg D10xsh i.zGRP##i.year [aweight = weight], clust(locid) 
	predict xb, xb 
	su xb
	local xbmin = r(min)
	local xbmax = r(max)
	est restore `y'NCGRPT
	estadd scalar xbmin = `xbmin'
	estadd scalar xbmax = `xbmax'
	est store `y'NCGRPT
	drop xb
}

#delimit ;
estimates restore yNC;
distinct locid if e(sample);
local nregion = r(ndistinct);
local obs = r(N);
estout 	yNC yNCGRP yNCGRPT
		using "$tables/IVRich.tex", 
cells("b(star fmt(3))" "se( par fmt(3))") 
keep(D10xsh)
mlabels("(1)" "(2)" "(3)",)
varlabels(D10xsh "Immigrant Share")
collabels(,none)
prehead(\begin{tabularx}{\textwidth}{l*{3}{Y}}\toprule )
posthead(
	& \multicolumn{3}{c}{Instrument:} \\ 
	& Continuous
	& Discretised\$^\dagger\$  
	& Discretised\$^\dagger\$ \\ 
	& 				& 
	& with Interactions  \\ 
	\cmidrule(lr){2-4}
	\addlinespace
	& \multicolumn{3}{c}{\textit{A.} Labour Productivity} \\ 
	\addlinespace
	)
style(tex)
type
replace
starlevels(* 0.10 ** 0.05 *** .01)
; 

estout yWB2NC yWB2NCGRP yWB2NCGRPT 
		using "$tables/IVRich.tex", 
cells("b(star fmt(3))" "se( par fmt(3))") 
keep(D10xsh)
mlabels(,none)
varlabels(D10xsh "Immigrant Share")
collabels(,none)
posthead(
	\cmidrule(lr){2-4}
	\addlinespace
	& \multicolumn{3}{c}{\textit{B.} Labour Share} \\ 
	\addlinespace
	)
style(tex)
type
append
starlevels(* 0.10 ** 0.05 *** .01)
prefoot(\addlinespace \cmidrule(lr){2-4} )
stats(widstat, fmt(%9.3f) labels("F-Statistic"))
postfoot(
	Obs. & \multicolumn{3}{c}{`obs'} \\
	Regions & \multicolumn{3}{c}{`nregion'} \\
	\midrule
	& \multicolumn{3}{c}{Fixed Effects} \\ 
	Year  & No & No  & Yes \\ 
	\bottomrule \end{tabularx} 
	)
;
#delimit cr

/*******************************************************************************
Measurement Error
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
local mD = 0 
foreach y of varlis y lWB2 yWB2 { 
	ivreghdfe `y' (xsh = z) [aw = weight], abs(year locid)
	est store IV`y'
	local bIV = _b[xsh]
	ivreghdfe `y' xsh [aw = weight], abs(year locid)
	est store OLS`y'
	local bOLS = _b[xsh]
	local mD = `mD' + 1 - abs(`bOLS') / abs(`bIV') 
}
local mD = `mD' / 3 * 100
file open myfile using "$tables/AttenuationRelSize.tex", write replace
file write myfile %9.0f (`mD')
file close myfile

distinct locid 	
local nregion = string(r(ndistinct), "%12.0fc")
est restore IVy
local obs = string(e(N), "%12.0fc") 
#delimit ;
	estout 	OLSy OLSlWB2 OLSyWB2
			using "$tables/MainTableFE.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(xsh)
	mlabels("(1)" "(2)" "(3)",)
	varlabels(	
				xsh "Immigrant Share"
			)
	collabels(,none)
	type
	replace 
	style(tex)
	prehead(\begin{tabularx}{\textwidth}{l*{3}{Y}}\toprule )
	posthead( 	
			& Labour Productivity & Labour Cost & Labour Share \\ 
			\addlinespace
			\midrule
			& \multicolumn{3}{c}{\textit{A.} OLS} \\ 
			\addlinespace
			)
	starlevels(* 0.10 ** 0.05 *** .01)
	postfoot(\midrule)
	prefoot(\addlinespace)
;
#delimit ;
	estout 	IVy IVlWB2 IVyWB2
			using "$tables/MainTableFE.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(xsh )
	mlabels(,none)
	varlabels(	
				xsh  "Immigrant Share"
			)
	collabels(,none)
	type
	append 
	style(tex)
	posthead( 	
			& \multicolumn{3}{c}{\textit{B.} IV} \\ 
			\addlinespace
			)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
	postfoot(
		\addlinespace
		\midrule
		Obs. & \multicolumn{3}{c}{`obs'} \\
		Regions & \multicolumn{3}{c}{`nregion'} \\
		\bottomrule \end{tabularx}
		);
#delimit cr

qui reghdfe xsh [aw = weight], abs(year locid)
local R2 = e(r2)
file open myfile using "$tables/AuxR2.tex", write replace
file write myfile %9.3f (e(r2))
file close myfile

su xsh [aw = weight] 
local bpi = r(mean)
local spi = r(sd) ^ 2

distinct locid
local n = 320000 / r(ndistinct)

local atte = `bpi' * (1 - `bpi') / `n' / ((1 - `R2') * `spi') * 100 
file open myfile using "$tables/Attenuation.tex", write replace
file write myfile %9.0f (`atte')
file close myfile

file open myfile using "$tables/AttenuationExplain.tex", write replace
local exAT = `atte' / `mD' * 100 
file write myfile %9.0f (`exAT')
file close myfile

