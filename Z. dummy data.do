* Version: September 2019
global ncountries = 100
global dummy "~/Dropbox/Research/Papers/current/CMP_gravity/glenn/data/dummy"

*----------------
* 0. Gravity data
*----------------
// all possible flows o d hs6
forvalues t = 1998/2011 {
clear*
set obs $ncountries
	gen o = _n
	gen d = _n
	fillin o d											// square matrix of all country-pairs
	drop _fillin
	gen dist = abs((rnormal()*5 + 10))					// create country-pair variables
	foreach x in contig colony comlang rta {
		gen `x' = rnormal()
		replace `x' = (`x'> 0)
	}
	gen hs6 = runiformint(1,20)							// create product level flows
	fillin o d hs6
	drop if o == d
	drop _fillin
	gen intermediate = (hs6>10)							// types of goods
	gen diff_con = 0					
	replace diff_con = 1 if inlist(hs6,1,3,5,7,9,11,13,151,17,19)  
	gen raw_mat = 0
	replace raw_mat = 1 if inlist(hs6,1,4,7,10) 
	gen v = (rnormal()*5) 								// values at o d hs6 level
	replace v = 0 if v <0								// 50% zeroes
	foreach x in dist contig colony comlang rta {		// fill in country-pair values for all o d hs6 obs
		bys o d: egen mean_`x' = mean(`x')
		replace `x' = mean_`x'
		drop mean_`x'
	}	
	gen hs2 = round(hs6/5)	+ 1							// aggregate hs codes
	foreach x in v dist {
		gen ln`x' = ln(`x')
		replace ln`x' = abs(ln`x')
	}	
	gen t = `t'
save $dummy/gravity_hs6_`t', replace
} 

