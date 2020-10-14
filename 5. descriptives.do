* This version: September 2019
* First version: September 2019


clear*
cd $clean

cap log close
local date = c(current_date)
log using "$results/descriptives_`date'", text replace
	
*------------------------
* 1. Regression variables
*------------------------
// regressions variables
use gravity_hs6_panel, clear
	tabstat v dist interm diff_con contig comlang colony rta, statistics(N mean median sd min max) save
	return list
	putexcel set sumstats_RegressionVars.xlsx, replace
	putexcel A1 = matrix(r(Stat2)), names
	
	su v dist interm diff_con contig comlang colony rta, d
	
	forvalues t = 1998 (6) 2011 {
		su v dist contig comlang colony rta if t==`t', d
	}		
	
*------------	
* 2. products
*------------
use gravity_hs6_panel, clear
keep if t == 2011

	distinct hs6
	distinct hs6 if bec_class =="Intermediate"
	distinct hs6 if bec_class =="Consumption"
	distinct hs6 if bec_class =="Capital"
	
	table bec_class hs6
	tab bec_class
	table diff_con intermediate
	
*-----------------	
* 3. raw materials	
*-----------------
use gravity_hs6_panel, clear
	tab raw
	
	// raw, intermediate and homog
	preserve
		keep if raw_mat ==1 & intermediate == 1 & diff_con==0
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore
	
	// raw, intermediate and diff
	preserve
		keep if raw_mat ==1 & intermediate == 1 & diff_con==1
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore
	
		// raw, final and homog
	preserve
		keep if raw_mat ==1 & intermediate == 0 & diff_con==0
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore
	
	// raw, final and diff
	preserve
		keep if raw_mat ==1 & intermediate == 0 & diff_con==1
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore

// find descriptions
use $clean/prod_classes, clear
	list if hs6 == 90111
	list if hs6 == 120991
	list if hs6 == 740400
	
	list if hs6 == 121190
	list if hs6 == 701092
	list if hs6 == 10600
	
	list if hs6 == 30420
	list if hs6 == 30613
	list if hs6 == 70990
	
	list if hs6 == 30379
	list if hs6 == 30490
	list if hs6 == 30374
	
*------------
* 4. 4 groups	
*------------
use gravity_hs6_panel, clear
	
	// intermediate and homog
	preserve
		keep if intermediate == 1 & diff_con==0
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore
	
	// intermediate and diff
	preserve
		keep if intermediate == 1 & diff_con==1
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore
	
	// final and homog
	preserve
		keep if intermediate == 0 & diff_con==0
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore
	
	// final and diff
	preserve
		keep if intermediate == 0 & diff_con==1
		fcollapse (count) nobs = hs6, by(hs6) fast
		gsort -nobs
		list in 1/3
	restore

// find descriptions
use $clean/prod_classes, clear
	list if hs6 == 392190
	list if hs6 == 481910
	list if hs6 == 481920
	
	list if hs6 == 847330
	list if hs6 == 870899
	list if hs6 == 732690
	
	list if hs6 == 170490
	list if hs6 == 220421
	list if hs6 == 380810
	
	list if hs6 == 940360
	list if hs6 == 610910
	list if hs6 == 300490

clear
exit	
	
	
	
