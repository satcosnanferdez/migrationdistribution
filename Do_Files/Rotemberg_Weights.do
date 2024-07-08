/*******************************************************************************
This script produces the decomposition introduced by 
Goldsmith-Pinkham et al (2020)
*******************************************************************************/
/*
Exposure 
*/
use normexp itl321cd iso2c using "$data/Exposure.dta", clear 
expand 25
bys iso2c itl321cd: g year = 1990 + _n 

/*
ONS Stocks
*/
merge m:1 year iso2c using "$data/MShocks.dta"
count if _merge != 3 
if(r(N) > 0) { 
	disp as error "Shocks and exposure not matched"
	exit 101 
}
drop _merge 



/*
Aggregated data 
*/
merge m:1 itl321cd year using "$data/AnalysisData.dta", ///
	keepusing(y yWB2 D10xsh z weight)
keep if _merge == 3 
drop _merge 

egen id = group(itl321cd iso2c)
xtset id year 
foreach v in y yWB2 { 
	g D`v' = S10.`v' 
	drop `v' 
}
keep if !missing(Dy)
drop id 

tab year, gen(tYear)
drop tYear1 

global x D10xsh 
global z z
global controls tYear*

reshape wide D10popUN@ normexp@, i(itl321cd year) j(iso2c, s)

reg normexpPL normexpRO [aw = weight]
capture file close fh
file open fh  using "$tables/PLcorrRO.tex", write replace
mat cor = r(C)
local cor = string(_b[normexpRO], "%9.3f")
file write fh "`cor'" _n
file close fh

capture file close fh
file open fh  using "$tables/PLcorrROR2.tex", write replace
mat cor = r(C)
local cor = string(e(r2), "%9.3f")
file write fh "`cor'" _n
file close fh

/*
Drop if shocks / growht is always zero: 
*/
foreach v of varlist D10popUN* { 
	su `v' 
	local max = r(max)
	local min = r(min) 
	if(regexm("`v'", "D10popUN(.+)") & `min' == 0 & `max' == 0) { 
		local bpc = regexs(1)
		drop `v' normexp`bpc'
	}
}

levelsof year, local(yearSet) 
foreach t in `yearSet' {
	foreach var of varlist normexp* {
		gen t`t'_`var' = (year == `t') * `var'
	}
	foreach var of varlist D10popUN* {
		gen t`t'_`var'b = `var' if year == `t'
		egen t`t'_`var' = max(t`t'_`var'b), by(itl321cd)
		drop t`t'_`var'b
	}
}

/*
Rotemberg weights decomposition generate estimates for both productivity 
and labour share 
*/ 
bartik_weight, z(t*_normexp*) weightstub(t*_D10popUN*) x($x) y(Dy) /// 
	controls($controls) weight_var(weight)	
mat betaDy = r(beta)
mat alphaDy = r(alpha)
mat GDy = r(G)

bartik_weight, z(t*_normexp*) weightstub(t*_D10popUN*) x($x) y(DyWB2) /// 
	controls($controls) weight_var(weight)
mat betaDyWB2 = r(beta)
mat alpha = r(alpha)
mat G = r(G)

preserve 
foreach m in G alpha { 
	mat tmp = `m' - `m'Dy
	svmat tmp
	qui count if tmp1 != 0 & !missing(tmp1)
	if(r(N)) { 
		disp as error "Differences between matrices `m'"
		exit() 
	}
	clear 
}
restore 

qui desc t*_normexp*, varlist
global varlist = r(varlist)

/*
Save macros with statistics 
*/
foreach var of varlist normexp* {
	if regexm("`var'", "normexp(.*)") {
		local iso2c = regexs(1) 
	}
	tempvar temp
	qui gen `temp' = `var' * D10popUN`iso2c'
	qui regress $x `temp' $controls [aweight = weight], cluster(itl321cd)
	qui test `temp'
	local F_`iso2c' = r(F)
	drop `temp'
}

