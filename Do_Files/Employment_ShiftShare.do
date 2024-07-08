/*******************************************************************************
SIC 2007 to 2003 
*******************************************************************************/
import excel "$siclook/sicweightedtables0307_tcm77-261272.xls", /// 
	sheet("RU3digit") firstrow case(lower) clear
destring sic2007, gen(ind)
replace ind = trunc(ind / 10)

bys sic2007: egen tot = total(count)
replace count = count / tot
keep count sic*
destring sic2007, replace 
destring sic2003, replace 

save "$data/SIC2007toSIC2003.dta", replace 

/*******************************************************************************
EMPLOYMENT BY 3-DIGIT INDUSTRY 1991-2015
*******************************************************************************/
import excel "$aes/Emp91_98IND92D3.xlsx", clear  

gen year = B if regexm(A, "Date")
replace year = year[_n - 1] if missing(year)
drop A
rename B lad15cd

foreach v of varlist * { 
	cap tostring `v', replace 
	if(inlist("`v'", "lad15cd", "year")) continue 
	if(!regexm(`v'[7], "[0-9]+ :")) { 
		drop `v'
		continue 
	}
	replace `v' = regexs(1) in 7 if regexm(`v', "([0-9]+) :.+")
	local nname = `v'[7]
	di "`nname'"
	qui rename `v' emp`nname'
}
keep lad15cd emp* year
keep if regexm(lad15cd, "^[A-Z][0-9]+")
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

keep lad21cd year emp* 
qui destring emp* year, replace force 

collapse (sum) emp*, by(lad21cd year)
reshape long emp@, i(lad21cd year) j(sic2003, s) 
destring sic2003, replace 
replace sic2003 = 518 if sic2003 == 516 
replace sic2003 = 519 if sic2003 == 517 

/*
Some years in-between not reported fill them by interpolation
*/
bys sic2003 lad21cd (year): g D = year[_n + 1] - year 
replace D = 1 if missing(D)
expand D
sort sic2003 lad21cd year
bys sic2003 lad21cd year: g tmp = year + _n - 1 
tab tmp
replace emp = . if year != tmp 
drop year D
rename tmp year
bys sic2003 lad21cd: ipolate emp year, g(tmp)
replace emp = tmp 
drop tmp 

drop if year == 1998 

tempfile dat91_97
save `dat91_97'

/*****************************************
1998-2008
******************************************/
/*1998-2008 employment*/
import excel "$abi/Emp98_08IND03D3.xlsx", clear  

gen year = B if regexm(A, "Date")
replace year = year[_n - 1] if missing(year)
drop A
rename B lad15cd

foreach v of varlist * { 
	cap tostring `v', replace 
	if(inlist("`v'", "lad15cd", "year")) continue 
	if(!regexm(`v'[7], "[0-9]+ :")) { 
		drop `v'
		continue 
	}
	replace `v' = regexs(1) in 7 if regexm(`v', "([0-9]+) :.+")
	local nname = `v'[7]
	di "`nname'"
	qui rename `v' emp`nname'
}
keep lad15cd emp* year
keep if regexm(lad15cd, "^[A-Z][0-9]+")

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

keep lad21cd year emp* 
qui destring emp* year, replace force 

collapse (sum) emp*, by(lad21cd year)
reshape long emp@, i(lad21cd year) j(sic2003, s) 
destring sic2003, replace 

append using `dat91_97'
tab sic2003 year

save `dat91_97', replace 

/*****************************************
2009-2015
******************************************/
import excel "$bres/Emp09_15IND07D3.xlsx", clear  

gen year = B if regexm(A, "Date")
replace year = year[_n - 1] if missing(year)
drop A
rename B lad19cd

foreach v of varlist * { 
	cap tostring `v', replace 
	if(inlist("`v'", "lad19cd", "year")) continue 
	if(!regexm(`v'[8], "[0-9]+ :")) { 
		drop `v'
		continue 
	}
	replace `v' = regexs(1) in 8 if regexm(`v', "([0-9]+) :.+")
	local nname = `v'[8]
	di "`nname'"
	qui rename `v' emp`nname'
}
keep lad19cd emp* year
keep if regexm(lad19cd, "^[A-Z][0-9]+")

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

qui destring emp*, replace 
collapse (sum) emp*, by(lad21cd year)
reshape long emp@, i(lad21cd year) j(sic2007, s)
destring sic2007, replace 
destring year, replace 

tempfile tmp 
save `tmp', replace 

/*
Expand the 2007 - 2003 mapping 
*/
levelsof lad21cd, local(lads)
distinct lad21cd
local nlads = r(ndistinct)
levelsof year, local(years)
distinct year
local T = r(ndistinct)

use "$data/SIC2007toSIC2003.dta", clear 
expand `nlads'
g lad21cd = "" 
bys sic2003 sic2007: g n = _n 
local i = 1
foreach l in `lads' { 
	replace lad21cd = "`l'" if n == `i'
	local ++i
}

expand `T'
g year = .
drop n 
bys sic2003 sic2007 lad21cd: g n = _n 
local i = 1
foreach l in `years' { 
	replace year = `l' if n == `i'
	local ++i
}

