/*******************************************************************************
Estimates with AKM standard errors
*******************************************************************************/
foreach v in yWB2 y lWB2 { 
	qui use "$data/AnalysisData.dta", clear 
	qui merge 1:1 itl321cd year using "$data/shares.dta"
	qui keep if _merge == 3 
	qui drop _merge 

	qui xtset locid year
	qui g D10`v' = S10.`v'
	qui keep if !missing(D10`v')    
	qui tab year, gen(yearG)
	
	qui ivreghdfe D10`v' (D10xsh = z) /// 
		yearG2-yearG4 [aw = weight], clust(locid) first ffirst
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]
	
	qui ivreg_ss D10`v', endogenous_var(D10xsh) shiftshare_iv(z) /// 
		control_varlist(yearG2-yearG4) /// 
		share_varlist(sh*) weight_var(weight) firststage(1)
	estadd scalar SWF1 = `SWF1'
	est store `v'_BASE
}
foreach v in yWB2 y lWB2 { 
	qui use "$data/AnalysisData.dta", clear 
	qui merge 1:1 itl321cd year using "$data/shares.dta"
	qui keep if _merge == 3 
	qui drop _merge 

	qui xtset locid year
	qui g D10`v' = S10.`v'
	qui keep if !missing(D10`v')    
	qui tab year, gen(yearG)

	qui ivreghdfe D10`v' (D10xsh = z) /// 
		yearG2-yearG4 L10z [aw = weight], clust(locid) first ffirst
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]

	qui ivreg_ss D10`v', endogenous_var(D10xsh) shiftshare_iv(z) /// 
		control_varlist(yearG2-yearG4 L10z) /// 
		share_varlist(sh*) weight_var(weight) firststage(1)
	estadd scalar SWF1 = `SWF1'
	est store `v'_COND
}

qui use "$data/AnalysisData.dta", clear 
distinct locid 	
local nregion = string(r(ndistinct), "%12.0fc")
est restore y_BASE
local obs = string(e(N), "%12.0fc") 
local p1st_BASE = string(real(e(p_firststage)), "%020.3fc") 
local f_BASE = string(e(SWF1), "%020.3fc") 
est restore y_COND
local p1st_COND = string(real(e(p_firststage)), "%020.3fc") 
local f_COND = string(e(SWF1), "%020.3fc") 
#delimit ;
	estout 	y_BASE lWB2_BASE yWB2_BASE 
			using "$tables/AKM.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh)
	mlabels("(1)" "(2)" "(3)",)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
			)
	collabels(,none)
	type
	replace 
	style(tex)
	prehead(\begin{tabularx}{\textwidth}{l*{3}{Y}}\toprule ) 
	posthead( 	& Productivity & Labour Cost & Labour Share \\ 
			\midrule
			\addlinespace
			\multicolumn{4}{l}{\textbf{A. Baseline}} \\ 
	)
	starlevels(* 0.10 ** 0.05 *** .01)
	postfoot(
		P-value 1\$^{st}\$-Stage & \multicolumn{3}{c}{`p1st_BASE'} \\ 
		F-stat & \multicolumn{3}{c}{`f_BASE'} \\ 
		\midrule)
	prefoot(\addlinespace)
;
#delimit ;
	estout 	y_COND lWB2_COND yWB2_COND
			using "$tables/AKM.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh)
	mlabels(,none)
	varlabels(	
			D10xsh  "$\Delta$ Immigrant Share"
		)
	collabels(,none)
	type
	append 
	style(tex)
	posthead(\multicolumn{4}{l}{\textbf{B. Conditional on Lagged Instrument}} \\ )
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
	postfoot(
		P-value 1\$^{st}\$-Stage & \multicolumn{3}{c}{`p1st_COND'} \\
		F-stat & \multicolumn{3}{c}{`f_COND'} \\ 
		\addlinespace
		\midrule
		Obs. & \multicolumn{3}{c}{`obs'} \\
		Regions & \multicolumn{3}{c}{`nregion'} \\
		\bottomrule \end{tabularx}
	);
#delimit cr
