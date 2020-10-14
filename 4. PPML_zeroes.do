* This version: September 2019
* First version: March 2019

/*______________________________________________________________________________ 
1. ... Notes ...
- This do-file runs 3 baseline specifications, but using PPML instead of OLS,
  including all zeroes to generate an extensive margin.
- The PPML panel is not run with additional zeroes. Our Linux server with 
  1TB Ram and 36 cores runs out of memory at 1.8 billion observations, 
  high-dimensional fixed effects, and non-linear estimation.
______________________________________________________________________________*/	


clear*
cd $clean

cap log close
local date = c(current_date)
log using "$results/PPML_zeroes_by_year_`date'", text replace


*---------------------------------
* 1. IG vs FG interaction, by year
*---------------------------------
global vars "contig comlang colony rta"
eststo clear
forvalues t = $start (6) $end {	
	use zeroes_hs_`t', clear
	replace v = v/1000000								// recenter to speed up convergence
		eststo: ppmlhdfe v c.lndist##i.interm $vars, a(o d hs2) vce(cluster o#d)
		eststo: ppmlhdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	}	
	esttab using "$results/PPML_zeroes_FGvsIG_by_year.csv", ///
	b(3) se(3) pr2(3) not nogaps star parentheses replace
	
*-------------------------------
* 2. Drop raw materials, by year
*-------------------------------
global vars "contig comlang colony rta"
eststo clear
forvalues t = $start (6) $end {								
	use zeroes_hs_`t', clear
	drop if raw_mat == 1
	replace v = v/1000000
		eststo: ppmlhdfe v c.lndist##i.interm $vars, a(o d hs2) vce(cluster o#d)
		eststo: ppmlhdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	}	
	esttab using "$results/PPML_zeroes_noraw_by_year.csv", ///
	b(3) se(3) pr2(3) not nogaps star parentheses replace

/*	
*--------------------------
* 3. Homog vs diff, by year
*--------------------------
global vars "contig comlang colony rta"
eststo clear
forvalues t = $start (6) $end {
	use zeroes_hs_`t', clear
	replace v = v/1000000
		eststo: ppmlhdfe v c.lndist##i.diff_con $vars, a(o d hs2) vce(cluster o#d)
		eststo: ppmlhdfe v c.lndist##i.diff_con, a(o d o#d hs2) vce(cluster o#d)
	}	
	esttab using "$results/PPML_zeroes_HOMvsDIFF_by_year.csv", ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
*/
	
*---------------------
* 4. 4 groups, by year
*---------------------
// groups are - 1: FG_hom (reference), 2: FG_diff, 3: IG_hom, 4: IG_diff
global vars "contig comlang colony rta"
eststo clear
forvalues t = $start (6) $end {			
	use zeroes_hs_`t', clear
	sort bec_class diff_con
	egen groups = group(interm diff_con)	
	replace v = v/1000000				
		eststo: ppmlhdfe v c.lndist##i.groups $vars, a(o d hs2) vce(cluster o#d)
			test lndist#2.groups = lndist#3.groups
			test lndist#2.groups = lndist#4.groups
			test lndist#3.groups = lndist#4.groups
		eststo: ppmlhdfe v c.lndist##i.groups, a(o d o#d hs2) vce(cluster o#d)
			test lndist#2.groups = lndist#3.groups
			test lndist#2.groups = lndist#4.groups
			test lndist#3.groups = lndist#4.groups
	}	
	esttab using "$results/PPML_zeroes_4groups_by_year.csv", ///
	b(3) se(3) pr2(3) not nogaps star parentheses replace
	
cap log close
clear
