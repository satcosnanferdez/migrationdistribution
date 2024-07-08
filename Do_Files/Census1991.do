/*******************************************************************************
CENSUS TOTAL POPULATION 1991: England and Wales
*******************************************************************************/
/*
England and Wales (Note: Data has entries for Scotland but all are missing)
*/
import delimited "$cens91/Migrants1991.csv", delimiter(comma) clear 
foreach v of varlist * { 
	if("`v'" == "v2") continue
	if(!regexm(`v'[5], "Persons") | !regexm(`v'[5], "Born") ) { 
		drop `v'
		continue 
	}
	replace `v' = `v'[5] in 1
	replace `v' = regexs(1) if regexm(`v', ".+Born in (.+)[:\(].+") in 1
	gen cont`v' = `v'[1]
	local lb = `v'[5]
	lab var `v' "`lb'"
}
rename v2 lad18cd 
keep if lad18cd != ""
reshape long v@ contv@, i(lad18cd) j(tmp)
destring v, gen(pop) force 
keep if pop != .
replace cont = strtrim(regexr(cont, "\(.+\)", "")) 

/*LAD11 to LAD21*/ 
rename lad lad11cd
gen matched = ""
merge m:1 lad11cd using "$data/LAD11toLAD21.dta", keepusing(lad21cd)
replace matched = lad21cd 
keep if _merge == 1 | _merge == 3
drop _merge lad21cd

gen lad20cd = lad11cd
merge m:1 lad20cd using "$data/LAD20toLAD21.dta", keepusing(lad21cd)
replace matched = lad21cd if missing(matched)
keep if _merge == 1 | _merge == 3
drop _merge 

count if missing(matched) & regexm(lad21cd, "[EW][0-9]+")
if(r(N) > 0) { 
    disp as error "Non matched LADs in EW"
	exit 
}
keep if !missing(matched)
drop lad*
rename matched lad21cd
collapse (sum) pop, by(lad21cd contv)

replace contv = "Myanmar" if regexm(contv, "Myanmar")
replace contv = "Ireland" if regexm(contv, "Irish Republic")
replace contv = "China" if regexm(contv, "China, Peoples Republic of")
replace contv = "Malta" if regexm(contv, "Malta and Gozo")
replace contv = "South Africa" if regexm(contv, "South Africa, Republic of")

g D = 1
replace D = 3 if regexm(contv, "Botswana, Lesotho and Swaziland")
replace D = 2 if regexm(contv, "Czechoslovakia")

foreach v of varlist pop* { 
	destring `v', replace force
	replace `v' = `v' / D if regexm(contv, "Botswana, Lesotho and Swaziland")
	replace `v' = `v' / D if regexm(contv, "Czechoslovakia")
}
expand D

bys contv lad21cd: g tmp = "Botswana" if _n == 1 & regexm(contv, "Botswana, Lesotho and Swaziland")
bys contv lad21cd: replace tmp = "Lesotho" if _n == 2 & regexm(contv, "Botswana, Lesotho and Swaziland")
bys contv lad21cd: replace tmp = "Swaziland" if _n == 3 & regexm(contv, "Botswana, Lesotho and Swaziland")

bys contv lad21cd: replace tmp = "Czech Republic" if _n == 1 & regexm(contv, "Czechoslovakia")
bys contv lad21cd: replace tmp = "Slovakia" if _n == 2 & regexm(contv, "Czechoslovakia")
replace contv = tmp if !missing(tmp)
drop tmp
collapse (sum) pop, by(lad21cd contv)

preserve 
	collapse (first) lad21cd, by(contv)
	kountry contv, from(other) stuck marker
	tab contv if MARKER == 0
	keep if MARKER == 1 | regexm(contv, "Outside United Kingdom")
	rename _ISO3N_ iso3n 
	drop MARKER  
	kountry iso3n, from(iso3n) to(iso2c)
	rename _ISO2C_ iso2c 
	replace iso2c = "Other" if regexm(contv, "Outside United Kingdom")
	keep if iso2c != ""
	drop iso3n
	tempfile map
	save `map'
restore 
merge m:1 contv using `map'
tab contv if _merge == 1
keep if _merge == 3 
drop _merge 

count if cont == "United Kingdom"
if(r(N) == 0) { 
	disp as error "United Kingdom not included"
	exit 
}
count if cont == "Outside United Kingdom" 
if(r(N) == 0) { 
	disp as error "Outside United Kingdom not included"
	exit 
}
count if iso2c == "GB"
if(r(N) == 0) { 
	disp as error "GB not inclued in iso2c"
	exit 
}

bys lad21cd: egen tot = total(pop * (iso2c != "Other" & iso2c != "GB"))
replace pop = pop - tot if iso2c == "Other"

bys lad21cd: egen Pj = total(pop)

rename pop Mmj

keep iso2c lad21cd Pj Mmj

tempfile EW
save `EW'

/*******************************************************************************
CENSUS Population 1991: Scotland 
*******************************************************************************/
import delimited "$cens91/Migrants1991SC.csv", delimiter(comma) clear 
foreach v of varlist * { 
	if("`v'" == "v1") continue
	if(!regexm(`v'[6], "^S[0-9]+")) { 
		drop `v'
		continue 
	}
	local lb = `v'[6]
	rename `v' pop`lb'
}
keep if regexm(v1, "Persons")
replace v1 =  strtrim(regexs(1)) if regexm(v1, "^.+\((.+):.+")
replace v1 =  strtrim(regexr(v1, "Born in", ""))
rename v1 contv 

bys contv: gen n = _N
drop if n > 1
drop n 
reshape long pop@, i(contv) j(lad, s)
destring pop, replace force
replace cont = strtrim(regexr(cont, "\(.+\)", "")) 

/*LAD11 to LAD21*/ 
rename lad lad11cd
gen matched = ""
merge m:1 lad11cd using "$data/LAD11toLAD21.dta", keepusing(lad21cd)
replace matched = lad21cd 
keep if _merge == 1 | _merge == 3
drop _merge lad21cd

gen lad20cd = lad11cd
merge m:1 lad20cd using "$data/LAD20toLAD21.dta", keepusing(lad21cd)
replace matched = lad21cd if missing(matched)
keep if _merge == 1 | _merge == 3
drop _merge 

/*
Older local authorities need to split 
*/
expand 2 if lad11cd == "S12000009"
bys lad11cd contv: replace pop = pop / _N
bys lad11cd contv: replace matched = "S12000045" if _n == 1 & _N == 2 & lad11cd == "S12000009"
bys lad11cd contv: replace matched = "S12000049" if _n == 2 & _N == 2 & lad11cd == "S12000009"

expand 2 if lad11cd == "S12000043"
bys lad11cd contv: replace pop = pop / _N
bys lad11cd contv: replace matched = "S12000045" if _n == 1 & _N == 2 & lad11cd == "S12000043" 
bys lad11cd contv: replace matched = "S12000049" if _n == 2 & _N == 2 & lad11cd == "S12000043" 

tab lad11cd if missing(matched)

/*
Count the number of entries with censored/mising pop
*/
egen nmis = total(missing(pop)), by(contv) 
replace nmis = nmis + 1

/*
Allocate national residual to those with missing 
*/
egen tmp = total(pop * (lad20cd != "S92000003")), by(cont)
gen popSC = pop if lad20cd == "S92000003"
bys cont (popSC): replace popSC = popSC[1]
replace pop = (popSC - tmp) / nmis if missing(pop)

count if missing(matched) & !regexm(lad20cd, "S92") 
if(r(N) > 0) { 
    disp as error "non matched LADs in Scotland"
	exit 
}
drop if missing(matched)
drop lad*
rename matched lad21cd
collapse (sum) pop, by(lad21cd contv)

replace contv = "Myanmar" if regexm(contv, "Myanmar")
replace contv = "Ireland" if regexm(contv, "Irish Republic")
replace contv = "China" if regexm(contv, "China, Peoples Republic of")
replace contv = "Malta" if regexm(contv, "Malta and Gozo")
replace contv = "South Africa" if regexm(contv, "South Africa, Republic of")

g D = 1
replace D = 3 if regexm(contv, "Botswana, Lesotho and Swaziland")
replace D = 2 if regexm(contv, "Czechoslovakia")

foreach v of varlist pop* { 
	destring `v', replace force
	replace `v' = `v' / D if regexm(contv, "Botswana, Lesotho and Swaziland")
	replace `v' = `v' / D if regexm(contv, "Czechoslovakia")
}
expand D

bys contv lad21cd: g tmp = "Botswana" if _n == 1 & regexm(contv, "Botswana, Lesotho and Swaziland")
bys contv lad21cd: replace tmp = "Lesotho" if _n == 2 & regexm(contv, "Botswana, Lesotho and Swaziland")
bys contv lad21cd: replace tmp = "Swaziland" if _n == 3 & regexm(contv, "Botswana, Lesotho and Swaziland")

bys contv lad21cd: replace tmp = "Czech Republic" if _n == 1 & regexm(contv, "Czechoslovakia")
bys contv lad21cd: replace tmp = "Slovakia" if _n == 2 & regexm(contv, "Czechoslovakia")
replace contv = tmp if !missing(tmp)
drop tmp 

preserve 
	collapse (first) lad21cd, by(contv)
	kountry contv, from(other) stuck marker
	tab contv if MARKER == 0
	keep if MARKER == 1 | regexm(contv, "Outside United Kingdom")
	rename _ISO3N_ iso3n 
	drop MARKER  
	kountry iso3n, from(iso3n) to(iso2c)
	rename _ISO2C_ iso2c 
	replace iso2c = "Other" if regexm(contv, "Outside United Kingdom")
	keep if iso2c != ""
	drop iso3n
	tempfile map
	save `map'
restore 
merge m:1 contv using `map'
tab contv if _merge == 1 
keep if _merge == 3 
drop _merge

count if cont == "United Kingdom"
if(r(N) == 0) { 
	disp as error "United Kingdom not included"
	exit 
}
count if cont == "Outside United Kingdom" 
if(r(N) == 0) { 
	disp as error "Outside United Kingdom not included"
	exit 
}
count if iso2c == "GB"
if(r(N) == 0) { 
	disp as error "GB not inclued in iso2c"
	exit 
}

bys lad21cd: egen tot = total(pop * (iso2c != "Other" & iso2c != "GB"))
replace pop = pop - tot if iso2c == "Other"

bys lad21cd: egen Pj = total(pop)

rename pop Mmj

keep iso2c lad21cd Pj Mmj

tempfile SC 
save `SC'

/*******************************************************************************
Append England, Scotland and Wales. Make sure there is a common set of countries 
of birth  
*******************************************************************************/
use `EW', clear 
collapse (first) lad21cd, by(iso2c)
keep iso2c 
tempfile inner 
save `inner'
use `SC', clear 
collapse (first) lad21cd, by(iso2c)
keep iso2c 
merge 1:1 iso2c using `inner'
count if _merge != 3 
if(r(N) > 0) { 
	disp as error "countries of birth not matched between EW and SC"
	exit 
}
drop _merge 

use `EW', clear 
append using `SC'

/*
Map local authorities into NUTS-3 
*/
merge m:1 lad21cd using "$data/LAD21toITL3.dta"
count if _merge != 3 & regexm(lad21cd, "[EW][0-9]+") 
if(r(N) > 0) {
	disp as error "ITL3 not matched"
	exit 
}
keep if _merge == 3
drop _merge 

preserve 
	collapse (first) Pj, by(lad21cd itl321cd* weight*)
	reshape long itl321cd@ weight@, i(lad21cd) j(tmp)
	keep if weight != .
	replace Pj = weight * Pj
	collapse (sum) Pj, by(itl321cd)
	tempfile P
	save `P'
restore 
drop Pj 
reshape long itl321cd@ weight@, i(lad21cd iso2c) j(tmp)
keep if weight != .
replace Mmj = weight * Mmj
collapse (sum) Mmj, by(itl321cd iso2c)
merge m:1 itl321cd using `P', nogen 

drop if iso2c == "GB"

save "$data/Census1991.dta", replace 


