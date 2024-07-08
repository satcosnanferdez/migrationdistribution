/*******************************************************************************
NUTS3 INCOME COMPONENTS 
*******************************************************************************/
forvalue t = 6 / 15 {
	if(`t' == 6) local nm "gvainc"
	if(`t' == 7) local nm "coe"
	if(`t' == 8) local nm "mincome"
	if(`t' == 9) local nm "rentincome"
	if(`t' == 10) local nm "nonmcons"
	if(`t' == 11) local nm "holdgain"
	if(`t' == 12) local nm "tradprofit"
	if(`t' == 13) local nm "tradsur"
	if(`t' == 14) local nm "prodtax"
	if(`t' == 15) local nm "prodsub"
	
	import excel "$gva/gvaincome.xls", sheet("Table `t'") clear
	foreach v of varlist * { 
		if(inlist("`v'", "B", "D", "A")) continue 
		tostring `v', replace 
		if(!regexm(`v'[2], "^[0-9]+")) { 
			continue 
		}
		local nname = `v'[2]
		di "`nname'"
		qui rename `v' `nm'`nname'
	}
	keep if D == "All"
	keep if A == "NUTS3" | (A == "UK" & !regexm(C, "less")) | B == "UKI"
	drop if regexm(B, "UKI[0-9]+")
	drop C D E A 
	rename B nuts318cd
	keep `nm'* nuts318cd
	reshape long `nm'@, i(nuts318cd) j(year)
	destring `nm', replace 
	save "$data/NUTS3`nm'.dta", replace 
}
use "$data/NUTS3gvainc.dta", clear 
forvalue t = 7 / 15 {
	if(`t' == 7) local nm "coe"
	if(`t' == 8) local nm "mincome"
	if(`t' == 9) local nm "rentincome"
	if(`t' == 10) local nm "nonmcons"
	if(`t' == 11) local nm "holdgain"
	if(`t' == 12) local nm "tradprofit"
	if(`t' == 13) local nm "tradsur"
	if(`t' == 14) local nm "prodtax"
	if(`t' == 15) local nm "prodsub"
	merge 1:1 nuts318cd year using "$data/NUTS3`nm'.dta", nogen 
	rm "$data/NUTS3`nm'.dta"
}
replace year = 2017 if year == 20173

preserve 
	keep if nuts318cd == "UK"
	gen gos = tradprofit + tradsur + nonmcons + rentincome - holdgain
	gen lc = (coe + coe / (coe + gos) * mincome) 
	keep year coe lc
	save "$data/COEnational.dta", replace 
restore 
	
drop if nuts318cd == "UK"

gen itl321cd = regexr(nuts318cd, "UK", "TL")
replace itl321cd = "TLK24" if itl321cd == "TLK21" /*Bournemonth and Poole*/ 
replace itl321cd = "TLK25" if itl321cd == "TLK22" /*Dorset*/ 
	
gen gos = tradprofit + tradsur + nonmcons + rentincome - holdgain
gen lc = (coe + coe / (coe + gos) * mincome) 

save "$data/ITL3igva.dta", replace 

/*******************************************************************************
Constant prices gva 
*******************************************************************************/
import excel "$gva/gvabalanced.xlsx", sheet("Table3b") clear	
foreach v of varlist * { 
	if(inlist("`v'", "B", "D", "A")) continue 
	tostring `v', replace 
	if(!regexm(`v'[2], "^[0-9]+")) { 
		continue 
	}
	replace `v' = regexs(1) if regexm(`v', "([0-9]+)[^0-9]*") in 2
	local nname = `v'[2]
	di "`nname'"
	qui rename `v' gvacon`nname'
}
keep if C == "Total"
drop D C B
rename A itl
reshape long gvacon@, i(itl) j(year)
destring gvacon, replace 
keep if regexm(itl, "^TL")
rename itl itl321cd
	
/*
Drop Northern Ireland
*/
drop if regexm(itl321cd, "^TLN")

/*
London to a single division
*/
replace itl321cd = "TLI" if regexm(itl321cd, "^TLI")
	
collapse (sum) gvacon, by(itl321cd year) 

save "$data/ITL3gvacon.dta", replace 

/*******************************************************************************
Current prices gva 
*******************************************************************************/
import excel "$gva/gvabalanced.xlsx", sheet("Table3c") clear	
foreach v of varlist * { 
	if(inlist("`v'", "B", "D", "A")) continue 
	tostring `v', replace 
	if(!regexm(`v'[2], "^[0-9]+")) { 
		continue 
	}
	replace `v' = regexs(1) if regexm(`v', "([0-9]+)[^0-9]*") in 2
	local nname = `v'[2]
	di "`nname'"
	qui rename `v' gvacur`nname'
}
keep if C == "Total"
drop D C B
rename A itl
reshape long gvacur@, i(itl) j(year)
destring gvacur, replace 
keep if regexm(itl, "^TL")
rename itl itl321cd
	
/*
Drop Northern Ireland
*/
drop if regexm(itl321cd, "^TLN")

/*
London to a single division
*/
replace itl321cd = "TLI" if regexm(itl321cd, "^TLI")
	
collapse (sum) gvacur, by(itl321cd year) 

merge 1:1 itl321cd year using "$data/ITL3gvacon.dta", nogen 
g def = gvacon / gvacur 
*drop gva*

/*
Shift base to 2015 
*/
bys itl321cd: g tmp = def if year == 2015 
bys itl321cd (tmp): replace tmp = tmp[1]
replace def = def / tmp 
drop tmp 

merge 1:1 itl321cd year using "$data/ITL3igva.dta", 
tab year _merge 
keep if _merge == 3 
drop _merge 

rm "$data/ITL3gvacon.dta"
save "$data/GVAcomponents.dta", replace 




