

*File to Merge SITCRev2 and Rev3 with Rauch classifiation
*Written by Ayal Chen-Zion achenzio@ucsd.edu 5/14/15

*T2,T3,T4 refer to the tier of the SITC
*_4 refers to the Rauch classification at the 4-digit level only
*_34 refers to the Rauch classificaiton at the 4-digit level and then at the 3-digit level for those missing (CORRECT)

cd $raw
import delimited "sitc4digtisRev2_rauch.csv", varnames(1) clear 
rename sitc4 sitc2_T4
save  $tmp/Rauch_classification_revised, replace

*Generate the classification (4-digit)
	gen sitc2_T3=int(sitc2_T4/10)
	gen sitc4thdig=10*[(sitc2_T4/10)-sitc2_T3]
	keep if sitc4thdig==0
	drop sitc4thdig sitc2_T4
save $tmp/Rauch_classification_revised_T3, replace

import delimited sitc_r2.txt, delimiter(space) clear
*Clean
egen descrip=concat(description-v16), punct(" ")
drop bea-v16
gen lastdig=substr(sitc2,-1,.)
gen lasttwodig=substr(sitc2,-2,.)
gen Tier=4
replace Tier=3 if lastdig=="X" & lasttwodig~="XX"
replace Tier=2 if lasttwodig=="XX"
destring sitc2, gen(sitcnum) ignore("XX X A")
drop if lastdig=="A"

*Create Tier variables
gen sitc2_T4=sitcnum if Tier==4
replace sitc2_T4=sitcnum*10 if Tier==3

gen sitc2_T3=sitcnum if Tier==3
replace sitc2_T3=int(sitcnum/10) if Tier==4

gen sitc2_T2=sitcnum if Tier==2
replace sitc2_T2=int(sitcnum/10) if Tier==3
replace sitc2_T2=int(sitcnum/100) if Tier==4
 
sort sitc2_T2 sitc2_T3 sitc2_T4

*Only keep those that are Tier 3 or 4
drop if sitc2_T4==. & sitc2_T3==.

*Merge in 4-digit classification
merge m:1 sitc2_T4 using $tmp/Rauch_classification_revised.dta, gen(_merge_revclas)
gen con_4=con
gen lib_4=lib

*Merge in 3-digit classification
merge m:1 sitc2_T3 using $tmp/Rauch_classification_revised_T3.dta, ///
gen(_merge_revclasT3) update
rename con con_34
rename lib lib_34

preserve
keep if con_34=="" & _merge_revclas~=2
keep descrip sitc2_T4
count
list
*Number SITCRev2 with no 3- or 4-digit class
restore

preserve
keep if _merge_revclas==2
keep descrip sitc2_T4
count
*Number with a 3- or 4-digit class, but no SITCRev2 (see Rev3)
restore

sort sitc2_T4
by sitc2_T4:  gen dup = cond(_N==1,0,_n)
tab dup
drop if dup>1
drop dup

*All 4-digits but 4 have a classification
keep sitc2_T4 con_34 lib_34
*1274 4digit sitc covered by a classification
save "$tmp/rauch", replace

*To create concordance with HS6-use HS6 to SITC rev2 5-digit classification
import excel "$raw/HS1996 to SITC2 Conversion and Correlation Tables.xls", sheet("For stata") firstrow clear
rename HS96 hs6
rename S2 sitc2
gen sitc2_T4=substr( sitc2,1,4)
destring hs6 sitc2 sitc2_T4, replace

*Merge with Rauch classification
merge m:1 sitc2_T4 using "$tmp/rauch"
keep if _merge==3
*OIL missing
keep hs6 sitc2_T4 con_34 lib_34
save $tmp/hs96_rauch, replace


**************************************
*HS2 AND SECION DESCRIPTIONS*
**************************************
use $raw/hs2_row.dta, clear
gen hs2=substr(var1,1,2)
tab hs2
destring hs2, replace
drop  if hs2==.
gen hs2_descr=substr(var1,3,.)

*Generate even broader cathegories (sections), according to website
gen section=.
gen section_descr=""
forval v=1/5 {
replace section=1 if hs2==`v'
replace section_descr="Animals and animal products" if hs2==`v'
}
forval v=6/14 {
replace section=2 if hs2==`v'
replace section_descr="Vegetable products" if hs2==`v'
}
forval v=15/15 {
replace section=3 if hs2==`v'
replace section_descr="Fats and oils" if hs2==`v'
}
forval v=16/24 {
replace section=4 if hs2==`v'
replace section_descr="Food, beverages and tobacco" if hs2==`v'
}

forval v=25/27 {
replace section=5 if hs2==`v'
replace section_descr="Mineral Products" if hs2==`v'
}
forval v=28/38 {
replace section=6 if hs2==`v'
replace section_descr="Chemicals" if hs2==`v'
}
forval v=39/40 {
replace section=7 if hs2==`v'
replace section_descr="Plastics" if hs2==`v'
}
forval v=41/43 {
replace section=8 if hs2==`v'
replace section_descr="Leather and fur products" if hs2==`v'
}
forval v=44/46 {
replace section=9 if hs2==`v'
replace section_descr="Wood and wood products" if hs2==`v'
}
forval v=47/49 {
replace section=10 if hs2==`v'
replace section_descr="Paper products" if hs2==`v'
}
forval v=50/63 {
replace section=11 if hs2==`v'
replace section_descr="Textiles" if hs2==`v'
}
forval v=64/67 {
replace section=12 if hs2==`v'
replace section_descr="Footwear and headgear" if hs2==`v'
}

forval v=68/70 {
replace section=13 if hs2==`v'
replace section_descr="Stone and glass products" if hs2==`v'
}
forval v=68/71 {
replace section=14 if hs2==`v'
replace section_descr="Jewellery" if hs2==`v'
}
forval v=72/83 {
replace section=15 if hs2==`v'
replace section_descr="Metals" if hs2==`v'
}
forval v=84/85 {
replace section=16 if hs2==`v'
replace section_descr="Machinery and electrical products" if hs2==`v'
}
forval v=86/89 {
replace section=17 if hs2==`v'
replace section_descr="Transportation" if hs2==`v'
}
forval v=90/92 {
replace section=18 if hs2==`v'
replace section_descr="Optical, watches, musical products" if hs2==`v'
}
forval v=93/93 {
replace section=19 if hs2==`v'
replace section_descr="Arms" if hs2==`v'
}
forval v=94/96 {
replace section=20 if hs2==`v'
replace section_descr="Furniture, toys, misc." if hs2==`v'
}
forval v=97/97 {
replace section=20 if hs2==`v'
replace section_descr="Art" if hs2==`v'
}

drop var1
save $tmp/hs2_description, replace
