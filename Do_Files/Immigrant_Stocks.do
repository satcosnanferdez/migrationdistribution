/*******************************************************************************
LAD 16-65 Immigrant Pop - to ITL3 16-65 Immigrant Pop 
*******************************************************************************/ 
/*
OG DATA: IMMIGRANT-NATIVE 16-65 POPULATION AT THE LOCAL AUTHORITY DISTRICT 
AS REPORTED BY ONS 
*/
forvalue y = 0 / 20 {
	if(`y' < 10) import excel "$ladmigrant/LAD0`y'Immigrant.xls", sheet("1.2") clear
	if(`y' >= 10) import excel "$ladmigrant/LAD`y'Immigrant.xls", sheet("1.2") clear
	keep A B F H G I
	destring F H G I, replace force 
	drop if F == .
	mvencode H, mv(0) override
	rename G varN 
	replace varN = (varN / 1.96) ^ 2
	rename I varM 
	replace varM = (varM / 1.96) ^ 2
	rename F N 
	renam H M 
	rename A lad11cd 
	rename B lad11nm 
	gen year = 2000 + `y'
	if(`y' < 10) save "$data/LADImmigrant0`y'.dta", replace 
	if(`y' >= 10) save "$data/LADImmigrant`y'.dta", replace 
}
use "$data/LADImmigrant00.dta", clear 
rm "$data/LADImmigrant00.dta"
forvalue y = 1 / 20 {
	if(`y' < 10) { 
		append using "$data/LADImmigrant0`y'.dta"
		rm "$data/LADImmigrant0`y'.dta"
	}
	if(`y' >= 10) { 
		append using "$data/LADImmigrant`y'.dta"
		rm "$data/LADImmigrant`y'.dta"
	}
}

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
Non matched are divisions higher than LAD 1
*/
tab lad11cd if missing(matched)
drop if missing(matched)
drop lad* 
rename matched lad21cd

collapse (sum) N M, by(lad21cd year)

merge m:1 lad21cd using "$data/LAD21toITL3.dta"
tab lad21cd if _merge == 2
/*
E06000053 Isles of Scilly -> Combined with Cornwall 
E09000001 City of London -> Added to Westminster
*/
keep if _merge ==  3 
drop _merge 
reshape long itl321cd@ weight@, i(lad21cd year) j(tmp)	
keep if !missing(itl321cd)
foreach v in M N {
	replace `v' = `v' * weight
}
collapse (sum) M N, by(itl321cd year)
keep if year <= 2015

tempfile migEW1664 
save `migEW1664'

/*******************************************************************************
England and Wales all population 
*******************************************************************************/
forvalue y = 0 / 20 {
	if(`y' < 10) import excel "$ladmigrant/LAD0`y'Immigrant.xls", sheet("1.1") clear
	if(`y' >= 10) import excel "$ladmigrant/LAD`y'Immigrant.xls", sheet("1.1") clear
	keep A B F H G I
	destring F H G I, replace force 
	drop if F == .
	mvencode H, mv(0) override
	rename G varN 
	replace varN = (varN / 1.96) ^ 2
	rename I varM 
	replace varM = (varM / 1.96) ^ 2
	rename F N 
	renam H M 
	rename A lad11cd 
	rename B lad11nm 
	gen year = 2000 + `y'
	if(`y' < 10) save "$data/LADImmigrant0`y'.dta", replace 
	if(`y' >= 10) save "$data/LADImmigrant`y'.dta", replace 
}
use "$data/LADImmigrant00.dta", clear 
rm "$data/LADImmigrant00.dta"
forvalue y = 1 / 20 {
	if(`y' < 10) { 
		append using "$data/LADImmigrant0`y'.dta"
		rm "$data/LADImmigrant0`y'.dta"
	}
	if(`y' >= 10) { 
		append using "$data/LADImmigrant`y'.dta"
		rm "$data/LADImmigrant`y'.dta"
	}
}

tempfile migEW 
save `migEW'

/*******************************************************************************
Data at the local authority (council area) level for Scotland reported by 
NRS, totals reported instead of 16-64
*******************************************************************************/
foreach s in 1a 1b {
	import excel "$ladmigrant/Scotland.xlsx", sheet("Table `s'") clear
	rename A lad11cd 
	foreach v of varlist * { 
		tostring `v', replace 
		if("`v'" == "lad11cd") continue 
		if(!regexm(`v'[4], "[0-9]") & !regexm(`v'[6], "CI")) {
			drop `v'
			continue
		}
		replace `v' = regexs(1) in 4 if regexm(`v', "^[^0-9]+([0-9]+)[^0-9].+")
		disp "Year `nm' from variable `v'"
		
		if(`v'[4] != "") {
			local nm = `v'[4]
			capture confirm variable N`nm', exact
			if(!_rc) rename `v' M`nm'
			else rename `v' N`nm'
		} 
		else {	
			destring `v', replace force 
			replace `v' = (`v' / 1.96) ^ 2
			capture confirm variable varN`nm', exact
			if(!_rc) rename `v' varM`nm'
			else rename `v' varN`nm'
		}
	}
	keep if regexm(lad11cd, "^S[0-9]+")
	destring N* M*, replace force 
	reshape long N@ M@ varN@ varM@, i(lad11cd) j(year)
	tempfile mig`s'
	save `mig`s''
}
use `mig1a', clear 
append using `mig1b'
append using `migEW'

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
Non matched are divisions higher than LAD 1
*/
tab lad11cd if missing(matched)
drop if missing(matched)
drop lad* 
rename matched lad21cd

collapse (sum) N M varN varM, by(lad21cd year)

merge m:1 lad21cd using "$data/LAD21toITL3.dta"
tab lad21cd if _merge == 2
keep if _merge ==  3 
drop _merge 
reshape long itl321cd@ weight@, i(lad21cd year) j(tmp)	
keep if !missing(itl321cd)
foreach v in M N varN varM {
	replace `v' = `v' * weight
}
collapse (sum) M N varN varM, by(itl321cd year)
keep if year <= 2015
tempfile tmp
save `tmp'

/*******************************************************************************
Earlier stocks 1992-1999
*******************************************************************************/
import excel "$lookups/uacnty_ITL321_GB_LU.xlsx", clear first
rename uacnt uacnty
replace uacnty =  regexr(uacnty, "^[^0-9A-Za-z]+", "")
g uacnty_code = regexs(1) if regexm(uacnty, "^([0-9A-Za-z]+).+")
keep uacnty* ITL321CD
rename ITL321CD itl321cd
keep uacnty_code itl321cd
bys uacnty_code: g weight = 1 / _N
tempfile tmp_look 
save `tmp_look'

/*
UA and County stocks 
*/
import excel "$uamig/Population by country of birth, county, AJ92 to AJ99.xlsx", /// 
	clear cellrange(A7:R210)
drop A
rename B uacnty
replace uacnty =  regexr(uacnty, "^[^0-9A-Za-z]+", "")
g uacnty_code = regexs(1) if regexm(uacnty, "^([0-9A-Za-z]+).+")
local pv = ""
foreach v of varlist * { 
    if(inlist("`v'", "uacnty", "uacnty_code")) continue 
	if(regexm(`v'[1], " ([0-9][0-9][0-9][0-9])[0-9]*$")) { 
	    local year = regexs(1)
		rename `v' N`year'
		local pv = "`year'"
	} 
	else rename `v' M`pv'
}
keep if !missing(uacnty_code)
reshape long M@ N@, i(uacnty uacnty_code) j(year)
destring M N, replace force
mvencode M N, mv(0) override
drop if year == 1996 
/*
For year 1996 use the January-March data in April-June 1996 for some unknown 
reason in the original data about one-third of the sample does not have a 
value at UACNTY
*/
tempfile tmp2 
save `tmp2'

import excel "$uamig/Population by country of birth, county, AJ92 to AJ99.xlsx", /// 
	clear cellrange(I212:L414)
drop I
rename J uacnty
replace uacnty =  regexr(uacnty, "^[^0-9A-Za-z]+", "")
g uacnty_code = regexs(1) if regexm(uacnty, "^([0-9A-Za-z]+).+")
rename K N 
rename L M
drop if missing(uacnty_code)
destring M N, replace force 
mvencode M N, mv(0) override
g year = 1996 
append using `tmp2'

reshape wide M@ N@, i(uacnty_code uacnty) j(year)
merge 1:m uacnty_code using `tmp_look'
count if _merge != 3 
if(r(N) > 0) { 
    disp as error "UACNTY not matched"
	exit 
}
foreach v of varlist M* N* { 
    replace `v' = `v' * weight
}

/*
London to a single division 
*/
replace itl321cd = "TLI" if regexm(itl321cd, "^TLI")
collapse (sum) M* N*, by(itl321cd)
reshape long M@ N@, i(itl321cd) j(year)
replace M = M * 1e-3 
replace N = N * 1e-3 

append using `tmp'
/*
Northern Ireland
*/
drop if regexm(itl321cd, "^TLN")

save `tmp', replace 

/*******************************************************************************
1991 Stocks from the Census 
*******************************************************************************/
use "$data/Census1991.dta", clear 
collapse (sum) M = Mmj (first) Pj, by(itl321cd)
g N = Pj - M
count if N <= 0
if(r(N) > 0) { 
	disp as error "N <= 0"
	exit 
}
keep N M itl321cd
replace M = M / 1e3 
replace N = N / 1e3 
g year = 1991 
append using `tmp'

/*
1992-1999 data does not contain entries for TLF24, TLF25, TLH37 
*/
bys itl321cd: g T  = _N
su T 
count if T != r(max) & !inlist(itl321cd, "TLF24", "TLF25", "TLH37")
if(r(N) > 0) { 
    disp as error "Missing entries for ITL3 other than TLF24, TLF25, TLH37"
	exit 
}
keep M N year itl321cd
reshape wide M@ N@, i(itl321cd) j(year)
reshape long M@ N@, i(itl321cd) j(year)

bys itl321cd: ipolate M year, g(tmp)
replace M = tmp 
drop tmp 

bys itl321cd: ipolate N year, g(tmp)
replace N = tmp 
drop tmp 

save `tmp', replace

/*
Adjust 1991-1999 data to be 16-64 years old by using Birth and ITL3 specific 
ratios from 2000 
*/
use `migEW1664', clear 
rename M M1664 
rename N N1664 

merge 1:1 year itl321cd using `tmp'
drop _merge 
g M1664_rat = M1664 / M 
g N1664_rat = N1664 / N 
gsort itl321cd -year
foreach v in M1664_rat N1664_rat {
	by itl321cd: replace `v' = `v'[_n - 1] if missing(`v')
}
preserve 
	g P = M + N 
	collapse (mean) M1664_ratimp = M1664_rat N1664_ratimp = N1664_rat [pw = P], by(year)
	tempfile rats
	save `rats'
restore 
merge m:1 year using `rats', nogen 
foreach v in M1664_rat N1664_rat {
	replace `v' = `v'imp if missing(`v')
}
count if missing(M1664_rat) | missing(N1664_rat)
if(r(N) > 0) { 
    disp as error "Missing working age ratios"
	exit 
}
replace M = M * M1664_rat 
replace N = N * N1664_rat 
keep M N year itl321cd
count if missing(M) | missing(N)
if(r(N) > 0) { 
    disp as error "Missing M or N"
	exit 
}

save "$data/Immigrant1665.dta", replace 

