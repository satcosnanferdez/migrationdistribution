/*******************************************************************************
Get productivity measures from ONS 
*******************************************************************************/
foreach s in "B4" "Productivity Jobs" "Productivity Hours" { 
	if("`s'" == "B4") local nm "prod"
	if("`s'" == "Productivity Jobs") local nm "jobs"
	if("`s'" == "Productivity Hours") local nm "hours"
	import excel "$gva/itlproductivity.xls", sheet("`s'") clear
	foreach v of varlist * { 
		if(inlist("`v'", "A", "B", "C")) continue 
		cap tostring `v', replace 
		if(!regexm(`v'[4], "^[0-9]+")) { 
		continue 
	}
	local nname = `v'[4]
	di "`nname'"
	qui rename `v' `nm'`nname'
	}
	keep if A == "ITL3" | A == "UK" | B == "TLI"
	drop if regexm(B, "TLI[0-9]+")
	drop A 
	rename B itl321cd
	rename C itl321nm
	reshape long `nm'@, i(itl321cd) j(year)
	destring `nm', replace force 
	/*Clean unused columns*/ 
	foreach v of varlist * {
		if(regexm("`v'", "[A-Z]")) drop `v'
	}
	save "$data/tmp`nm'", replace 
}

use "$data/tmpprod.dta", clear 
rm "$data/tmpprod.dta"
foreach nm in "jobs" "hours" {
	merge 1:1 year itl321cd using "$data/tmp`nm'", /// 
	keepusing(`nm') nogen 
	rm "$data/tmp`nm'.dta"
}
preserve 
	keep if itl321cd == "UKX"
	save "$data/ProdNational.dta", replace 
restore 

save "$data/Productivity.dta", replace 


	


