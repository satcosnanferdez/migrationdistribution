/*******************************************************************************
EMPLOYMENT BY 3-DIGIT INDUSTRY 1991-2015
*******************************************************************************/
import excel "$aes/nomis_2023_10_06_135151.xlsx", clear  

gen year = B if regexm(A, "date")
replace year = year[_n - 1] if missing(year)
drop A
rename B lad15cd

local i = 1
foreach v of varlist * { 
	cap tostring `v', replace 
	if(inlist("`v'", "lad15cd", "year")) continue 
	if(!regexm(`v'[7], " *[0-9]+ *:")) { 
		drop `v'
		continue 
	}
	rename `v' emp`i'
	local ++i
}
keep lad15cd emp* year
keep if regexm(lad15cd, "^[A-Z][0-9]+")
compress
destring emp* year, replace force
egen emp = rowtotal(emp*)
keep lad15cd emp year

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

tab lad11cd if missing(matched)
drop lad*
rename matched lad21cd

collapse (sum) emp, by(lad21cd year)

/*
Some years in-between not reported fill them by interpolation
*/
bys lad21cd (year): g D = year[_n + 1] - year 
replace D = 1 if missing(D) | D == 0
expand D
bys lad21cd year: g tmp = year + _n - 1 
replace emp = . if year != tmp 
drop year D
rename tmp year
bys lad21cd: ipolate emp year, g(tmp)
replace emp = tmp 
drop tmp 

drop if year == 1998 

save "$data/ERASEME.dta", replace 

/*****************************************
1998-2008
******************************************/
/*1998-2008 employment*/
import excel "$abi/nomis_2023_10_06_134949.xlsx", clear  
drop in 1 / 6
foreach v of varlist * { 
	if(regexm(`v'[1], "^[0-9]+$")) { 
		local y = `v'[1]
		rename `v' emp`y'
	}
}
keep if regexm(B, "^[A-Z][0-9]+")
keep B emp*
rename B lad15cd
compress

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

tab lad11cd if missing(matched)
drop lad*
rename matched lad21cd

keep lad21cd emp* 
qui destring emp*, replace force 

collapse (sum) emp*, by(lad21cd)
reshape long emp@, i(lad21cd) j(year) 

append using "$data/ERASEME.dta"
save "$data/ERASEME.do", replace 

/*****************************************
2009-2015
******************************************/
import excel "$bres/nomis_2023_10_06_134754.xlsx", clear  

gen year = B if regexm(A, "date")
replace year = year[_n - 1] if missing(year)
drop A
rename B lad19cd

local i = 1 
foreach v of varlist * { 
	cap tostring `v', replace 
	if(inlist("`v'", "lad19cd", "year")) continue 
	if(!regexm(`v'[8], "[0-9]+ :")) { 
		drop `v'
		continue 
	}
	qui rename `v' emp`i'
	local ++i
}
keep lad19cd emp* year
keep if regexm(lad19cd, "^[A-Z][0-9]+")
compress 
destring year emp*, replace force 
egen emp = rowtotal(emp*)
keep lad19cd emp year

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

tab lad11cd if missing(matched)
drop lad*
rename matched lad21cd

collapse (sum) emp, by(year lad21cd)

append using "$data/ERASEME.do"

merge m:1 lad21cd using "$data/LAD21toITL3.dta"
tab lad21cd if _merge == 2
keep if _merge ==  3 
drop _merge 
reshape long itl321cd@ weight@, i(lad21cd year) j(tmp)	
keep if !missing(itl321cd)
foreach v in emp {
	replace `v' = `v' * weight
}
collapse (sum) emp, by(itl321cd year)

rm "$data/ERASEME.do"
save "$data/Employment.do", replace 

