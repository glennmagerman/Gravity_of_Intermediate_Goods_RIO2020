* This version: August 2019
* First version: March 2019

/*______________________________________________________________________________ 
1. ... Notes ...
- No GDP included. Not used in estimations (fixed effects). 
- We drop "Mixed" goods in BEC, since hard to allocate to FG/IG (line 124).
- Can restrict sample to UN recognized countries if wanted. 
- 6. All zeroes added, by year. This is very CPU + RAM intensive, and most probably
  fails on standard machines. We used a server with 36 cores and 1 TB Ram 
  to run the large panel with zeroes.
  
2. ... Data sources ...
BACI/CEPII  http://www.cepii.fr/cepii/en/bdd_modele/presentation.asp?id=1
RAUCH from  http://econweb.ucsd.edu/~jrauch/rauchclass/SITCRauch_merging_code.do
			http://unstats.un.org/unsd/tradekb/Knowledgebase/50043/HS-Classification-by-Section
HS-to-BEC   http://unstats.un.org/unsd/trade/classifications/correspondence-tables.asp
______________________________________________________________________________*/

*-----------------
* 1. Country codes (ISO3)
*-----------------
import delimited "$raw/country_code_baci96.csv", clear 
	keep iso3 i name_eng
	ren (iso3 name) (info name)
	gen iso=substr(info,1,3)								// misnomers have ISO3 codes in beginning of string
	drop if iso==""											// missing are Antarctica, very remote islands or NES (no ISO codes)
	gen i2=substr(info,-3,3) if i==.						// missing have 3d numeric country code at end
	destring i2, replace
	replace i=i2 if i==.
	replace iso="MKD" if iso=="?"
	duplicates drop iso, force								// checked: identical iso and numeric codes 
	drop i2 info
	drop if strpos(iso,",")>0								// drops ISO3 = ,,"
save "$tmp/iso_codes", replace								// 218 countries, i iso name

*--------------
* 2. Trade data (BACI/CEPII)
*--------------
forvalues t =  $start(1)$end {
	import delimited "$raw/baci96_`t'.csv", clear
	replace v = v*1000										// to current $, q is in tons (converted if needed)
	merge m:1 i using $tmp/iso_codes, nogen keepusing(i iso)
	ren (i j iso)(tmp i iso_i)
	merge m:1 i using $tmp/iso_codes, nogen keepusing(i iso)
	ren (tmp i iso) (i j iso_j)
	drop if missing(v)										// zero flows?
	drop i j 
save "$tmp/baci96_`t'", replace								// iso_i iso_j t hs6 v q
}

*------------------
* 3. Bilateral data (CEPII)
*------------------
use "$raw/gravdata_48_15", clear
	keep if year>1997 & year<2012
	ren *_o *_i
	ren *_d *_j
	ren (iso3_i iso3_j year comlang_off fta_wto) ///
	(iso_i iso_j t comlang rta) 
	drop if iso_i==iso_j									 
	gen wto_ij = (gatt_i==1 & gatt_j==1)
	keep iso_i iso_j t contig comlang distw colony rta wto_ij
	ren iso_i iso

	merge m:1 iso using $tmp/iso_codes, ///
	nogen keep(match) keepusing(iso) 						// drop special areas
	merge m:1 iso using $raw/bacid_un, nogen keepusing(un) 	// subset of countries in UN classification	
	ren (iso iso_j un) (iso_i iso un_i) 
	merge m:1 iso using $tmp/iso_codes, ///
	nogen keep(match) keepusing(iso)
	merge m:1 iso using $raw/bacid_un, nogen keepusing(un)
	ren (iso un) (iso_j un_j)
	*keep if un_i == 1 & un_j == 1
	drop un_*
save $tmp/gravity, replace									// 626,248 obs, 212 countries. 44732 in 2011 = 212*211

*---------------------------
* 4. Product classifications (BEC, HS, Rauch, raw materials)
*---------------------------
// Rauch classification (differentiated goods) and HS classification
do "$folder/notebooks/current/1b. product_class.do" 

