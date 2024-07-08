/*******************************************************************************
Employment outcomes  
*******************************************************************************/	
use "$data/AnalysisData.dta", clear 
xtset locid year 
g lnN = log(N)
g D10J = S10.jobs / L10.jobs

foreach y of varlist lnJ lnN { 
	/*IV*/
	ivreghdfe S10.`y' (D10xsh = z)  [pweight = weight], /// 
		abs($FE) clus(locid) first ffirst 
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]
	estadd scalar SWF1 = `SWF1'
	est store IV`y'_stat
	

	ivreghdfe S10.`y' (D10xsh L10D10xsh = z L10z)  [pweight = weight], /// 
		abs($FE) clus(locid) first ffirst 
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]
	local SWF2 = FIRST["SWF", 2]
	estadd scalar SWF1 = `SWF1'
	estadd scalar SWF2 = `SWF2'
	est store IV`y'_dyn
}

foreach y of varlist D10J D10N { 
	/*IV*/
	ivreghdfe `y' (D10M = z)  [pweight = weight] if year >= 2012, /// 
		abs($FE) clus(locid) first ffirst 
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]
	estadd scalar SWF1 = `SWF1'
	est store IV`y'_stat

	ivreghdfe `y' (D10M L10D10M = z L10z)  [pweight = weight] if year >= 2012, /// 
		abs($FE) clus(locid) first ffirst 
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]
	local SWF2 = FIRST["SWF", 2]
	estadd scalar SWF1 = `SWF1'
	estadd scalar SWF2 = `SWF2'
	est store IV`y'_dyn
}

#delimit ;
estimates restore IVlnJ_dyn;
distinct locid if e(sample);
local nregion = r(ndistinct);
local obs = r(N);
estout 	IVlnJ_stat IVlnN_stat IVlnJ_dyn IVlnN_dyn
		using "$tables/JobsGrowth.tex", 
cells("b(star fmt(3))" "se( par fmt(3))") 
keep(D10xsh L10D10xsh)
mlabels(,none)
varlabels(
		D10xsh "$\Delta$ Immigrant Share"
		L10D10xsh "Lag $\Delta$ Immigrant Share")
collabels(,none)
prehead(\begin{tabularx}{\textwidth}{l*{4}{Y}}\toprule 
	& (1) & (2) & (3) & (4) \\ 
	\midrule
	& \$\Delta log(jobs_{rt})\$ & \$\Delta log(N_{rt})\$ 
	& \$\Delta log(jobs_{rt})\$ & \$\Delta log(N_{rt})\$  \\
	\addlinespace
	)
style(tex)
type
replace
starlevels(* 0.10 ** 0.05 *** .01)
stats(SWF1 SWF2, fmt(%9.3fc) label("\addlinespace F-stat (current)" "F-stat (lagged)"))
;
#delimit cr
#delimit ; 
estout 	IVD10J_stat IVD10N_stat IVD10J_dyn IVD10N_dyn
		using "$tables/JobsGrowth.tex", 
cells("b(star fmt(3))" "se( par fmt(3))") 
keep(D10M L10D10M)
mlabels(,none)
varlabels(
		D10M "$\dfrac{\Delta M_{rt}}{N_{rt-10} + M_{rt-10}}$"
		L10D10M "\$\dfrac{\Delta M_{rt - 10}}{N_{rt-20} + M_{rt-20}}\$")
collabels(,none)
prehead(
	\midrule
	& \$ \dfrac{\Delta jobs_{rt}}{jobs_{rt - 10}} \$ & \$\dfrac{\Delta N_{rt}}{N_{rt - 10}}\$ 
	& \$ \dfrac{\Delta jobs_{rt}}{jobs_{rt - 10}} \$ & \$\dfrac{\Delta N_{rt}}{N_{rt - 10}}\$ \\ 
	\addlinespace
	)
style(tex)
type
append
starlevels(* 0.10 ** 0.05 *** .01)
stats(SWF1 SWF2, fmt(%9.3fc) label("\addlinespace F-stat (current)" "F-stat (lagged)"))
postfoot(
	\midrule
	Obs. & \multicolumn{4}{c}{`obs'} \\
	Regions & \multicolumn{4}{c}{`nregion'} \\
	\bottomrule
	\end{tabularx}
	)
;
#delimit cr
