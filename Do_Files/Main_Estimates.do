use "$data/AnalysisData.dta", clear 
xtset locid year 

foreach z in "" "LFS" { 
	/*******************************************************************************
	Balance of Conditional Instrument: 
	*******************************************************************************/
	foreach y of varlist $BX { 
		reghdfe `y' z`z' [aweight = weight] if year >= 2012, /// 
				abs($FE) clus(locid)
		est store `y'_stat
		
		reghdfe `y' z`z' L10z`z' [aweight = weight] if year >= 2012, /// 
				abs($FE) clus(locid)
		est store `y'_dyn
	}

	distinct locid 	
	local nregion = string(r(ndistinct), "%12.0fc")
	est restore L10D10emp_stat
	local obs = string(e(N), "%12.0fc") 
	#delimit ;
	estout 	L10D10popL_stat L10D10emp_stat L10D10empdens_stat D10zEmp_stat L10D10zEmp_stat L10D10xsh_stat
			using "$tables/BalanceCondIV`z'.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(z`z')
	mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)",)
	varlabels(	
				z`z'  "Instrument"
			)
	collabels(,none)
	type
	replace 
	style(tex)
	prehead(\begin{tabularx}{1.25\textwidth}{l*{6}{Y}}\toprule )
	posthead( 	
				& Lagged \$\Delta\$ log-Wrk.Age Pop
				& Lagged \$\Delta\$ log-Emp
				& Lagged \$\Delta\$ log-Emp Rate
				& Bartik Industry Shock 
				& Lagged Bartik Industry Shock 
				& Lagged \$\Delta\$ Immigrant Share \\ 
				\cmidrule(lr){2-7}
				& \multicolumn{6}{c}{Unconditional} \\ 
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
	;
	#delimit ;
	estout 	L10D10popL_dyn L10D10emp_dyn L10D10empdens_dyn D10zEmp_dyn L10D10zEmp_dyn L10D10xsh_dyn 
			using "$tables/BalanceCondIV`z'.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(z`z' L10z`z')
	mlabels(,none)
	varlabels(	
				z`z' "Instrument"
				L10z`z' "Lagged Instrument"
			)
	collabels(,none)
	type
	append 
	style(tex)
	posthead( 	\midrule 
				& \multicolumn{6}{c}{Conditional on Lagged Instrument} \\ 
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	postfoot(
		\addlinespace
		\midrule
		Obs. & \multicolumn{6}{c}{`obs'} \\
		Regions & \multicolumn{6}{c}{`nregion'} \\
		\bottomrule \end{tabularx}
		);
	#delimit cr		

	/*******************************************************************************
	Balance Using Jaeger, Ruist and Stuhler (2019)
	*******************************************************************************/		
	local den = 0
	local num = 0 
	foreach y in $BX { 
		ivreghdfe `y' (D10xsh = z`z') [aweight = weight] if year >= 2012, /// 
			abs($FE) clus(locid) 
		est store `y'_stat
		local b0 = abs(_b[D10xsh])
		
		if("`y'" == "L10D10xsh") continue 
		ivreghdfe `y' (D10xsh L10D10xsh = z`z' L10z`z') [aweight = weight] if year >= 2012, /// 
			abs($FE) clus(locid) 
		est store `y'_dyn 
		local num = `num' + (1 - abs(_b[D10xsh]) / `b0')
		local ++den
	}	
	/*
	Average % reduction in pre-trends point estimates 
	*/
	local pred = string(`num' / `den' * 100, "%12.0fc")
	if("`z'" == "") { 
		file open myfile using "$tables/PreTrendReduction.text", write replace
		file write myfile %12.0fc (`pred')
		file close myfile
	}

	/*
	Produce table 
	*/
	distinct locid 	
	local nregion = string(r(ndistinct), "%12.0fc")
	est restore L10D10emp_stat
	local obs = string(e(N), "%12.0fc") 
	#delimit ;
	estout 	L10D10popL_stat L10D10emp_stat L10D10empdens_stat D10zEmp_stat L10D10zEmp_stat L10D10xsh_stat
			using "$tables/BalanceIV`z'.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh )
	mlabels("(1)" "(2)" "(3)" "(4)" "(5)" "(6)",)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
			)
	collabels(,none)
	type
	replace 
	style(tex)
	prehead(\begin{tabularx}{1.32\textwidth}{l*{6}{Y}}\toprule )
	posthead( 	
				& Lagged \$\Delta\$ log-Wrk.Age Pop
				& Lagged \$\Delta\$ log-Emp
				& Lagged \$\Delta\$ log-Emp Rate
				& Bartik Industry Shock 
				& Lagged Bartik Industry Shock 
				& Lagged \$\Delta\$ Immigrant Share \\ 
				\cmidrule(lr){2-7}
				& \multicolumn{6}{c}{Static} \\ 
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace)
	;
	#delimit ;
	estout 	L10D10popL_dyn L10D10emp_dyn L10D10empdens_dyn D10zEmp_dyn L10D10zEmp_dyn 
			using "$tables/BalanceIV`z'.tex", 
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
				& \multicolumn{6}{c}{Dynamic} \\ 
				\addlinespace
				)
	starlevels(* 0.10 ** 0.05 *** .01)
	postfoot(
		\addlinespace
		\midrule
		Obs. & \multicolumn{6}{c}{`obs'} \\
		Regions & \multicolumn{6}{c}{`nregion'} \\
		\bottomrule \end{tabularx}
		);
	#delimit cr

	/*******************************************************************************
	First-stage estimates
	*******************************************************************************/
	est clear 

	ivreghdfe S10.yWB2 (D10xsh = z`z') /// 
		[pw = weight] if year >= 2012, /// 
		abs($FE) clus(locid) first ffirst savefirst 
	distinct locid 
	local nregion = string(r(ndistinct), "%12.0fc")
	local obs = string(e(N), "%12.0fc") 
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]
	est restore _ivreg2_D10xsh
	estadd scalar SWF = `SWF1'
	est store c1

	ivreghdfe S10.yWB2 (D10xsh L10D10xsh = z`z' L10z`z') /// 
		[pw = weight] if year >= 2012, /// 
		abs($FE) clus(locid) first ffirst savefirst 
	local rk2 = string(e(idstat), "%9.3f")
	local rk2_p = "[" + string(e(idp), "%9.3f") + "]"
	mat FIRST = e(first) 	
	local SWF1 = FIRST["SWF", 1]
	local SWF2 = FIRST["SWF", 2]

	est restore _ivreg2_D10xsh
	estadd scalar SWF = `SWF1'
	est store c2

	est restore _ivreg2_L10D10xsh
	estadd scalar SWF = `SWF2'
	est store c3

	#delimit ;
	estout 	c1 c2 c3 
			using "$tables/First_Stage`z'.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(z`z' L10z`z')
	mlabels("(1)" "(2)" "(3)",)
	varlabels(	
				z`z' "Immigrant Instrument"
				L10z`z' "Lagged Immigrant Instrument"
			)
	collabels(,none)
	type
	replace 
	style(tex)
	prehead(\begin{tabularx}{\textwidth}{l*{3}{Y}}\toprule )
	posthead( 	& $\Delta$ Immigrant Share 
				& $\Delta$ Immigrant Share 
				& Lagged $\Delta$ Immigrant Share \\
				\cmidrule(lr){2-4})
	starlevels(* 0.10 ** 0.05 *** .01)
	prefoot(\addlinespace \cmidrule(lr){2-4} )
	stats(SWF, fmt(%9.3f) label("F-stat (excluded instruments)") )
	postfoot(
		rk LM & & \multicolumn{2}{c}{`rk2'} \\
		rk LM: p-value &  & \multicolumn{2}{c}{`rk2_p'} \\
		Obs. & \multicolumn{3}{c}{`obs'} \\
		Regions & \multicolumn{3}{c}{`nregion'} \\
		\bottomrule \end{tabularx}
		);
	#delimit cr

	/*******************************************************************************
	Main estimates a la Jaeger, Ruist and Stuhler (2019)
	*******************************************************************************/
	foreach y in y lWB2 yWB2 { 
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
		
		/*
		Print average effects for dynamic specifcation, 
		recall that variables have been scaled to be in thousands 
		*/
		local b = _b[D10xsh]
		g tmp = exp(`y')
		su tmp [aw = weight], mean 
		local ev =  string(r(mean) * `b' * 10, "%12.0fc")
		if("`z'" == "") { 
			file open myfile using "$tables/EAtAvg`y'.text", write replace
			file write myfile %12.0fc ("`ev'")
			file close myfile
			
			local b = string(abs(`b'), "%9.3f")
			file open myfile using "$tables/BETA`y'.text", write replace
			file write myfile %9.3f ("`b'")
			file close myfile
		}
		cap drop tmp 
		
		if("`z'" == "" & "`y'" == "y") { 
			/*
			Estimate overlap with (Ottaviano, Peri and Wright, 2018)
			*/
			local OPWdf = 80235 - 4 
			local OPWb = 3.09
			local OPWstde = 1.77 
			local OPWcilow = `OPWb' - `OPWstde' * invt(`OPWdf', 0.975)
			local OPWciup = `OPWb' + `OPWstde' * invt(`OPWdf', 0.975)
			lincom D10xsh
			local cilow = r(lb)
			local ciup = r(ub)
			local pcont = (min(`ciup', `OPWciup') - max(`cilow', `OPWcilow')) / (`ciup' - `cilow') * 100 
			local pcont = string(`pcont', "%12.0fc")
			file open myfile using "$tables/OPWcont.text", write replace
			file write myfile %12.0fc ("`pcont'")
			file close myfile
				
			/*
			Comparison with Peri (2012) 
			*/
			ivreghdfe S10.`y' (D10M L10D10M = z`z' L10z`z') /// 
				[pw = weight] if year >= 2012, /// 
				abs($FE) clus(locid) 
			local stde = e(V)[1,1]
			local stde = string(sqrt(`stde'), "%9.3f")
			local b = string(_b[D10M], "%9.3f")
			file open myfile using "$tables/BD10My.text", write replace
			file write myfile %9.3f ("`b'")
			file close myfile
			file open myfile using "$tables/StdD10My.text", write replace
			file write myfile %9.3f ("`stde'")
			file close myfile
			
			ivreghdfe S10.`y' (D10M = z`z') /// 
				[pw = weight] if year >= 2012, /// 
				abs($FE) clus(locid) 
			local stde = e(V)[1,1]
			local stde = string(sqrt(`stde'), "%9.3f")
			local b = string(_b[D10M], "%9.3f")
			file open myfile using "$tables/BD10MyStat.text", write replace
			file write myfile %9.3f ("`b'")
			file close myfile
			file open myfile using "$tables/StdD10MyStat.text", write replace
			file write myfile %9.3f ("`stde'")
			file close myfile
			
			local P12df = 204 - 1
			local P12b = 0.22
			local P12stde = 0.27 
			local P12cilow = `P12b' - `P12stde' * invt(`P12df', 0.975)
			local P12ciup = `P12b' + `P12stde' * invt(`P12df', 0.975)
			lincom D10M
			local cilow = r(lb)
			local ciup = r(ub)
			local pcont = (min(`ciup', `P12ciup') - max(`cilow', `P12cilow')) / (`ciup' - `cilow') * 100 
			local pcont = string(`pcont', "%12.0fc")
			file open myfile using "$tables/P12cont.text", write replace
			file write myfile %12.0fc ("`pcont'")
			file close myfile
			
		}
		
		reghdfe S10.`y' D10xsh L10D10xsh /// 
			[pw = weight] if year >= 2012, /// 
			abs($FE) clus(locid)  
		est store OLS`y'_dyn
		
	}

	distinct locid 	
	local nregion = string(r(ndistinct), "%12.0fc")
	est restore OLSy_stat
	local obs = string(e(N), "%12.0fc") 
	#delimit ;
	estout 	OLSy_stat IVy_stat OLSy_dyn IVy_dyn
			using "$tables/MainTable`z'.tex", 
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
	estout 	OLSlWB2_stat IVlWB2_stat OLSlWB2_dyn IVlWB2_dyn
			using "$tables/MainTable`z'.tex", 
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
	estout 	OLSyWB2_stat IVyWB2_stat OLSyWB2_dyn IVyWB2_dyn
			using "$tables/MainTable`z'.tex", 
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
	Main estimates conditional on lagged instrument
	*******************************************************************************/
	foreach y in y lWB2 yWB2 { 
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
		ivreghdfe S10.`y' (D10xsh = z`z') L10z`z' /// 
			[pw = weight] if year >= 2012, /// 
			abs($FE) clus(locid) endog(D10xsh) first ffirst savefirst 
		est store IV`y'_dyn
			
		reghdfe S10.`y' D10xsh L10D10xsh /// 
			[pw = weight] if year >= 2012, /// 
			abs($FE) clus(locid)  
		est store OLS`y'_dyn
	}

	distinct locid 	
	local nregion = string(r(ndistinct), "%12.0fc")
	est restore OLSy_stat
	local obs = string(e(N), "%12.0fc") 
	#delimit ;
	estout 	OLSy_stat IVy_stat OLSy_dyn IVy_dyn
			using "$tables/MainTableCond`z'.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh L10z`z')
	mlabels("(1)" "(2)" "(3)" "(4)",)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
				L10z`z' "Lagged Immigrant Instrument"
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
	estout 	OLSlWB2_stat IVlWB2_stat OLSlWB2_dyn IVlWB2_dyn
			using "$tables/MainTableCond`z'.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh L10z`z')
	mlabels(,none)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
				L10z`z' "Lagged Immigrant Instrument"
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
	estout 	OLSyWB2_stat IVyWB2_stat OLSyWB2_dyn IVyWB2_dyn
			using "$tables/MainTableCond`z'.tex", 
	cells("b(star fmt(3))" "se( par fmt(3))") 
	keep(D10xsh L10z`z')
	mlabels(,none)
	varlabels(	
				D10xsh  "$\Delta$ Immigrant Share"
				L10z`z' "Lagged Immigrant Instrument"
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
}