merge m:1 sic2007 year lad21cd using `tmp'
replace sic2003 = 10 if sic2007 == 10 & _merge == 2
replace sic2003 = 102 if sic2007 == 52 & _merge == 2
replace sic2003 = 950 if sic2007 == 970 & _merge == 2 
replace sic2003 = 960 if sic2007 == 981 & _merge == 2 
replace sic2003 = 970 if sic2007 == 982 & _merge == 2 
replace sic2003 = 990 if sic2007 == 990 & _merge == 2 

replace count = 1 if sic2007 == 52 & _merge == 2
replace count = 1 if sic2007 == 10 & _merge == 2
replace count = 1 if sic2007 == 970 & _merge == 2 
replace count = 1 if sic2007 == 981 & _merge == 2 
replace count = 1 if sic2007 == 982 & _merge == 2 
replace count = 1 if sic2007 == 990 & _merge == 2 

expand 2 if sic2007 == 72
drop n
bys sic2003 sic2007 lad21cd year: g n = _n 
replace sic2003 = 120 if sic2007 == 72 & n == 2
replace count = .5 if sic2007 == 72 

replace emp = emp * count

collapse (sum) emp, by(year lad21cd sic2003)

append using `dat91_97'

drop if inlist(sic2003, 960, 970)

merge m:1 lad21cd using "$data/LAD21toITL3.dta"
tab lad21cd if _merge == 2
keep if _merge ==  3 
drop _merge 
reshape long itl321cd@ weight@, i(lad21cd year sic2003) j(tmp)	
keep if !missing(itl321cd)
foreach v in emp {
	replace `v' = `v' * weight
}
collapse (sum) emp, by(itl321cd sic2003 year)

save "$data/EmploymentIndustry.dta", replace 


/*******************************************************************************
Create Shift-Share: ITL3 
*******************************************************************************/
use "$data/EmploymentIndustry.dta", clear 
g sic20032d = trunc(sic2003 / 10)
collapse (sum) emp, by(itl321cd year sic20032d)
rename sic20032d sic2003

g emp91 = emp if year == 1991
bys sic2003 itl321cd (emp91): replace emp91 = emp91[1] 

bys itl321cd year: egen emp91TOT = total(emp91) 
g SH91 = emp91 / emp91TOT 

bys itl321cd year: egen empTOT = total(emp) 
g SH = emp / empTOT 

bys sic2003 year: egen empNAT = total(emp) 

egen id = group(sic2003 itl321cd)
xtset id year 
g D10zEmp = (log(empNAT) - log(L10.empNAT)) * SH91
g L10D10zEmp = L10.D10zEmp

collapse (sum) L10D10zEmp D10zEmp, by(itl321cd year)
keep if year >= 2002 & year <= 2015

save "$data/ProjectedEmployment.dta", replace 