foreach lhs in Dy DyWB2 { 
	foreach var of varlist normexp* {
		if regexm("`var'", "normexp(.*)") {
			local iso2c = regexs(1) 
		}
		tempvar temp
		qui gen `temp' = `var' * D10popUN`iso2c'
		ch_weak, p(.05) beta_range(-10(.1)10)  y(`lhs') x($x) z(`temp')  /// 
			weight(weight) controls($controls) cluster(itl321cd)
		disp r(beta_min) ,  r(beta_max)
		local ci_min`lhs'_`iso2c' =string( r(beta_min), "%9.2f")
		local ci_max`lhs'_`iso2c' = string( r(beta_max), "%9.2f")
		drop `temp'
	}
}

preserve
	keep normexp* itl321cd year weight
	reshape long normexp@, i(itl321cd year) j(iso2c, s)
	gen normexppop = normexp * weight
	collapse (sd) normexpsd = normexp (rawsum) normexppop weight /// 
		[aweight = weight], by(iso2c year)
	tempfile tmp
	save `tmp'
restore

/*******************************************************************************
Save Bartik weight estimates 
*******************************************************************************/
clear
svmat betaDyWB2
svmat betaDy
svmat alpha
svmat G

/*
Identify year and country-of-birth for each estimate 
*/
gen iso2c = ""
gen year = ""
local t = 1
foreach var in $varlist {
	if regexm("`var'", "t(.*)_normexp*(.*)") {
		qui replace year = regexs(1) if _n == `t'
		qui replace iso2c = regexs(2) if _n == `t'
	}
	local t = `t' + 1
}
gsort -alpha1

destring year, replace

merge 1:1 iso2c year using `tmp'
keep if _merge == 3 
drop _merge 

/*******************************************************************************
Produce statistics to be exported 
*******************************************************************************/

/***************************************** 
Calculate Panel C: Variation across years in alpha *
******************************************/ 
levelsof year, local(yearSet) 
foreach y in `yearSet' { 
	total alpha1 if year == `y'
	mat b = e(b)
	local sum_`y'_alpha = string(b[1,1], "%9.3f")
	
	sum alpha1 if year == `y'
	local mean_`y'_alpha = string(r(mean), "%9.3f")
}

/***********************************************
Aggregate across years 
************************************************/
gen betaDy2 = alpha1 * betaDy1
gen betaDyWB22 = alpha1 * betaDyWB21
gen iso2cshare2 = alpha1 * (normexppop / weight)
gen iso2cshare_sd2 = alpha1 * normexpsd
gen G2 = alpha1 * G1

collapse (sum) alpha1 betaDy2 betaDyWB22 iso2cshare2 iso2cshare_sd2 G2 (mean) G1, by(iso2c)

gen agg_betaDy = betaDy2 / alpha1
gen agg_betaDyWB2 = betaDyWB22 / alpha1
gen agg_iso2cshare = iso2cshare2 / alpha1
gen agg_iso2cshare_sd = iso2cshare_sd2 / alpha1
gen agg_g = G2 / alpha1

gsort -alpha1

/***************************************** 
Panel A: Negative and Positive Weights 
*****************************************/
total alpha1 if alpha1 > 0
mat b = e(b)
local sum_pos_alpha = string(b[1,1], "%9.3f")
total alpha1 if alpha1 < 0
mat b = e(b)
local sum_neg_alpha = string(b[1,1], "%9.3f")

sum alpha1 if alpha1 > 0
local mean_pos_alpha = string(r(mean), "%9.3f")
sum alpha1 if alpha1 < 0
local mean_neg_alpha = string(r(mean), "%9.3f")

local share_pos_alpha = string(abs(`sum_pos_alpha')/(abs(`sum_pos_alpha') + ///	
	abs(`sum_neg_alpha')), "%9.3f")
local share_neg_alpha = string(abs(`sum_neg_alpha')/(abs(`sum_pos_alpha') + /// 
	abs(`sum_neg_alpha')), "%9.3f")
	

/***************************************** 
Panel B: Correlations of Country of Birth Aggregates 
******************************************/ 
gen F = .
levelsof iso2c, local(bplcs)
foreach iso2c in `bplcs' {
	capture replace F = `F_`iso2c'' if iso2c == "`iso2c'"
}

foreach v1 in alpha1 agg_g agg_betaDy agg_betaDyWB2 F agg_iso2cshare_sd { 
	if(regexm("`v1'", "_*([^_]+)$")) { 
		local l = regexs(1)
	}
	foreach v2 in alpha1 agg_g agg_betaDy agg_betaDyWB2 F agg_iso2cshare_sd { 
		if(regexm("`v2'", "_*([^_]+)$")) { 
			local r = regexs(1)
		}
		corr `v1' `v2'
		mat Mcorr = r(C)
		local `l'_`r' = string(Mcorr[1, 2], "%9.3f")
	}
}

/***************************************** 
 Panel  D: Top 5 Rotemberg Weight Inudstries 
******************************************/
kountry iso2c, from(iso2c) 
replace NAMES_STD = iso2c if iso2c == "Other"
local iso2cTOP5 = ""
forvalue i = 1 / 5 {
	gsort -alpha1	
	local iso2c = iso2c[`i']
	local iso2cTOP5 = "`iso2cTOP5' `iso2c'"
	qui sum alpha1 if iso2c == "`iso2c'"
	local alpha_`iso2c' = string(r(mean), "%9.3f")
	
	qui sum agg_g if iso2c == "`iso2c'"	
	local g_`iso2c' = string(r(mean) * 1e-3, "%9.3f")
	
	qui sum agg_betaDy if iso2c == "`iso2c'"	
	local betaDy_`iso2c' = string(r(mean), "%9.3f")
	
	qui sum agg_betaDyWB2 if iso2c == "`iso2c'"	
	local betaDyWB2_`iso2c' = string(r(mean), "%9.3f")
	
	tempvar temp
	qui gen `temp' = iso2c == "`iso2c'"
	gsort -`temp'
	local iso2c_name_`iso2c' = NAMES_STD[1]
	
	drop `temp'
}

/***************************************** 
Panel E: Weighted Betas by alpha weights
******************************************/
gen agg_betaDy_weight = agg_betaDy * alpha1
gen agg_betaDyWB2_weight = agg_betaDyWB2 * alpha1

gen positive_weight = alpha1 > 0

collapse (sum) agg_betaDy_weight agg_betaDyWB2_weight alpha1 /// 
	(mean) agg_betaDy agg_betaDyWB2, by(positive_weight)

foreach lhs in Dy DyWB2 { 
	egen total_agg_beta`lhs' = total(agg_beta`lhs'_weight)
	gen share = agg_beta`lhs'_weight / total_agg_beta`lhs'

	gsort -positive_weight
	local agg_beta`lhs'_pos = string(agg_beta`lhs'_weight[1], "%9.3f")
	local agg_beta`lhs'_neg = string(agg_beta`lhs'_weight[2], "%9.3f")
	local agg_beta`lhs'_pos2 = string(agg_beta`lhs'[1], "%9.3f")
	local agg_beta`lhs'_neg2 = string(agg_beta`lhs'[2], "%9.3f")
	local agg_beta`lhs'_pos_share = string(share[1], "%9.3f")
	local agg_beta`lhs'_neg_share = string(share[2], "%9.3f")
	
	drop share 
}

/*******************************************************************************
Print table 
*******************************************************************************/
capture file close fh
file open fh  using "$tables/rotemberg_summary.tex", write replace
file write fh "\begin{tabularx}{\textwidth}{l*{4}{Y}} \toprule" _n

/** Panel A **/
file write fh "\multicolumn{4}{l}{\textbf{Panel A: Negative and positive weights}} \\" _n
file write fh  " & Sum & Mean & Share  \\  \cmidrule(lr){2-4}" _n
file write fh  "Negative & `sum_neg_alpha' & `mean_neg_alpha' & `share_neg_alpha'  \\" _n
file write fh  "Positive & `sum_pos_alpha' & `mean_pos_alpha' & `share_pos_alpha'  \\" _n

/** Panel B **/
file write fh "\multicolumn{4}{l}{\textbf{Panel B: Correlations of country-of-birth aggregates} }\\" _n
file write fh  " 			&$\alpha_k$ 	    & \$g_{k}$       & $\beta^{Prod.}_{k}$ & $\beta^{Lab.Share}_{k}$ \\" _n
file write fh  "\cmidrule(lr){2-5} " _n
file write fh " & \\" _n
file write fh " $\alpha_k$              & `alpha1_alpha1' \\" _n
file write fh " \$g_{k}$                & `g_alpha1'  	     & `g_g' \\" _n
file write fh " $\beta^{Prod.}_{k}$     & `betaDy_alpha1'    & `betaDy_g'    & `betaDy_betaDy'   \\" _n
file write fh " $\beta^{Lab.Share}_{k}$ & `betaDyWB2_alpha1' & `betaDyWB2_g' &  `betaDy_betaDyWB2' & `betaDyWB2_betaDyWB2' \\" _n

/** Panel C **/
file write fh "\multicolumn{4}{l}{\textbf{Panel C: Variation across years in $\alpha_{k}$}}\\" _n
file write fh  " & Sum & Mean \\  \cmidrule(lr){2-3}" _n
foreach y in `yearSet' {
	file write fh  "`y' & `sum_`y'_alpha' & `mean_`y'_alpha'   \\" _n
}

/** Panel D.1: Top 5 weights and shocks **/
file write fh "\multicolumn{4}{l}{\textbf{Panel D: Top 5 Rotemberg weight countries} }\\" _n
file write fh "\multicolumn{4}{l}{\textit{Panel D.1: Weights and Inflows} }\\" _n
file write fh  " & $\hat{\alpha}_{k}$ & \$g_{k}$ \\ \cmidrule(lr){2-3}" _n
foreach iso2c of local iso2cTOP5 {
	file write fh  "`iso2c_name_`iso2c'' & `alpha_`iso2c'' & `g_`iso2c'' \\ " _n
}

/** Panel D.1: Top 5 weights and shocks **/
file write fh "\multicolumn{4}{l}{\textit{Panel D.2: Estimates} }\\" _n
file write fh  "& $\hat{\beta}^{Prod.}_{k}$ & 95 \% CI & $\hat{\beta}^{Lab.Share}_{k}$ & 95 \% CI  \\ \cmidrule(lr){2-5}" _n
foreach iso2c of local iso2cTOP5 {
	file write fh  "`iso2c_name_`iso2c'' & `betaDy_`iso2c'' & (`ci_minDy_`iso2c'', `ci_maxDy_`iso2c'')    " _n
	file write fh  "& `betaDyWB2_`iso2c'' & (`ci_minDyWB2_`iso2c'', `ci_maxDyWB2_`iso2c'')    \\ " _n
}

/** Panel E **/
file write fh "\multicolumn{4}{l}{\textbf{Panel E: Estimates of $\beta^{y}_{k}$ for positive and negative weights} }\\" _n
file write fh  " & $\alpha$-weighted Sum & Share of overall $\beta$ & Mean  \\ \cmidrule(lr){2-4}" _n

file write fh "\multicolumn{4}{l}{}{\textit{Productivity}}\\" _n
file write fh  " Negative & `agg_betaDy_neg' & `agg_betaDy_neg_share' &`agg_betaDy_neg2' \\" _n
file write fh  " Positive & `agg_betaDy_pos' & `agg_betaDy_pos_share' & `agg_betaDy_pos2' \\" _n

file write fh "\multicolumn{4}{l}{}{\textit{Labour Share}}\\" _n
file write fh  " Negative & `agg_betaDyWB2_neg' & `agg_betaDyWB2_neg_share' &`agg_betaDyWB2_neg2' \\" _n
file write fh  " Positive & `agg_betaDyWB2_pos' & `agg_betaDyWB2_pos_share' & `agg_betaDyWB2_pos2' \\" _n

file write fh  "\bottomrule \end{tabularx}" _n
file close fh 

/*******************************************************************************
This script produces the decomposition introduced by 
Goldsmith-Pinkham et al (2020)
*******************************************************************************/
/*
Exposure 
*/
use normexp itl321cd iso2c using "$data/Exposure.dta", clear 
merge m:1 itl321cd using "$data/ITL3toGOR9D.dta"
keep if _merge == 3
drop _merge 
expand 25
bys iso2c itl321cd: g year = 1990 + _n 

/*
Aggregated data 
*/
merge m:1 itl321cd year using "$data/AnalysisData.dta", ///
	keepusing(y yWB2 D10xsh z weight locid)
keep if _merge == 3 
drop _merge 

reshape wide normexp@, i(itl321cd year) j(iso2c, s)

foreach v of varlist normexp* { 
	egen `v'_std = std(`v')  
}

egen NUTS1 = group(gor9d)
tempfile tmp0 
save `tmp0'

/*******************************************************************************
Export estimates 
*******************************************************************************/
foreach Dfe in "" "year#NUTS1" { 
	use `tmp0', clear
	preserve 
		clear 
		g y = ""
		g b = . 
		g blow = . 
		g bup = . 
		g iso2c = ""
		g year = . 
		tempfile tmp 
		save `tmp'
	restore 

	foreach y in y yWB2 { 
		foreach iso2c of local iso2cTOP5 {
			reghdfe `y' c.normexp`iso2c'_std c.normexp`iso2c'_std#ib2002.year  /// 
				[aw = weight],  /// 
				abs($FE locid `Dfe') clust(locid) 

			levelsof year if e(sample), local(yearSet)
			distinct year if e(sample)
			local T = r(ndistinct)
			
			preserve 
				clear 

				set obs `T'
				
				g y = "`y'"
				g b = . 
				g blow = . 
				g bup = . 
				g iso2c = "`iso2c'"
				g year = . 

				local iter = 1 
				foreach t in `yearSet' { 
					lincom c.normexp`iso2c'_std#i`t'.year, level(95)
					replace year = `t' in `iter'
					replace b = r(estimate) in `iter'
					replace blow = r(lb) in `iter'
					replace bup = r(ub) in `iter'
					local ++iter 
				}
				append using `tmp'
				save `tmp', replace 	
			restore 
		}		
	}

	/*
	Append inflows from these countries:
	*/
	use "$data/NationalStocks.dta", clear
	reshape wide pop@, i(year) j(iso2c, s)
	reshape long pop@, i(year) j(iso2c, s)
	mvencode pop, mv(0) override

	merge 1:m year iso2c using `tmp'
	keep if _merge == 3 | _merge == 1 

	expand 2 if _merge == 1
	bys year iso2c: replace y = "y" if _n == 1 & _merge == 1 
	by year iso2c: replace y = "yWB2" if _n == 2 & _merge == 1 

	drop _merge 
	keep if year >= 2000 & year <= 2015

	g inflow = pop 
	
	local lbl ""
	if(regexm("`Dfe'", "NUTS1")) local lbl "NUTS1"
	
	foreach y in y yWB2 { 
		foreach iso2c of local iso2cTOP5 {
			#delimit ; 
			twoway 	
				(scatter inflow year if iso2c == "`iso2c'" & y == "`y'", 
					mcol(gs7) ms(S) yaxis(2)) 
				(scatter b year if year >= 2002 & iso2c == "`iso2c'" & y == "`y'", 
					mcol(black)) 
				(rcap blow bup year if year >= 2002 & iso2c == "`iso2c'" & y == "`y'", 
					lcol(black)), 
				ytitle("Estimated Effect", size(vlarge))  
				ytitle("Immigrant Stock" "(in thousands)", size(vlarge) axis(2)) 
				xtitle("Year", size(vlarge))
				xlabel(2000(1)2015, valuelabel angle(45)) 
				legend(off)		
				yline(0, lp(dash)) /// 
				;
			#delimit cr 
			graph export "$plots/Trend_`iso2c'_`y'`lbl'.eps", replace 
		}
	}
}
