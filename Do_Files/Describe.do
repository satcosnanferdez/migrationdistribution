/*******************************************************************************
Immigrantion vs Labour Productivity / Labour Share 
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
xtset locid year 

g D10y = S10.y 
g D10yWB2 = S10.yWB2 
g D10x = S10.xsh 

twoway /// 
	(scatter D10y D10x [aw = weight], ms(oh) mcol(black)) /// 
	(lfit D10y D10x [aw = weight], lcol(gs7)), /// 
	legen(off) /// 
	xtitle("Migrant Share" "(Decennial Changes)", size(vlarge)) /// 
	ytitle("(log-)Productivity" "(Decennial Changes)", size(vlarge))
graph export "$plots/ProductivityVSImmigration.eps", replace 

reg D10y D10x [aw = weight], clust(locid)
local b = string(_b[D10x], "%9.3f")
local stde = e(V)[1,1]
local stde string(sqrt(`stde'), "%9.3f")
local b = string(_b[D10x], "%9.3f")
file open myfile using "$tables/ProductivityVSImmigration.text", write replace
file write myfile %9.3f (`b')
file close myfile
local b = string(_b[D10x] * 10, "%12.0fc")
file open myfile using "$tables/ProductivityVSImmigration10p.text", write replace
file write myfile %12.0fc (`b')
file close myfile
file open myfile using "$tables/ProductivityVSImmigrationStdEr.text", write replace
file write myfile %9.3f (`stde')
file close myfile

twoway /// 
	(scatter D10yWB2 D10x [aw = weight], ms(oh) mcol(black)) /// 
	(lfit D10yWB2 D10x [aw = weight], lcol(gs7)), /// 
	legen(off) /// 
	xtitle("Migrant Share" "(Decennial Changes)", size(vlarge)) /// 
	ytitle("(log-)Labour Share" "(Decennial Changes)", size(vlarge))
graph export "$plots/LShareVSImmigration.eps", replace 

reg D10yWB2 D10x [aw = weight], clust(locid)
local stde = e(V)[1,1]
local stde string(sqrt(`stde'), "%9.3f")
local b = string(_b[D10x], "%9.3f")
file open myfile using "$tables/LShareVSImmigration.text", write replace
file write myfile %9.3f (`b')
file close myfile
local b = string(_b[D10x] * 10, "%12.0fc")
file open myfile using "$tables/LShareVSImmigration10p.text", write replace
file write myfile %12.0fc (`b')
file close myfile
file open myfile using "$tables/LShareVSImmigrationStdEr.text", write replace
file write myfile %9.3f (`stde')
file close myfile

/*******************************************************************************
Table with means, sd, min and max  
*******************************************************************************/
use "$data/AnalysisData.dta", clear 
g yWB2_lvl = exp(yWB2)
g lWB2_lvl = exp(lWB2)	
xtset locid year 
g jobsK = jobs / 100e3

foreach v in y lnJ yWB2 lWB2 { 
	g D10`v' = S10.`v'
}
foreach v of varlist D10* { 
	replace `v' = . if missing(D10y)
}

eststo base: estpost su /// 
	prodcon jobsK lWB2_lvl yWB2_lvl xsh /// 
	D10y D10lnJ D10yWB2 D10lWB2 D10xsh ///
	[aweight = weight]
	
su xsh [aw = weight]
local mean = r(mean)
file open myfile using "$tables/XSHmean.tex", write replace
file write myfile %9.3f (`mean')
file close myfile

su xsh [aw = weight]
local sd = r(sd)
local sd = `sd' ^ 2
file open myfile using "$tables/XSHsd.tex", write replace
file write myfile %9.3f (`sd')
file close myfile

distinct itl321cd 
local Nloc = r(ndistinct)
local obs = r(N)
distinct year
local Nt = r(ndistinct)

#delimit ;
estout base 
	using "$tables/Describe.tex",  
	cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3))") 
	varlabels(	prodcon "Labour Productivity \hspace{75pt} " 
			jobsK "Jobs (in 100K)"
			lWB2_lvl "Labour Cost"  
			yWB2_lvl "Labour Share" 
			xsh "\addlinespace Immigrant Share"
			D10y "\midrule
				& \multicolumn{4}{c}{Decennial Changes} \\ 
				\cmidrule(lr){2-5}
				(log-)Labour Productivity"
			D10lnJ 	"(log-)Jobs"
			D10lWB2 "(log-)Labour Cost"  
			D10yWB2 "(log-)Labour Share"
			D10xsh "\addlinespace Immigrant Share") 
	collabels("Mean" "Std.dev." "Min" "Max")  
	mlabels(, none) 
	posthead(\midrule
		& \multicolumn{4}{c}{2002-2015 Averages} \\
		\cmidrule(lr){2-5})
	prefoot(\midrule 
		Years 		& \multicolumn{4}{c}{`Nt'} \\
		Regions 	& \multicolumn{4}{c}{`Nloc'} )
	replace
	eqlabels(,none)
	style(tex)
	type
;
#delimit cr

/*
Immigrant instrument 
*/
eststo base: estpost su /// 
	z L10z ///
	[aweight = weight]
	
#delimit ;
estout base 
	using "$tables/DescribeZ.tex",  
	cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3))") 
	varlabels(	
			z "Shift-Share Migrant Shock \hspace{75pt} " 
			L10z "Lag Shift-Share Migrant Shock"
			)
	collabels(, none)  
	mlabels(, none) 
	replace
	eqlabels(,none)
	style(tex)
	type
;
#delimit cr

/*
Statistics to be incorporated to text 
*/
su xsh [aw = weight], mean 
local AVxsh = string(r(mean) * 100, "%12.0fc")
file open myfile using "$tables/AvgXsh.text", write replace
file write myfile %12.0fc (`AVxsh')
file close myfile

su xsh [aw = weight] if london, mean 
local AVxsh = string(r(mean) * 100, "%12.0fc")
file open myfile using "$tables/AvgXshLondon.text", write replace
file write myfile %12.0fc (`AVxsh')
file close myfile

su D10xsh [aw = weight]
local AVxsh = string(r(mean) * 100, "%12.0fc")
local SDxsh = string(r(sd) * 100, "%12.0fc")
file open myfile using "$tables/AvgD10Xsh.text", write replace
file write myfile %12.0fc (`AVxsh')
file close myfile
file open myfile using "$tables/SD10Xsh.text", write replace
file write myfile %12.0fc (`SDxsh')
file close myfile

count if D10xsh > 0 & !missing(D10xsh)
local pos = r(N)
count if !missing(D10xsh)
local ppos = string(`pos' / r(N) * 100, "%12.0fc")
file open myfile using "$tables/PercPositive.text", write replace
file write myfile %12.0fc (`ppos')
file close myfile

count if year == 2015 & S13.xsh < 0
local negg = string(r(N), "%12.0fc")
file open myfile using "$tables/NegativeD13Xsh.text", write replace
file write myfile %12.0fc (`negg')
file close myfile

distinct itl321cd
local n = string(r(ndistinct), "%12.0fc")
file open myfile using "$tables/NRegions.text", write replace
file write myfile %12.0fc (`n')
file close myfile

/*******************************************************************************
Actual share vs Instrument 
*******************************************************************************/
use "$data/AnalysisData.dta", clear 

scatter D10xsh z, mcol(black) /// 
	xtitle("Shift-Share") /// 
	ytitle("Decennial Changes in Migrant Share") ///
	xlab(0(.05).2) ylab(0(.05).2)
graph export "$plots/XshVSz.eps", replace 
 	
