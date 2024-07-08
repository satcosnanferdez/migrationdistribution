clear all
set more off, permanently

/*******************************************************************************
Specifications 
*******************************************************************************/
global FE "year"
global X "L10D10emp L10D10empdens D10zEmp L10D10zEmp"
global BX "$X L10D10popL L10D10xsh"

/*******************************************************************************
Directories
*******************************************************************************/
/*
ssc install kountry

* Install ftools 
cap ado uninstall ftools
net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

* Install reghdfe
cap ado uninstall reghdfe
net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

* Install ivreg2, the core package
cap ado uninstall ivreg2
ssc install ivreg2

* Install this package ivreghdfe
cap ado uninstall ivreghdfe
net install ivreghdfe, from("https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/")

ssc install ranktest
ssc install distinct
ssc install estout

/*
Settings for plots
*/
ssc install grstyle

/*
AKM inference
*/
ssc install reg_ss
ssc install ivreg_ss
*/
grstyle init
grstyle set plain, nogrid

/*
Root directory 
*/
global root "/your/path/here"


/*
Post-processed data 
*/
global data "$root/Data/Mod"
shell mkdir $data 

/*
Outputs: Tables and Plots 
*/
shell mkdir "$root/Latex"

global tables "$root/Latex/Tables"
shell mkdir $tables

global plots "$root/Latex/Plots"
shell mkdir $plots

/*
Programs 
*/
global prog "$root/Do_Files"
sysdir set PERSONAL "$prog"

/**************************************
Raw data directories
***************************************/
/*
Root directory 
*/
global origdata "$root/Data/Orig"

/*
Geographical lookups
*/
global lookups "$origdata/Lookup"

/*
Data from the 1991 Census 
*/
global cens91 "$origdata/Census_1991"

/*
Data from the 2001 Census 
*/
global cens01 "$origdata/Census_2001"

/*
Regional Accounts 
*/
global gva "$origdata/GVA"

/*
Population by country of birth at LAD 
*/
global ladmigrant "$origdata/LAD_Migrants"

/*
UN migration data 
*/
global un "$origdata/UN"

/*
Annual Population Survey 
*/
global aps "$origdata/APS"

/*
LFS data 
*/
global lfs "$origdata/LFS"

/*
AES data 
*/
global aes "$origdata/AES"

/*
ABI data 
*/
global abi "$origdata/ABI"

/*
BRES data 
*/
global bres "$origdata/BRES"

/*
Population for pre-period at UA level 
*/
global uamig "$origdata/UA_Migrants"

/*
Distance data 
*/ 
global gis "$origdata/ArcGIS"

/*
Industrial look-up tables 
*/
global siclook "$origdata/SICLOOK"

/*
LAD to TTWA mappings 
*/
global ladttwa "$origdata/LAD_TTWA"

/*******************************************************************************
A) Preliminaries
*******************************************************************************/
/*
A.1 Get geographical lookups: LAD to NUTS3 
*/
do "$prog/GeoLookups.do"

/*
A.2 Population by country of birth from 1991 Census
*/
do "$prog/Census1991.do"

/*
A.3 Productivity 
*/
do "$prog/Productivity.do"

/*
A.4 GVA by income components
*/
do "$prog/GVAComponents.do"

/*
A.5 Current immigrant stocks 
*/
do "$prog/Immigrant_Stocks.do"

/*
A.7 Bilateral immigration stocks from UN 
*/
do "$prog/UN_MStocks.do"

/*
A. National level migrant stocks by country of birth from LFS data 
*/
do "$prog/LFS_Migrants.do"

/*
A.9 Combine 1991 populations with current stocks to compute shift-share
*/
do "$prog/Instrument_LFS_TTWA.do"
do "$prog/Instrument_LFS.do"

/*
A.12 Occupation Data 
*/
do "$prog/Occupation_Data.do"

/*
A.15 ITL3 Employment levels 1991-2015
*/
do "$prog/Employment.do"

/*
Employment shift-share 
*/ 
do "$prog/Employment_ShiftShare.do"

/*
Compile dataset
*/ 
do "$prog/Compile_Dataset.do"

/*******************************************************************************

*******************************************************************************/
/*
Describe data 
*/
do "$prog/Describe.do"

/*
Balancing, first-stage and main estimates for the main instrument, the 
national level shift-share and shift-share using EU enlargements
*/
do "$prog/Main_Estimates.do"

/*
Robustness to changes in measurement of LHS, specification, weights and 
instrument(s)
*/
do "$prog/Robustness.do"

/*
Rotemberg 
*/
do "$prog/Rotemberg_Weights.do"

/*
Jobs Growth 
*/
do "$prog/JobsGrowth.do"

/*
Changes in occupation composition 
*/ 
do "$prog/Occupation_Composition.do"

/*
Estimates with AKM standard errors
*/ 
do "$prog/AKMStdErr.do"
