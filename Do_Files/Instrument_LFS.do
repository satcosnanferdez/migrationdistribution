/*******************************************************************************
Homogenise countries of birth: 
*******************************************************************************/
use "$data/LFSCoB.dta", clear 
drop if iso2c == "GB"
collapse (sum) pop, by(iso2c year quarter)
collapse (mean) pop, by(iso2c year)
tempfile LFS
save `LFS'

collapse (first) year, by(iso2c)
keep iso2c 
merge 1:m iso2c using "$data/Census1991.dta"
keep if _merge == 3 
collapse (first) itl321cd, by(iso2c)
keep iso2c
g origin = iso2c
merge 1:m origin using "$data/UNMStocks.dta"
keep if _merge == 3 
collapse (first) destination, by(iso2c)
keep iso2c
tempfile inner 
save `inner'

count 
local N = r(N)
file open myfile using "$tables/OriginGroups.text", write replace
file write myfile %12.0fc (`N')
file close myfile

/*
Homogeneise present stocks 
*/
use `LFS', clear  
merge m:1 iso2c using `inner'
replace iso2c = "Other" if _merge == 1 
collapse (sum) popUK = pop, by(iso2c year)
save `LFS', replace 

/******************************************************************************/
use "$data/Census1991.dta", clear 
merge m:1 iso2c using `inner'
replace iso2c = "Other" if _merge == 1
collapse (sum) Mmj (first) Pj, by(iso2c itl321cd)
bys iso2c: egen Mm = total(Mmj)
bys itl321cd: egen Mj = total(Mmj)
preserve 
	g alloc = (Mmj / Mm)
	keep iso2c itl321cd alloc
	save "$data/MigrantAllocation.dta", replace 
restore 
preserve 
	g normexp = (1 / Pj) * (Mmj / Mm)
	keep iso2c itl321cd normexp 
	save "$data/Exposure.dta", replace 
restore 
g Nj = Pj - Mj 
count if Nj < 0 
if(r(N) > 0) { 
	disp as error "Negative Nj"
	exit 
}
expand 25
bys itl321cd iso2c: g year = 1990 + _n 

/*
Merge national changes 
*/
merge m:1 iso2c year using `LFS'
count if _merge != 3
if(r(N) > 0) { 
	disp as error "non-matched"
	exit 
}  
drop _merge 

egen id = group(itl321cd iso2c)

tempfile INST
save `INST'

/*
Using predicted changes based on EU expansion and 
other push factors 
*/ 
use `LFS', clear 
/*
1995 enlargement of the European Union: Austria, Finland, and Sweden
*/ 
g DEU1995 = inlist(iso2c, "AT", "FI", "SE") & year >= 1995 
/*
2004 enlargement of the European Union: 
Cyprus, Czech Republic, Estonia, Hungary, Latvia, Lithuania, 
Malta, Poland, Slovakia and Slovenia.
*/ 
#delimit ; 
g DEU2004 = ( 
				inlist(iso2c, "CY", "CZ", "EE", "HU") | 
				inlist(iso2c, "LV", "LT", "MT", "PL") | 
				inlist(iso2c, "SK", "SI")  
			)
	& year >= 2004
;
/*
2007 enlargement of the European Union: Romania & Bulgaria
*/ 
g DEU2007 = ( 
				inlist(iso2c, "RO", "BG") 
			)
	& year >= 2007
;
/*
2013 enlargement of the European Union: Croatia
NOTE Croatia is not individually identifiable in the data...
*/ 
count if iso2c == "HR";
if(r(N) > 0) { 
	disp as error "HR is in data";
	exit;
};
#delimit cr 

/*
Changes in migration flows to largest EU countries 
*/
preserve 
	use "$data/UNMStocks.dta", clear 	
	drop if origin == "GB"
	keep if inlist(destination, "HighIncome") | destination == "GB"
	g GBsotck = stock if destination == "GB"
	bys year origin (GBsotck): replace GBsotck = GBsotck[1]
	replace stock = stock - GBsotck
	keep if destination != "GB"
	drop GBsotck
	rename origin iso2c 
	reshape wide stock*, i(iso2c year) j(destination, s)
	collapse (sum) stock*, by(iso2c year)
	merge m:1 iso2c using `inner'
	replace iso2c = "Other" if _merge == 1
	drop if _merge == 2 
	collapse (sum) stock*, by(iso2c year)
	rename stock* UNstock*
	egen id = group(iso2c)
	xtset id year 
	foreach v of varlist UNstock* { 
		if(regexm("`v'", "UNstock")) { 
			local c = regexr("`v'", "UNstock", "")
			g self`c' = iso2c == "`c'"
			g D`v' = S10.`v'
			replace D`v' = . if iso2c == "`c'"	
		}
	}
	save "$data/NORMUNMStocks.dta", replace 
	keep if year >= 1991 & year <= 2015
	tempfile UN
	save `UN'
restore 
merge 1:1 iso2c year using `UN'
count if _merge != 3 
if(r(N) > 0) { 
	disp as error "non matched UN stocks"
	exit 
}
drop _merge 

/*
Prediction using averages of flows to other large 
Western European countries and EU enlargements 
*/
merge m:1 iso2c using "$gis/Distances.dta"
keep if _merge == 3 | _merge == 1 
g invdist = 1 / (distance / 100e3)
egen DTOT = rowmean(DUNstock*)
xtset id year
g lnpop = log(1 + pop)
egen UNTOT = rowmean(UNstock*)
g lnUNTOT = log(UNTOT) 
replace invdist = 0 if iso2c == "Other"
ge other = iso2c == "Other"

reg S10.pop c.invdist##c.DTOT c.other##c.DTOT DEU* 
predict D10popUN, xb
drop UNTOT

/*
Prediction using EU enlargements 
*/
reg S10.pop DEU* 
predict D10popEU, xb 

preserve 
	keep year iso2c popUK 
	rename popUK pop 
	save "$data/NationalStocks.dta", replace 
restore 

keep D10popUN D10popEU year iso2c 

preserve 
		keep D10popUN year iso2c 
		save "$data/MShocks.dta", replace 
restore 

merge 1:m year iso2c using `INST'
count if _merge != 3 & iso2c != "Other"
if(r(N) > 0) { 
	disp as error "non matched in projection"
	exit 
}
keep if _merge == 3 
drop _merge 
xtset id year 

g zLFSEU = (1 / Pj) * (Mmj / Mm) * D10popEU
g zLFSUN = (1 / Pj) * (Mmj / Mm) * D10popUN

/*
Shift-Share
*/
xtset id year 
g zLFS = (1 / Pj) * (Mmj / Mm) * S10.popUK 

preserve 
	g shares = (1 / Pj) * Mmj 
	keep year iso2c itl321cd shares
	reshape wide shares@, i(itl321cd year) j(iso2c, s)
	save "$data/shares.dta", replace
restore 

collapse (sum) z*, by(itl321cd year)
egen id = group(itl321cd)
xtset id year 

foreach x of varlist z* { 
	g L10`x' = L10.`x'
}
drop id 

save "$data/Instrument.dta", replace 