use $dummy/gravity_hs6_1998, clear
	forvalues t = 1999/2011 { 
		append using  $dummy/gravity_hs6_`t'
	}
save  $dummy/gravity_hs6_panel, replace


*-------
* 1. OLS
*-------
use $dummy/gravity_hs6_1998, clear
	drop if v==0
	reghdfe lnv c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)	
	
use $dummy/gravity_hs6_1998, clear
	drop if v==0	
	drop if raw_mat==1 
	reghdfe lnv c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)	

use $dummy/gravity_hs6_1998, clear
	drop if v==0
	egen groups = group(interm diff)	
	eststo: reghdfe lnv c.lndist##i.groups, a(o d o#d hs2) vce(cluster o#d)
	test lndist#2.groups = lndist#3.groups
	test lndist#2.groups = lndist#4.groups
	test lndist#3.groups = lndist#4.groups
		
*-------------------	
* 2. PPML, no zeroes	
*-------------------	
use $dummy/gravity_hs6_1998, clear
	drop if v==0
	*replace v = v/1000000								// speed up convergence
	ppmlhdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	
use $dummy/gravity_hs6_1998, clear
	drop if v==0
	*replace v = v/1000000								
	drop if raw_mat==1 
	ppmlhdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	
use $dummy/gravity_hs6_1998, clear
	drop if v==0
	*replace v = v/1000000								
	egen groups = group(interm diff)	
	ppmlhdfe v c.lndist##i.groups, a(o d o#d hs2) vce(cluster o#d)	
	test lndist#2.groups = lndist#3.groups
	test lndist#2.groups = lndist#4.groups
	test lndist#3.groups = lndist#4.groups
	
*----------------------	
* 3. PPML, added zeroes	
*----------------------	
use $dummy/gravity_hs6_1998, clear
	ppmlhdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	
use $dummy/gravity_hs6_1998, clear							
	drop if raw_mat==1 
	ppmlhdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	
use $dummy/gravity_hs6_1998, clear							
	egen groups = group(interm diff)	
	ppmlhdfe v c.lndist##i.groups, a(o d o#d hs2) vce(cluster o#d)	
	test lndist#2.groups = lndist#3.groups
	test lndist#2.groups = lndist#4.groups
	test lndist#3.groups = lndist#4.groups	

*-------
* 4. LPM
*-------
use $dummy/gravity_hs6_1998, clear
	replace v = (v>0)
	reghdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	
use $dummy/gravity_hs6_1998, clear
	replace v = (v>0)
	drop if raw_mat==1 
	reghdfe v c.lndist##i.interm, a(o d o#d hs2) vce(cluster o#d)
	
use $dummy/gravity_hs6_1998, clear	
	replace v = (v>0)
	egen groups = group(interm diff)	
	reghdfe v c.lndist##i.groups, a(o d o#d hs2) vce(cluster o#d)	
	test lndist#2.groups = lndist#3.groups
	test lndist#2.groups = lndist#4.groups
	test lndist#3.groups = lndist#4.groups		
	
*---------------------	
* 5. CLOGIT	- option 1 (discretize & contract)
*---------------------
use $dummy/gravity_hs6_1998, clear
	replace v = (v>0)
	egen cp = group(o d)
	replace lndist = round(lndist)
	contract v lndist interm hs6 o d cp
	clogit v i.lndist##i.interm [fw=_freq], group(cp) vce(cluster cp) // drop i.o and i.d since no within group variance
	*logit v i.lndist##i.interm i.o i.d i.hs2 [fw=_freq], vce(cluster cp)

*---------------------	
* 6. CLOGIT	- option 2 (random subsample)
*---------------------
forvalues t = $start(3)$start {
	
	tempname memhold
	postfile `memhold' sample N b_group2 se_group2 p_group2 b_group3 se_group3 ///
	p_group3 b_group4 se_group4 p_group4 b_dist_group2 se_dist_group2 p_dist_group2 ///
	b_dist_group3 se_dist_group3 p_dist_group3 b_dist_group4 se_dist_group4 ///
	p_dist_group4 using "$dummy/CLOGIT_subsamples_4groups_`t'", replace
	
	forvalues s = 1/30 {
		use $dummy/gravity_hs6_`t', clear
		local seed = 123  + `s'
		set seed `seed'
		sample 1
		replace v = (v>0)
		egen cp = group(o d)	
		egen groups = group(interm diff)
		clogit v c.lndist##i.groups i.hs2, group(cp) vce(cluster cp) // drop i.o and i.d since no within group variance
		
		// save b, se and p	
		local N = e(sample)		
	
		local b_group2: di _b[2.groups]
		local se_group2: di _se[2.groups]
		local t_group2 = `b_group2'/`se_group2'
		local p_group2 = 2*ttail(e(df_r),abs(`t_group2'))

		local b_group3: di _b[3.groups]
		local se_group3: di _se[3.groups]
		local t_group3 = `b_group3'/`se_group3'
		local p_group3 = 2*ttail(e(df_r),abs(`t_group3'))
		
		local b_group4: di _b[4.groups]
		local se_group4: di _se[4.groups]
		local t_group4 = `b_group4'/`se_group4'
		local p_group4 = 2*ttail(e(df_r),abs(`t_group4'))

		local b_dist_group2: di _b[2.groups#c.lndist]
		local se_dist_group2: di _se[2.groups#c.lndist]
		local t_dist_group2 = `b_dist_group2'/`se_dist_group2'
		local p_dist_group2 = 2*ttail(e(df_r),abs(`t_dist_group2'))
			
		local b_dist_group3: di _b[3.groups#c.lndist]
		local se_dist_group3: di _se[3.groups#c.lndist]
		local t_dist_group3 = `b_dist_group3'/`se_dist_group3'
		local p_dist_group3 = 2*ttail(e(df_r),abs(`t_dist_group3'))
		
		local b_dist_group4: di _b[4.groups#c.lndist]
		local se_dist_group4: di _se[4.groups#c.lndist]
		local t_dist_group4 = `b_dist_group4'/`se_dist_group4'
		local p_dist_group4 = 2*ttail(e(df_r),abs(`t_dist_group4'))
		

	
		post `memhold' (`s') (`N') (`b_group2') (`se_group2') (`p_group2') ///
		(`b_group3') (`se_group3') (`p_group3') (`b_group4') (`se_group4') ///
		(`p_group4') (`b_dist_group2') (`se_dist_group2') (`p_dist_group2') ///
		(`b_dist_group3') (`se_dist_group3') (`p_dist_group3') ///
		(`b_dist_group4') (`se_dist_group4') (`p_dist_group4')
		}	
	postclose `memhold'	
}					

use "$dummy/CLOGIT_subsamples_4groups_$start", clear
hist group2, normal  xline(0)			// true value = 0
