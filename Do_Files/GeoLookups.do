/*******************************************************************************
LAD21
*******************************************************************************/
import delimited "$lookups/LAD21.csv", clear
keep lad21cd lad21nm
save "$data/LAD21.dta", replace 

/*******************************************************************************
LAD20 to LAD21 
*******************************************************************************/
import excel "$lookups/OA11_LAD21_LSOA11_MSOA11_LEP21_EN_v3.xlsx", /// 
	sheet("OA11_LAD21_LSOA_MSOA_LEP21_ENv3")  first clear 
rename *, low
keep lad21cd lad21nm lsoa11cd
bysort lsoa11cd lad21cd: gen f = _n == 1 
keep if f 
drop f

keep if regexm(lad21cd, "^[A-Z][0-9]+")
/*Drop Northern Ireland*/ 
drop if regexm(lad21cd, "^N")
save "$data/lad1121E.dta", replace 

import delimited "$lookups/PCD_OA_LSOA_MSOA_LAD_MAY20_UK_LU.csv", /// 
	delimiter(comma) encoding(UTF-8) clear 
rename ladcd lad20cd
bysort lsoa11cd lad20cd: gen f = _n == 1 
keep if f 
keep lsoa11cd lad20cd

keep if regexm(lad20cd, "^[A-Z][0-9]+")
/*Drop Northern Ireland*/ 
drop if regexm(lad20cd, "^N")

bys lsoa11cd: gen Nlsoa = _N 
tab Nlsoa 

keep lsoa11cd lad20cd

merge 1:1 lsoa11cd using "$data/lad1121E.dta", nogen 
/*
Only matches England, there have been no changes in Wales and Scotland though
*/
replace lad21cd = lad20cd if missing(lad21cd)
/*
Drop Isle of Man and Channel Islands
*/
drop if inlist(lad21cd, "M99999999", "L99999999") 

preserve 
	bys lad21cd lad20cd: gen f = _n == 1 
	keep if f 
	keep lad21cd lad20cd
	merge m:1 lad21cd using "$data/LAD21.dta", nogen 
	replace lad20cd = lad21cd if missing(lad20cd)
	bys lad21cd: gen N21 = _N 
	bys lad20cd: gen N20 = _N 
	/*
	Map is many-to-one
	*/
	tab N21
	tab N20
	keep lad21cd lad20cd
	save "$data/LAD20toLAD21.dta", replace 
restore 

keep lsoa11cd lad21cd
save "$data/LSOA11toLAD21.dta", replace 

/*******************************************************************************
LAD11 to LAD21
*******************************************************************************/
/****************
LSOA 11 to LAD 11 
*****************/
/*
Scotland 
*/
import excel "$lookups/OA_DZ_IZ_2011.xlsx", sheet("OA_DZ_IZ_2011 Lookup") clear
keep A B 
rename A oa 
rename B lsoa11cd
keep if regexm(lsoa11cd, "S[0-9]+")
tempfile oatolsoa
save `oatolsoa'

import excel "$lookups/geog-2011-cen-supp-info-oldoa-newoa-lookup.xls", /// 
	sheet("2011OA_Lookup") clear
keep B C
rename B oa
rename C lad11cd
keep if regexm(lad11cd, "S[0-9]+")

merge 1:1 oa using `oatolsoa', nogen 
bys lad11cd lsoa11cd: gen f = _n == 1
keep if f
drop f oa
tempfile s11 
save `s11'

/*
England
*/
import delimite "$lookups/LSOA11toLAD11_EW.csv", delimiter(comma) encoding(UTF-8) clear 
bysort lsoa11cd lad11cd: gen f = _n == 1 
keep if f 
keep lsoa11cd lad11cd
append using `s11'

merge 1:1 lsoa11cd using "$data/LSOA11toLAD21.dta", nogen 
/*
Is the mapping one to one?
*/
bys lad11cd lad21cd: gen f = _n == 1 
keep if f 

merge m:1 lad21cd using "$data/LAD21.dta", nogen 
replace lad11cd = lad21cd if missing(lad11cd)
bys lad11cd: gen n11 = _N 
bys lad21cd: gen n21 = _N
tab n11
tab n21
keep lad11cd lad21cd

