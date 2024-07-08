use "$data/AnalysisData.dta", clear 
xtset locid year

foreach y of varlist occsh* {
	ivreghdfe S10.`y' (D10xsh = z) [pweight = weight] if year >= 2012, /// 
					abs($FE) clus(locid)
	est store `y'_stat
	
	ivreghdfe S10.`y' (D10xsh L10D10xsh = z L10z) [pweight = weight] if year >= 2012, /// 
					abs($FE) clus(locid)
	est store `y'_dyn
}

est restore occsh1_stat
distinct locid if e(sample)
local nregion = string(r(ndistinct), "%12.0fc")
local obs = string(e(N), "%12.0fc")
#delimit ;
estout 	occsh1_stat occsh2_stat occsh3_stat occsh4_stat
		occsh5_stat 
			using "$tables/Occupations.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh)
	mlabels("(1)" "(2)" "(3)" "(4)" "(5)",)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
			)
	collabels(,none)
	type
	replace 
	style(tex)
	prehead(\begin{tabularx}{1.32\textwidth}{l*{5}{Y}}\toprule )
	posthead( 	
				\addlinespace
				\midrule 
				& \multicolumn{5}{c}{Static} \\ 
				\addlinespace
				& Managers
				& Professional 
				& Associate
				& Administrative
				& Skilled \\ 
				\addlinespace
			)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
;
#delimit ;
estout 	occsh6_stat occsh7_stat occsh8_stat
		occsh9_stat
			using "$tables/Occupations.tex", 

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
	posthead(	& Caring
				& Sales
				& Process
				& Elementary \\
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
;
#delimit cr
#delimit ;
estout 	occsh1_dyn occsh2_dyn occsh3_dyn occsh4_dyn
		occsh5_dyn
			using "$tables/Occupations.tex", 

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
	posthead( 	\midrule
				& \multicolumn{5}{c}{Dynamic} \\ 
				\addlinespace
				& Managers
				& Professional 
				& Associate
				& Administrative
				& Skilled \\
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
;
#delimit cr
#delimit ;
estout 	occsh6_dyn occsh7_dyn occsh8_dyn occsh9_dyn
			using "$tables/Occupations.tex", 

	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh L10D10xsh)
	mlabels(,none)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
				L10D10xsh "Lagged $\Delta$ Immigrant Share"
			)
	collabels(,none)
	posthead(	& Caring
				& Sales
				& Process
				& Elementary \\
				\addlinespace
			)
	type
	append 
	style(tex)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
	postfoot(
		\addlinespace
		\midrule
		Obs. 	& \multicolumn{5}{c}{`obs'} \\
		Regions & \multicolumn{5}{c}{`nregion'} \\
		\bottomrule \end{tabularx}
		);
#delimit cr


