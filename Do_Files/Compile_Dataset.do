/*******************************************************************************
Merge datasets 
*******************************************************************************/
use "$data/Immigrant1665.dta", clear
egen id = group(itl321cd)
replace M = M * 1e3 
replace N = N * 1e3 

g xsh = M / (M + N)

/*
Decennial changes: current and lagged
*/
xtset id year 
g D10xsh = M / (M + N) - L10.M / (L10.M + L10.N)
g L10M = L10.M 
g L10N = L10.N

/*
Other measures of migration
*/
g D10xrat = M / N - L10.M / L10.N
g D10M = S10.M / (L10.N + L10.M)
g D10L = (S10.M + S10.N) / (L10.M + L10.N)
g D10N = S10.N / (L10.M + L10.N)

foreach v of varlist D10* xsh { 
	g L10`v' = L10.`v'
}

/*
Native out-migration 
*/
g natmig = log(N) - log(L10.N)
g L10natmig = L10.natmig

g D10popL = log(N + M) - log(L10.N + L10.M)
g L10D10popL = L10.D10popL
g L10popL = log(L10.N + L10.M)

drop id 

foreach d in /// 
	"$data/Productivity.dta" /// 
	"$data/Instrument.dta" /// 
	"$data/GVAcomponents.dta" /// 
	"$data/ProjectedEmployment.dta" /// 
	"$data/OccupationShares.dta" /// 
	{ 
	merge 1:1 year itl321cd using `d'
	keep if _merge == 3 
	drop _merge 
}
foreach d in /// 
	"$data/ITL3toGOR9D.dta" {
	merge m:1 itl321cd using `d'
	keep if _merge == 3 
	drop _merge 
}
encode gor9d, g(tmp)
drop gor9d
rename tmp gor9d

/*
Scale income side GVA to add to balanced GVA from productivity 
data: recall income GVA provided in millions 
*/
g gvaFromProd = prod * jobs * 1e-6
g scGVA = gvaFromProd / gvainc 
foreach v of varlist gvainc coe mincome rentincome /// 
	nonmcons holdgain tradprofit tradsur prodtax prodsub lc { 
	g `v'_uns = `v' 
	replace `v' = `v' * scGVA
}

/*
Outcomes and immigrant share 
*/
g Y = log(prod * jobs * def)
g y = log(prod * def * 1e-3)
g yH = log(prod * jobs / hours * def)
g lnJ = log(jobs)
g lWB1 = log(coe / jobs * def * 1e3)
g yWB1 = log(coe / gvainc)
g lWB2 = log(lc / jobs * def * 1e3)
g yWB2 = log(lc / gvainc)
g prodcon = prod * def * 1e-3

/*
Main outcomes measured from unscaled income side GVA 
*/
g y_uns = log(gvainc_uns / jobs * def)
g lWB_uns = log(lc_uns / jobs * def * 1e3)
g yWB_uns = log(lc_uns / gvainc_uns)

/*
London and Countries 
*/
g london = regexm(itl321cd, "TLI")
g scotland = regexm(itl321cd, "TLM")
g wales = regexm(itl321cd, "TLL")
g england = !scotland & !wales

encode itl321cd, g(locid)

/*
Weight by contribution to national GVA in baseline year 
*/
bys locid (year): g weight = gvainc[1]
bys locid (year): g jweight = jobs[1]

xtset locid year

g w10G = ( 1 / gvainc + 1 / L10.gvainc) ^(-1/2) 
g w1G = ( 1 / gvainc + 1 / L1.gvainc) ^(-1/2) 

g w10J = ( 1 / gvainc + 1 / L10.jobs) ^(-1/2) 
g w1J = ( 1 / gvainc + 1 / L1.jobs) ^(-1/2) 

keep if year >= 2002 & year <= 2015

/*
Lagged employment outcomes 
*/
preserve 
	use "$data/Employment.do", clear 
	keep if year >= 1992 & year < 2016

	egen locid = group(itl321cd)
	xtset locid year

	g D10emp = log(emp) - log(L10.emp)
	g L10D10emp = L10.D10emp
	g L10emp = log(L10.emp)

	keep *10* itl321cd year 
	keep if year >= 2002 & year <= 2015
	tempfile tmp 
	save `tmp'
restore 
merge 1:1 year itl321cd using `tmp'
count if _merge != 3 
if(r(N) > 0) { 
	disp as error "Non-matched ITL3-year obs"
	exit 
}
drop _merge 

xtset locid year 
g D10empdens = D10emp - D10popL
g L10D10empdens = L10D10emp - L10D10popL
g D10jbdens = S10.lnJ - D10popL
g L10empdens = L10emp - L10popL

/*
Rename some variables 
*/
rename *zLFSUN *z

save "$data/AnalysisData.dta", replace 

/*******************************************************************************
To replicate main regressions aggregating data to TTWA  
*******************************************************************************/
use "$data/AnalysisData.dta", clear
compress 
merge m:1 itl321cd using "$data/ITL3toTTWA.dta" 
keep if _merge == 3
drop _merge  

g gva_prod = prod * jobs * def

collapse (sum) gva_prod lc gvainc weight jobs M N L10M L10N, by(ttwa year)
g y = log(gva_prod / jobs)
g yWB2 = log(lc / gvainc)
merge 1:1 ttwa year using "$data/InstrumentTTWA.dta"
keep if _merge == 3 
drop _merge 
rename *zLFSUN *z

encode ttwa, g(locid)

xtset locid year 
g D10xsh = M / (M + N) - L10.M / (L10.M + L10.N)
g L10D10xsh = L10M / (L10M + L10N) - L10.L10M / (L10.L10M + L10.L10N)

save "$data/AnalysisDataTTWA.dta", replace 
