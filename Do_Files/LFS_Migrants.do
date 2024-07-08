/*******************************************************************************
LFS data migrants at national level 
*******************************************************************************/
/*******************************************************************************
1991
*******************************************************************************/
use "$lfs/LFS91/LFS91.dta", clear 
drop if country == 95 
count if country < 0

g cameyr = 1900 + arrival if arrival > 0 & arrival <= 91
replace cameyr = 1991 - age if arrival == -9
g yearsinUK = 1991 - cameyr if cameyr > 0
count if yearsinUK < 0 
if(r(N) > 0) { 
    disp as error "yearsinUK < 0"
	continue, break 
}
replace ftedage = 0 if ftedage == 99 
replace ftedage = . if ftedage < 0 | ftedage >= 98 
rename ftedage edage
collapse (sum) pop = pwt03 (count) Ncell = pwt03 if age >= 16 & age <= 64, by(country age cameyr edage)

tempfile tmp
save `tmp'

uselabel country, clear
keep value label
replace label = strlower(label)
replace label = "germany" if regexm(label, "german")
replace label = "ireland" if regexm(label, "irish republic")
replace label = "italy" if regexm(label, "italy")
replace label = "china" if regexm(label, "china")
replace label = "portugal" if regexm(label, "portugal")
replace label = "south africa" if regexm(label, "south africa")
replace label = "spain" if regexm(label, "spain")
replace label = "uk" if regexm(label, "uk")
replace label = "france" if regexm(label, "france")

kountry label, from(other) stuck marker
tab label if MARKER == 0
keep if MARKER == 1 
rename _ISO3N_ iso3n 
drop MARKER  
kountry iso3n, from(iso3n) to(iso2c)
rename _ISO2C_ iso2c 
drop if iso2c == ""
keep value iso2c 
tempfile map91
save `map91'
rename value country
merge 1:m country using `tmp'
replace iso2c = "Other" if _merge == 2

collapse (sum) pop Ncell, by(iso2c cameyr age edage)
g year = 1991 
tempfile dat91 
save `dat91'

use `map91', clear 
collapse (first) value, by(iso2c)
keep iso2c 
save `map91', replace 

/*******************************************************************************
1992-1999
*******************************************************************************/
local fls : dir "$lfs" dirs "*"
tempfile tmp 
tempfile lbldat
foreach f of local fls { 
	if !regexm("`f'", "[A-Za-z]+9[0-9]") | regexm("`f'", "lfs|LFS") continue 
	cap use "$lfs/`f'/`f'.dta", clear 
	rename *, lower 
	destring cryo, replace 
	*UK Born 
	replace cryo = 1 if cry == 1
	*Born in Republic of Ireland 
	replace cryo = 6 if cry == 6
	*Born in China
	replace cryo = 58 if cry == 58
	*Born in Hong Kong
	replace cryo = 36 if cry == 36

	g year = "19" + regexs(1) if regexm("`f'", "[A-Za-z]+([0-9][0-9])")
	destring year, replace 
	g quarter = regexs(1) if regexm("`f'", "([A-Za-z]+)[0-9][0-9]")
	replace quarter = strlower(quarter)

	su cameyr 
	if(r(max) > 100 & r(max) < 1992) { 
	    disp as error "cameyr over 100"
		exit 198
	}
	replace cameyr = cameyr + 1900 if cameyr > 0 & cameyr < 1000
	replace cameyr = year - age if cameyr == -9
	replace cameyr = . if cameyr > year 
	replace cameyr = . if cameyr < year - age - 1 & !missing(cameyr) & cameyr > 0
	g yearsinUK = year - cameyr if cameyr > 0
	count if yearsinUK < 0
	if(r(N) > 0) { 
	    disp as error "yearsinUK < 0"
		exit 198
	}
	count if yearsinUK > 65 & age >= 16 & age <= 64 & !missing(yearsinUK)
	if(r(N) > 0) { 
	    disp as error "yearsinUK > 65"
		exit 198
	}
	
	/*
	EDAGE == 97 := Never had education
	EDAGE == 96 := Still in education 
	*/
	replace edage = 0 if edage == 97 
	replace edage = -7  if edage == 96
	replace edage = . if edage < 0 
	
	drop if cryo < 0
	collapse (sum) pop = pwt07 (count) Ncell = pwt07 if age >= 16 & age <= 64, by(cryo year quarter cameyr age edage) 
	cap confirm file `tmp'
	if _rc { 
		save `tmp'
	}
	else { 
		append using `tmp'
	}
	save `tmp', replace 
	cap labelbook cryo
	if !_rc { 
		uselabel cryo, clear
		keep value label
		g year = "19" + regexs(1) if regexm("`f'", "[A-Za-z]+([0-9][0-9])")
		destring year, replace 
		g quarter = regexs(1) if regexm("`f'", "([A-Za-z]+)[0-9][0-9]")
		replace quarter = strlower(quarter)
		cap confirm file `lbldat'
		if _rc & year[1] == 1999 & quarter[1] == "jm" { 
			keep value label 
			save `lbldat'
			count 
			if(r(N) != 138) { 
				disp as error "Number of label entries != 138"
				continue, break 
			}
		}
		if !_rc { 
			continue 
		}
	}
}

