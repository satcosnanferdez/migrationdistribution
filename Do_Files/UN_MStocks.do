/*******************************************************************************
Measures of immigrant stocks from immigrants in other developed countries 
*******************************************************************************/
import excel "$un/UN_MigrantStockByOriginAndDestination_2019.xlsx", /// 
	sheet("Table 1") clear
drop B D E F G
drop in 1 / 15
compress

local i = 1 
foreach v of varlist * {
	rename `v' v`i'
	if(`i' < 3) { 
		local ++i
		continue 
	}
	g nmv`i' = v`i'[1]
	local ++i
}
rename v1 year  
rename v2 countrynm
destring year, replace 
keep if !missing(year)

preserve 
	g tmp = countrynm 
	replace tmp = "Bolivia" if countrynm == "Bolivia (Plurinational State of)"
	replace tmp = "Venezuela" if countrynm == "Venezuela (Bolivarian Republic of)"
	replace tmp = "Cape Verde" if countrynm == "Cabo Verde"
	replace tmp = "China" if regexm(countrynm, "China")
	replace tmp = "North Korea" if countrynm == "Dem. People's Republic of Korea"
	replace tmp = "Sint Maarten" if countrynm == "Sint Maarten (Dutch part)"
	replace tmp = "Palestine" if countrynm == "State of Palestine"
	replace tmp = "Ivory Coast" if countrynm == "Côte d'Ivoire"
	replace tmp = "Czech Republic" if countrynm == "Czechia"
	replace tmp = "Bonaire" if countrynm == "Bonaire, Sint Eustatius and Saba"
	replace tmp = "New Zealand" if countrynm == "Tokelau"
	replace tmp = "Swaziland" if countrynm == "Eswatini"
	replace tmp = "Curazao" if countrynm == "Curaçao"
	replace tmp = "United Kingdom" if countrynm == "Isle of Man"
	replace tmp = "United Kingdom" if countrynm == "Channel Islands"
	replace tmp = "Federated States of Micronesia" if countrynm == "Micronesia (Fed. States of)"
	replace tmp = "Republic of North Macedonia" if countrynm == "North Macedonia"
	replace tmp = "Reunion" if countrynm == "Réunion"

	collapse (first) year, by(countrynm tmp)
	kountry tmp, from(other) stuck marker
	rename MARKER marker1
	rename _ISO3N_ iso3n 
	tab countrynm if !marker1
	kountry iso3n, from(iso3n) to(iso2c)
	rename _ISO2C_ iso2c
	
	replace iso2c = "MK" if tmp == "Republic of North Macedonia"	
	replace iso2c = "SX" if tmp == "Sint Maarten"	
	replace iso2c = "BQ" if tmp == "Bonaire"
	replace iso2c = "CW" if tmp == "Curazao"
	replace iso2c = "MP" if tmp == "Northern Mariana Islands"
	
	replace iso2c = "GB" if iso2c == "FK"
	replace iso2c = "GB" if iso2c == "GI"
	
	keep iso2c countrynm
	keep if !missing(iso2c)
	tempfile tmp
	save `tmp'
restore 
merge m:1 countrynm using `tmp'
replace iso2c = "WORLD" if countrynm == "WORLD"
replace iso2c = "HighIncome" if countrynm == "High-income countries"
replace iso2c = "EUROPENA" if countrynm == "EUROPE AND NORTHERN AMERICA"
replace iso2c = "EUROPE" if countrynm == "EUROPE"
tab countrynm
keep if !missing(iso2c)

g id = _n 
reshape long v@ nmv@, i(id) j(tmp)
compress
destring v, g(stock) force
keep if !missing(stock)
keep year iso2c stock nmv
rename iso2c destination

rename nmv countrynm 
merge m:1 countrynm using `tmp'
replace iso2c = "Other" if _merge == 1
drop if _merge == 2 
drop _merge
rename iso2c origin 
drop if origin == destination

collapse (sum) stock, by(origin destination year)

/*
Make it balanced
*/
reshape wide stock@, i(destination year) j(origin, s)
reshape long stock@, i(destination year) j(origin, s)
mvencode stock, mv(0) override

/*
Keep destination countries observed throughout
*/
bys destination year: g t = _n == 1
bys destination: egen T = total(t)
su T
keep if T == r(max)
drop T t 

/*
Interpolate between observed years
*/
cap drop D
bys origin destination (year): g D = year[_n + 1] - year
replace D = 1 if missing(D)
expand D
bys origin destination year: g tmp = year - 1 + _n
replace stock = . if tmp != year
drop year 
rename tmp year
bys destination origin: ipolate stock year, g(tmp)
replace stock = tmp 
keep origin destination year stock 

save "$data/UNMStocks.dta", replace 