/*2011-2020 is many-to-one, this is fine*/ 
save "$data/LAD11toLAD21.dta", replace

/*******************************************************************************
LAD to NUTS3 / ITL3
*******************************************************************************/
import excel "$lookups/LAD21_LAU121_ITL321_ITL221_ITL121_UK_LU.xlsx", /// 
	sheet("LAD21_LAU121_ITL21_UK_LU") first clear 
rename *, low
/*
London to a single division 
*/
replace itl321cd = "TLI" if regexm(itl321cd, "^TLI")
bys lad21cd itl321cd: gen f = _n == 1 
keep if f 
drop f 
keep lad21cd itl321cd

/*
There are some LAD in Scotland mathing into multiple NUTS3 
*/ 
keep lad21cd itl321cd 
bys lad21cd: gen N = _n
bys lad21cd: gen weight = 1 / _N 
reshape wide itl321cd@ weight@, i(lad21cd) j(N)

save "$data/LAD21toITL3.dta", replace 

/*******************************************************************************
NUTS3 to Region 
*******************************************************************************/
import excel "$lookups/LAD21_LAU121_ITL321_ITL221_ITL121_UK_LU.xlsx", /// 
	sheet("LAD21_LAU121_ITL21_UK_LU") first clear 
rename *, low
/*
London to a single division 
*/
replace itl321cd = "TLI" if regexm(itl321cd, "^TLI")
bys itl321cd itl121cd: gen f = _n == 1 
keep if f 
keep itl321cd itl121cd

gen gor9d = ""
replace gor9d = "E12000001" if itl121cd == "TLC"
replace gor9d = "E12000002" if itl121cd == "TLD"
replace gor9d = "E12000003" if itl121cd == "TLE"
replace gor9d = "E12000004" if itl121cd == "TLF"
replace gor9d = "E12000005" if itl121cd == "TLG"
replace gor9d = "E12000006" if itl121cd == "TLH"
replace gor9d = "E12000007" if itl121cd == "TLI"
replace gor9d = "E12000008" if itl121cd == "TLJ"
replace gor9d = "E12000009" if itl121cd == "TLK"
replace gor9d = "W99999999" if itl121cd == "TLL"
replace gor9d = "S99999999" if itl121cd == "TLM"
replace gor9d = "N99999999" if itl121cd == "TLN"
keep itl321cd gor9d

gen D = 1 
reshape wide D@, i(gor9d) j(itl321cd, s)

save "$data/GOR9DtoITL3.dta", replace 

use "$data/GOR9DtoITL3.dta", clear
reshape long D@, i(gor9d) j(itl321cd, s)
keep if D == 1
drop D
save "$data/ITL3toGOR9D.dta", replace 

/*******************************************************************************
ITL3 to best fit TTWA 
*******************************************************************************/
import excel using "$ladttwa/2021la2011ttwalookupv2.xlsx", /// 
	sheet("2021 LAs by 2011 TTWAs") clear
replace A = A[_n - 1] if A == ""
keep if G != "" & regexm(A, "^[A-Z][0-9]+")
compress
keep A D C F
destring C F, replace
rename A lad21cd
rename D ttwa 
rename C ladpop 
rename F ttwapop
merge m:1 lad21cd using "$data/LAD21toITL3.dta"
keep if _merge == 3
drop _merge 
reshape long itl321cd@ weight@, i(lad21cd ttwa ladpop ttwapop) j(tmp)
keep if !missing(weight)
foreach v of varlist *pop { 
	replace `v' = `v' * weight
}
collapse (sum) *pop, by(itl321cd ttwa)
bys itl321cd: egen pop = total(ladpop)
g sh = ttwapop / pop
su sh
bys itl321cd sh: g slct = 1 == _n
bys itl321cd: replace slct = sum(slct)
bys itl321cd: g tokeep = slct == slct[_N]
keep if tokeep == 1
bys itl321cd: g N = _N
tab N
keep itl321cd ttwa
save "$data/ITL3toTTWA.dta", replace 