/*
In spring 1993 the number of countries recorded changes, 
there are changes in 98 and 1999 too. This implies that only 
records with codes up to 93 and for individual countries are homogeneous. 
*/
use `tmp', clear
replace cryo = 93 if cryo > 93
collapse (sum) pop Ncell, by(cryo year quarter cameyr age edage)
g value = cryo 
merge m:1 value using `lbldat'
count if _merge == 1 
if(r(N) > 0) { 
	disp as error "non matched labels"
	exit 
}
keep if _merge == 3 
drop _merge 

replace label = strlower(label)
replace label = "australia" if regexm(label, "australia, tasmania")
replace label = "canada" if regexm(label, "canada, newfoundland, nova scotia")
replace label = "hong kong" if regexm(label, "hong kong, kowloon")
replace label = "ireland" if regexm(label, "ireland,republic of")
replace label = "malawi" if regexm(label, "malawi")
replace label = "philippines" if regexm(label, "phillipines")
replace label = "portugal" if regexm(label, "portugal")
replace label = "spain" if regexm(label, "spain")
replace label = "tanzania" if regexm(label, "tanzania")

preserve 
	collapse (first) value, by(label)
	kountry label, from(other) stuck marker
	tab label if MARKER == 0
	keep if MARKER == 1 
	rename _ISO3N_ iso3n 
	drop MARKER  
	kountry iso3n, from(iso3n) to(iso2c)
	rename _ISO2C_ iso2c 
	drop if iso2c == ""
	keep label iso2c 
	tempfile map92
	save `map92'
restore 
merge m:1 label using `map92'
replace iso2c = "Other" if _merge == 1
count if _merge == 2 
if(r(N) > 0) { 
	disp as error "some _merge == 2"
	exit 
}
drop _merge 
collapse (sum) pop Ncell, by(iso2c year quarter cameyr age)
tempfile dat92
save `dat92'

/*******************************************************************************
2000 - 2015 
*******************************************************************************/
local fls : dir "$lfs" dirs "*"
tempfile tmp
tempfile tmp07 
tempfile lbldat
tempfile lbldat07
foreach f of local fls { 
	if !regexm("`f'", "[A-Za-z]+[0-1][0-9]") continue 
	cap use "$lfs/`f'/`f'.dta", clear 
	rename *, lower 
	
	g year = "20" + regexs(1) if regexm("`f'", "[A-Za-z]+([0-9][0-9])")
	destring year, replace 
	g quarter = regexs(1) if regexm("`f'", "([A-Za-z]+)[0-9][0-9]")
	replace quarter = strlower(quarter)
	
	replace cameyr = year - age if cameyr == -9
	replace cameyr = . if cameyr < year - age - 1 & !missing(cameyr) & cameyr > 0
	replace cameyr = . if cameyr > year 
	g yearsinUK = year - cameyr if cameyr > 0
	count if yearsinUK < 0
	if(r(N) > 0) { 
	    disp as error "yearsinUK < 0"
		exit 198
	}
	count if yearsinUK > 65 & age >= 16 & age <= 64 & !missing(yearsinUK)
	if(r(N) > 0) { 
	    disp as error "yearsinUK > 65"
		exit 198
	}
	
	/*
	EDAGE == 97 := Never had education
	EDAGE == 96 := Still in education 
	*/
	replace edage = 0 if edage == 97 
	replace edage = -7  if edage == 96
	replace edage = . if edage < 0 
		
	drop if cryox < 0 
	collapse (sum) pop = pwt (count) Ncell = pwt if age >= 16 & age <= 64, by(year quarter cryox cameyr age edage)
	if(year[1] < 2007) { 
		cap confirm file `tmp'
		if _rc { 
			save `tmp'
		}
		else { 
			append using `tmp'
		}
		save `tmp', replace 
		cap confirm file `lbldat'
		if _rc { 
			uselabel CRYOX, clear
			drop if value < 0 | value >= 103
			save `lbldat'
		}
	}
	else { 
		cap confirm file `tmp07'
		if _rc { 
			save `tmp07'
		}
		else { 
			append using `tmp07'
		}
		save `tmp07', replace 
		cap confirm file `lbldat07'
		if _rc {
			uselabel CRYOX7, clear
			drop if value < 0 
			save `lbldat07'
		}	
	}
}
foreach p in "" "07" { 
	use `tmp`p'', clear 
	g value = cryox
	merge m:1 value using `lbldat`p''
	if("`p'" == "07") { 
		replace label = "curacao" if value == 531 
		replace label = "south sudan" if value == 728
		/*
		For cryox07 there is a bunch of undocumented entries...  
		*/
		keep if _merge == 1 | _merge == 3 
		replace label = strlower(label)
		replace label = "spain" if regexm(label, "canary islands")
		replace label = "spain" if regexm(label, "spain ")
		replace label = "united kingdom" if regexm(label, "united kingdom")
		replace label = "democratic republic of the congo" if regexm(label, "congo \(democratic republic\)")
		replace label = "hong kong" if regexm(label, "hong kong")
		replace label = "macau" if regexm(label, "macao")
		replace label = "reunion" if regexm(label, "r.nion")
	}
	count if _merge != 3
	if(r(N) > 0 & "`p'" == "") { 
		disp as error "non matched labels"
		exit 
	}
	if("`p'" == "") { 
		replace label = strlower(label)
		replace label = "colombia" if regexm(label, "columbia")
		replace label = "ireland" if regexm(label, "irish republic")
		replace label = "italy" if regexm(label, "italy")
		replace label = "macau" if regexm(label, "macau")
		replace label = "philippines" if regexm(label, "phillippines")
		replace label = "united kingdom" if regexm(label, "uk/gb")
		replace label = "venezuela" if regexm(label, "venezuala")
	}
	drop _merge 

	preserve 
		collapse (first) value, by(label)
		kountry label, from(other) stuck marker
		tab label if MARKER == 0
		keep if MARKER == 1 
		rename _ISO3N_ iso3n 
		drop MARKER  
		kountry iso3n, from(iso3n) to(iso2c)
		rename _ISO2C_ iso2c 
		drop if iso2c == ""
		keep label iso2c 
		tempfile map`p'
		save `map`p''
	restore 
	
	merge m:1 label using `map`p''
	replace iso2c = "Other" if _merge == 1
	count if _merge == 2 
	if(r(N) > 0) { 
		disp as error "some _merge == 2"
		exit 
	}
	drop _merge 
	collapse (sum) pop Ncell, by(iso2c year quarter cameyr age edage) 
	tempfile fl`p'
	save `fl`p''
}

/*
Contries that are identifiable throughout the period 
*/
disp as error "IM IN MAP"
use `map', clear 
merge 1:1 iso2c using `map07'
keep if _merge == 3 
keep iso2c 
merge 1:1 iso2c using `map92'
keep if _merge == 3 
keep iso2c 
merge 1:1 iso2c using `map91'
keep if _merge == 3 
keep iso2c 
tempfile inner 
save `inner'

use `dat91', clear 
append using `dat92'
append using `fl'
append using `fl07'
merge m:1 iso2c using `inner'
count if _merge == 2 
if(r(N) > 0) { 
	disp as error "some _merge == 2 in inner"
	exit 
}	
replace iso2c = "Other" if _merge == 1 
collapse (sum) pop Ncell, by(iso2c year cameyr age quarter edage)

reshape wide pop@ Ncell@, i(year cameyr age quarter edage) j(iso2c, s)
reshape long pop@ Ncell@, i(year cameyr age quarter edage) j(iso2c, s)
mvencode pop, mv(0) override

save "$data/LFSCoB.dta", replace 


	
	
