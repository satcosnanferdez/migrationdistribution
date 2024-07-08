/******************************************************************************
Major Occupation Groups
*******************************************************************************/
import delimited "$aps/Emp_OccupationMajGrp.csv", delimiter(comma) clear  
drop v1
gen majOcc = v2 if regexm(v2, "T12a")
replace majOcc = regexs(1) if regexm(majOcc, ".+\(([0-9]).+")
replace majOcc = majOcc[_n - 1] if missing(majOcc)
rename v2 lad 

local iter = 1 
foreach v of varlist * { 
	cap tostring `v', replace 
	if(regexm(`v'[6], "^Conf")) {
		drop `v'
		continue 
	}
	if(inlist("`v'", "majOcc", "lad")) { 
		continue 
	}
	replace `v' = regexs(1) in 6 if regexm(`v', "[^0-9]([0-9]+).+")
	local y = `v'[6]
	rename `v' emp`y'
}
keep if regexm(lad, "^[A-Z][0-9]+$")
compress 
reshape long emp@, i(lad majOcc) j(year)
destring emp, replace force 
mvencode emp, mv(0)

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

collapse (sum) emp, by(lad21cd majOcc year)

merge m:1 lad21cd using "$data/LAD21toITL3.dta"
keep if _merge ==  3 
drop _merge 

reshape long itl321cd@ weight@, i(lad21cd majOcc year) j(tmp)	
keep if !missing(itl321cd)
foreach v in emp {
	replace `v' = `v' * weight
}
collapse (sum) emp , by(itl321cd year majOcc)

destring majOcc, replace 
lab def majOcc 1 "Managers" 2 "Professional" /// 
	3 "Associate" 4 "Administrative" 5 "Skilled" /// 
	6 "Caring" 7 "Sales" 8 "Process" 9 "Elementary"
lab val majOcc majOcc
tempfile tmp 
save `tmp'

/**************************************************
Use 2001 to impute years 2000 by carrying backward 
and 2002-2003 by interpolation
**************************************************/
/*
England and Wales
*/
import excel "$cens01/Occupation_groups.xlsx", clear first 
drop KS012a 
foreach v of varlist * { 
	if(regexm(`v'[6], "^[0-9]")) { 
		replace `v' = regexs(1) in 6 if regexm(`v', "^([0-9]+)[^0-9].+")
		local nm = `v'[6]
		rename `v' emp`nm'
	}
}
rename B lad
keep if regexm(lad, "[A-Z][0-9]+")
compress 
reshape long emp@, i(lad) j(majOcc)
destring emp, replace 
lab def majOcc 1 "Managers" 2 "Professional" /// 
	3 "Associate" 4 "Administrative" 5 "Skilled" /// 
	6 "Caring" 7 "Sales" 8 "Process" 9 "Elementary"
lab val majOcc majOcc
tempfile ew 
save `ew'

/*
Scotland
*/
import excel "$cens01/KS12a.xlsx", clear first
rename Table A
local i = 1
foreach v of varlist * { 
	if("`v'" == "A") continue 
	destring `v', replace force
	if("`v'" == "B") continue 
	replace `v' = `v' * B
	rename `v' emp`i'
	local ++i
}
drop B
rename A ca01nm
keep if !missing(emp1)
reshape long emp@, i(ca01nm) j(majOcc)
su majOcc 
replace majOcc = majOcc - r(min) + 1
replace ca01nm = "Edinburgh" if regexm(ca01nm, "Edinburgh")
tempfile sc 
save `sc'

/*
Get local authority codes
*/
import delimited "$lookups/COUNCIL AREA LOOKUP2001.csv", delimiter(comma) clear 
rename name ca01nm
replace ca01nm = "Edinburgh" if regexm(ca01nm, "Edinburgh")
rename council_area ca01cd
merge 1:m ca01nm using `sc'
tab ca01nm if _merge == 2
keep if _merge == 3
drop _merge  
save `sc', replace 

/*
Get 2011 local authority codes 
*/
import delimited "$lookups/COUNCIL AREA LOOKUP2011.csv", delimiter(comma) clear 
keep councilarea2011code nrsoldcouncilareacode 
rename councilarea2011code lad
rename nrsoldcouncilareacode ca01cd
merge 1:m ca01cd using `sc'
keep lad emp majOcc
collapse (sum) emp, by(majOcc lad)

append using `ew'

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

collapse (sum) emp, by(lad21cd majOcc)

merge m:1 lad21cd using "$data/LAD21toITL3.dta"
keep if _merge ==  3 
drop _merge 

reshape long itl321cd@ weight@, i(lad21cd majOcc) j(tmp)	
keep if !missing(itl321cd)
foreach v in emp {
	replace `v' = `v' * weight
}
collapse (sum) emp , by(itl321cd majOcc)
expand 2
bys itl321cd majOcc: g year = 1999 + _n 

append using `tmp'
drop if regexm(itl321cd, "^TLN")

g D = 1 
replace D = 3 if year == 2001
expand D
bys year itl321cd majOcc: g tmp = year + _n - 1 if year == 2001
replace tmp = year if missing(tmp)
replace emp = . if tmp != year
drop year 
rename tmp year 

egen sh = total(emp), by(itl321cd year)
replace sh = emp / sh
bys itl321cd majOcc: ipolate sh year, g(tmp)
replace sh = tmp 
keep sh itl321cd year majOcc
reshape wide sh@, i(itl321cd year) j(majOcc)
keep year itl321cd year sh*
rename sh* occsh*

save "$data/OccupationShares.dta", replace 

