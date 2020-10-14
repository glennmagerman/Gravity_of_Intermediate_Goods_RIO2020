* This version: September 2019
* First version: March 2019

/*______________________________________________________________________________ 
1. ... Notes ...
- This do-file runs 3 baseline specifications: interaction, no raw, 4 groups.
- (1)-(3) are cross-sections over the years 1998-2011. (4)-(6) are panel.
- For cross-sections, we use the most stringent FE specifications.
- For panels, we show additional results with less stringent FE specifications.
- For homogeneous vs differentiated, we use conservative version of Rauch.
______________________________________________________________________________*/	

clear*
cd $clean

cap log close
local date = c(current_date)
log using "$results/OLS_by_year_`date'", text replace
	
*---------------------------------
* 1. IG vs FG interaction, by year
*---------------------------------
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear
	eststo clear
	forvalues t = $start (3) $end {
		eststo: reghdfe lnv c.lndist##i.interm $vars if t == `t', a(o d hs2) vce(cluster o#d)
		eststo: reghdfe lnv c.lndist##i.interm if t == `t', a(o d o#d hs2) vce(cluster o#d)
	}	
	esttab using "$results/OLS_FGvsIG_by_year.csv", ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace

*-------------------------------
* 2. Drop raw materials, by year
*-------------------------------
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear
	eststo clear
	drop if raw_mat == 1
	forvalues t = $start (3) $end {
		eststo: reghdfe lnv c.lndist##i.interm $vars if t == `t', a(o d hs2) vce(cluster o#d)
		eststo: reghdfe lnv c.lndist##i.interm if t == `t', a(o d o#d hs2) vce(cluster o#d)
	}	
	esttab using "$results/OLS_noraw_by_year.csv", ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
	
*--------------------------
* 3. Homog vs diff, by year
*--------------------------
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear
	eststo clear
	forvalues t = $start (3) $end {
		eststo: reghdfe lnv c.lndist##i.diff_con $vars if t == `t', a(o d hs2) vce(cluster o#d)
		eststo: reghdfe lnv c.lndist##i.diff_con if t == `t', a(o d o#d hs2) vce(cluster o#d)
	}	
	esttab using "$results/OLS_HOMvsDIFF_by_year.csv", ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
	
*---------------------
* 4. 4 groups, by year
*---------------------
// groups are - 1: FG_hom (reference), 2: FG_diff, 3: IG_hom, 4: IG_diff
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear
	eststo clear
	sort bec_class diff_con
	egen groups = group(interm diff_con)	
	
	forvalues t = $start (3) $end {	
		eststo: reghdfe lnv c.lndist##i.groups $vars if t == `t', a(o d hs2) vce(cluster o#d)
			test lndist#2.groups = lndist#3.groups
			test lndist#2.groups = lndist#4.groups
			test lndist#3.groups = lndist#4.groups
		eststo: reghdfe lnv c.lndist##i.groups if t == `t', a(o d o#d hs2) vce(cluster o#d)
			test lndist#2.groups = lndist#3.groups
			test lndist#2.groups = lndist#4.groups
			test lndist#3.groups = lndist#4.groups
	}	
	esttab using "$results/OLS_4groups_by_year.csv", ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
	
cap log close

////////////////////////////////////////////////////////////////////////////////

clear*
cd $clean

cap log close
local date = c(current_date)
log using "$results/OLS_panel_`date'", text replace

*-------------------------------
* 5. IG vs FG interaction, panel
*-------------------------------
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear
	eststo clear
	eststo: reghdfe lnv c.lndist##i.interm $vars, a(o#t d#t t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.interm $vars, a(o#t d#t hs2#t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.interm, a(o#t d#t o#d#t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.interm, a(o#t d#t o#d#t hs2#t) vce(cluster o#d)
	
	estfe *, labels(o#t "Exporter x year FE" d#t "Importer x year FE" ///
	t "Year FE" hs2#t "HS 2-digit x year FE" o#d#t "Country pair x year FE")
	esttab using "$results/OLS_FGvsIG_panel.csv", ///
	indicate(`r(indicate_fe)', labels("Yes" "")) ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
	
*-----------------------------
* 6. Drop raw materials, panel
*-----------------------------
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear 
	eststo clear
	drop if raw_mat == 1
	eststo: reghdfe lnv c.lndist##i.interm $vars, a(o#t d#t t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.interm $vars, a(o#t d#t hs2#t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.interm, a(o#t d#t o#d#t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.interm, a(o#t d#t o#d#t hs2#t) vce(cluster o#d)
	
	estfe *, labels(o#t "Exporter x year FE" d#t "Importer x year FE" ///
	t "Year FE" hs2#t "HS 2-digit x year FE" o#d#t "Country pair x year FE")
	esttab using "$results/OLS_noraw_panel.csv", ///
	indicate(`r(indicate_fe)', labels("Yes" ""))  ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
	
*------------------------
* 7. Homog vs diff, panel
*------------------------
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear
	eststo clear
	eststo: reghdfe lnv c.lndist##i.diff_con $vars, a(o#t d#t t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.diff_con $vars, a(o#t d#t hs2#t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.diff_con, a(o#t d#t o#d#t) vce(cluster o#d)
	eststo: reghdfe lnv c.lndist##i.diff_con, a(o#t d#t o#d#t hs2#t) vce(cluster o#d)
	
	estfe *, labels(o#t "Exporter x year FE" d#t "Importer x year FE" ///
	t "Year FE" hs2#t "HS 2-digit x year FE" o#d#t "Country pair x year FE")
	esttab using "$results/OLS_HOMvsDIFF_panel.csv", ///
	indicate(`r(indicate_fe)', labels("Yes" "")) ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
		
*-------------------
* 8. 4 groups, panel
*-------------------
// groups are - 1: FG_hom (reference), 2: FG_diff, 3: IG_hom, 4: IG_diff
global vars "contig comlang colony rta"
use gravity_hs6_panel, clear
	eststo clear
	sort bec_class diff_con
	egen groups = group(interm diff_con)	
	eststo: reghdfe lnv c.lndist##i.groups $vars, a(o#t d#t t) vce(cluster o#d)
		test lndist#2.groups = lndist#3.groups
		test lndist#2.groups = lndist#4.groups
		test lndist#3.groups = lndist#4.groups
	eststo: reghdfe lnv c.lndist##i.groups $vars, a(o#t d#t hs2#t) vce(cluster o#d)
		test lndist#2.groups = lndist#3.groups
		test lndist#2.groups = lndist#4.groups
		test lndist#3.groups = lndist#4.groups
	eststo: reghdfe lnv c.lndist##i.groups, a(o#t d#t o#d#t) vce(cluster o#d)
		test lndist#2.groups = lndist#3.groups
		test lndist#2.groups = lndist#4.groups
		test lndist#3.groups = lndist#4.groups
	eststo: reghdfe lnv c.lndist##i.groups, a(o#t d#t o#d#t hs2#t) vce(cluster o#d)
		test lndist#2.groups = lndist#3.groups
		test lndist#2.groups = lndist#4.groups
		test lndist#3.groups = lndist#4.groups

	estfe *, labels(o#t "Exporter x year FE" d#t "Importer x year FE" ///
	t "Year FE" hs2#t "HS 2-digit x year FE" o#d#t "Country pair x year FE")
	esttab using "$results/OLS_4groups_panel.csv", ///
	indicate(`r(indicate_fe)', labels("Yes" "")) ///
	b(3) se(3) r2(3) not nogaps star parentheses ar2 replace
	
cap log close
clear