// HS96 - BEC v4 
import excel "$raw/HS1996 to BEC Conversion and Correlation Tables.xls", ///
	sheet("stata") firstrow clear
	ren (HS96 BEC) (hs6 bec)
	destring hs6 bec, replace force
	drop if missing(bec)									// 2 missing: 710820 - gold monetary; 711890 - money
	gen bec_class="Capital" if bec==41
	replace bec_class="Capital" if bec==521
	replace bec_class="Intermediate" if ///
	inlist(bec,111,121,21,22,31,322,42,53)
	replace bec_class="Consumption" if ///
	inlist(bec,112,122,522,61,62,63)
	replace bec_class="Mixed" if inlist(bec,32,321,51,7)	// 32 = petroleum oils (exluding crude), allocated to mixed
save $tmp/bec, replace

use $tmp/bec, clear
	merge 1:1 hs6 using "$raw/raw_hs96", nogen
	replace raw_mat=0 if raw_mat==.
	merge 1:1 hs6 using "$tmp/hs96_rauch", nogen keep(match) // 271000 is dropped (refined oils)

// w: traded on organized exchange, r: reference priced, n: differentiated products
// 2 versions: conservative vs liberal
	foreach x in con lib {
		gen diff_`x' =(`x'_34 == "n")
	}	
save $tmp/prod_class, replace

// HS96 descriptions
import delimited "$raw/hs96decription.csv", clear 
	ren (v1 v2) (hs6 hs6_descr)
	keep hs6 hs6_descr
	destring hs6, replace force
	drop if missing(hs6)
	merge 1:1 hs6 using $tmp/prod_class, nogen keep(match)
	replace hs6_descr=substr(hs6_descr,10,.)
	format hs6 %06.0f
	tostring hs6, gen(hs2) u
	replace hs2=substr(hs2,1,2)
	destring hs2, replace
	merge m:1 hs2 using "$raw/hs2_description", nogen keep(match)
	drop sitc2_T4 *_34 hs2_s
save $clean/prod_classes, replace							// 5,110 HS6 products + classifications

*-----------------
* 5. Gravity panel
*-----------------
forvalues t =  $start(1)$end {
	use $tmp/gravity, clear
	keep if t == `t'
	merge 1:m iso_i iso_j using "$tmp/baci96_`t'", ///
	nogen keep(match master)								// _m=1: zero pair flows, _m=2: not in iso list
	merge m:1 hs6 using $clean/prod_classes, ///
	nogen keepusing(hs6 hs2 bec* raw diff_*)
	gen intermediate = (bec_class=="Intermediate")  
	drop if bec_class == "Mixed"							// CHOICE TO MAKE!
	drop if missing(iso_i) | missing(iso_j) | missing(hs6)
	ren (iso_i iso_j) (i j) 
	foreach x in  v dist {
		gen ln`x' = ln(`x')
	}
	order i j t hs6 v q  
	compress
save $clean/gravity_hs6_`t', replace
}	
// panel
use $clean/gravity_hs6_1998, clear
	forvalues t =  1999(1)$end {
		append using $clean/gravity_hs6_`t'
	}
	encode i, gen(o)
	encode j, gen(d)
save $clean/gravity_hs6_panel, replace
 
*----------------------------- 
* 6. All zeroes added, by year 
*-----------------------------
// create all possible i j hs6 flows
use $clean/gravity_hs6_panel, clear
	bys i j hs6: keep if _n==1 							
	keep i j hs6
	fillin i j hs6											
	drop if i==j
	drop _fillin
save $tmp/tmp_ppml, replace									// 212*211*5090 = 227,685,880 (dropped 21 Mixed)

// add observed trade and covariates 
forvalues t = 1998/2011 {
use $tmp/tmp_ppml, clear
	gen t = `t'
	merge 1:1 i j hs6 t using $clean/gravity_hs6_panel, ///
	nogen keep(match master) keepusing(v)					// trade values i j hs6 t (keep only t==`t')
	replace v = 0 if missing(v)
	ren (i j) (iso_i iso_j)
	merge m:1 iso_i iso_j t using "$tmp/gravity", ///
	nogen keep(match)										// i j characteristics (keep only t==`t')
	ren (iso_i iso_j) (i j)
	gen lndist = ln(dist)
	keep i j hs6 t v lndist contig comlang colony rta
	merge m:1 hs6 using $clean/prod_classes, ///
	nogen keep(match) keepusing(hs6 hs2 bec_class raw diff_*) // _m==1 is hs6: 271000 (refined oils), _m==2 is Mixed BEC
	gen intermediate = (bec_class=="Intermediate")  
	encode i, gen(o)
	encode j, gen(d)
	compress
save $clean/zeroes_hs_`t', replace
}
 
clear
