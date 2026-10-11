/**********************/
/*Clean and set memory*/
/**********************/
clear all
set matsize 11000
set more off

/*********************/
/*Sets base directory*/
/*********************/
if "${project}" == "" global project "`c(pwd)'"
cd "$project"
cap mkdir "${project}/results"

/**********************************************************************
* FIGURE 6, PANEL A: Regional democratization waves
* Shows mean democracy in a region around its first democratization,
* compared to mean democracy in all other regions (jackknife control).
**********************************************************************/
use "${project}/data/DDCGdata_final.dta", clear
sort wbcode2 year

/* Identify first transition to democracy in each region.
   Remove periods of democracy in first years not accounted for
   in the initial regime definition, and short-lived post-independence
   democracy spells among initially autocratic countries. */
replace yeardem = 0 if l.dem==. | l2.dem==. | l3.dem==. | l4.dem==. | l5.dem==.
replace dem     = 0 if (l.dem==. | l2.dem==. | l3.dem==. | l4.dem==. | l6.dem==.) ///
                       & InitReg == 0

gen temp = .
replace temp = year if InitReg == 0 & yeardem == 1
bysort region demext: egen ydem = min(temp)

/* Remove the first democratizer in each region-regime cell to avoid
   mechanical correlation between the country and its own wave */
gen tag = .
replace tag = 1 if year == ydem & yeardem == 1
bysort wbcode: egen tag2 = mean(tag)
gen tempp = wbcode2 if tag2 == 1
bysort region demext: egen temp2 = min(tempp)
drop if tag2 == 1 & temp2 == wbcode2

/* Keep only initially autocratic region-regime cells and collapse */
keep if demext == "_nd"
collapse ydem dem, by(region demext year)

/* Remove global trends: jackknife mean — for each region,
   dhat1 = mean democracy of all OTHER regions in that year */
gen dhat1 = .

foreach reg in AFR EAP ECA INL LAC MNA SAS {
    gen temp  = dem if region != "`reg'"
    bysort year: egen temp2 = mean(temp)
    replace dhat1 = temp2 if region == "`reg'"
    drop temp temp2
}

/* Recenter around each region's first democratization year */
gen time = year - ydem
keep if time != .

/* Collapse to single time series and plot */
collapse dhat1 dem, by(time)
rename time year
sort year
tsset year
keep if year >= -10 & year <= 20

/* Figure 6a: Democratization waves
   FIX: .png instead of .eps (Stata 19 .eps preview unreliable on Mac)
   For .eps: graph export "${project}/results/FigureFS.eps", as(eps) preview(off) replace */
twoway ///
    (tsline dhat1, lcolor(gs5)  lpattern(longdash)) ///
    (tsline dem,   lcolor(black) lpattern(solid))   ///
    , ///
    ytitle("Mean democracy") ///
    xtitle("Years around first democratization in the region") ///
    legend(on order(2 "Initial nondemocracies in the region" ///
                    1 "Initial nondemocracies in other regions") ///
           cols(1) position(6)) ///
    xlabel(-10(5)20) ///
    graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) ///
    plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))

graph export "${project}/results/FigureFS.png", as(png) replace
di "Figure 6a saved to ${project}/results/FigureFS.png"


/**********************************************************************
* FIGURE 6, PANEL B: Regional reversal waves
* Shows mean democracy in a region around its first democratic reversal,
* compared to mean democracy in all other regions (jackknife control).
**********************************************************************/
use "${project}/data/DDCGdata_final.dta", clear
sort wbcode2 year

/* Identify first reversal from democracy in each region.
   Remove periods in first years not accounted for in initial regime. */
replace yearrev = 0 if l.dem==. | l2.dem==. | l3.dem==. | l4.dem==. | l5.dem==.

gen temp = .
replace temp = year if InitReg == 1 & yearrev == 1
bysort region demext: egen ydem = min(temp)

/* Remove the first reverter in each region-regime cell */
gen tag = .
replace tag = 1 if year == ydem & yearrev == 1
bysort wbcode: egen tag2 = mean(tag)
gen tempp = wbcode2 if tag2 == 1
bysort region demext: egen temp2 = min(tempp)
drop if tag2 == 1 & temp2 == wbcode2

/* Keep only initially democratic region-regime cells and collapse */
keep if demext == "_dem"
collapse ydem dem, by(region demext year)

/* Remove global trends: jackknife mean for each region */
gen dhat1 = .

foreach reg in AFR EAP ECA INL LAC MNA SAS {
    gen temp  = dem if region != "`reg'"
    bysort year: egen temp2 = mean(temp)
    replace dhat1 = temp2 if region == "`reg'"
    drop temp temp2
}

/* Recenter around each region's first reversal year */
gen time = year - ydem
keep if time != .

/* Collapse to single time series and plot */
collapse dhat1 dem, by(time)
rename time year
sort year
tsset year
keep if year >= -10 & year <= 20

/* Figure 6b: Reversal waves
   FIX: .png instead of .eps
   For .eps: graph export "${project}/results/FigureFSRev.eps", as(eps) preview(off) replace */
twoway ///
    (tsline dhat1, lcolor(gs5)  lpattern(longdash)) ///
    (tsline dem,   lcolor(black) lpattern(solid))   ///
    , ///
    ytitle("Mean democracy") ///
    xtitle("Years around first reversal in the region") ///
    legend(on order(2 "Initial democracies in the region" ///
                    1 "Initial democracies in other regions") ///
           cols(1) position(6)) ///
    xlabel(-10(5)20) ///
    graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) ///
    plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))

graph export "${project}/results/FigureFSRev.png", as(png) replace
di "Figure 6b saved to ${project}/results/FigureFSRev.png"
