/**********************/
/*Clean and set memory*/
/**********************/
clear all
set matsize 11000
set more off

/******************/
/*Install programs*/
/******************/
cap ssc install ivreg2,   replace
cap ssc install estout,   replace
cap ssc install parmest,  replace   /* FIX: was missing from original install list */

/*********************/
/*Sets base directory*/
/*********************/
if "${project}" == "" global project "`c(pwd)'"
cd "$project"
cap mkdir "${project}/results"
global limit = 30                   /* Number of years to plot */

/**********************************************************************
* PROGRAM: vareffects1
* Computes cumulative dynamic effects via forward iteration of the
* GDP process, carrying all previous effects through nlcom.
* NOTE: this version carries ALL previous effects in `previous' macro
* which avoids the matrix-size issue in the standard vareffects program
* when plotting 30 years rather than 25.
**********************************************************************/
capture program drop vareffects1
program define vareffects1, eclass

    quietly: nlcom ///
        (effect1: _b[shortrun]) ///
        (shortrun: _b[shortrun]) ///
        (lag1: _b[lag1]) (lag2: _b[lag2]) ///
        (lag3: _b[lag3]) (lag4: _b[lag4]), post

    quietly: nlcom ///
        (effect2: _b[effect1]*_b[lag1]+_b[shortrun]) ///
        (effect1: _b[effect1]) (shortrun: _b[shortrun]) ///
        (lag1: _b[lag1]) (lag2: _b[lag2]) ///
        (lag3: _b[lag3]) (lag4: _b[lag4]), post

    quietly: nlcom ///
        (effect3: _b[effect2]*_b[lag1]+_b[effect1]*_b[lag2]+_b[shortrun]) ///
        (effect2: _b[effect2]) (effect1: _b[effect1]) ///
        (shortrun: _b[shortrun]) ///
        (lag1: _b[lag1]) (lag2: _b[lag2]) ///
        (lag3: _b[lag3]) (lag4: _b[lag4]), post

    quietly: nlcom ///
        (effect4: _b[effect3]*_b[lag1]+_b[effect2]*_b[lag2]+_b[effect1]*_b[lag3]+_b[shortrun]) ///
        (effect3: _b[effect3]) (effect2: _b[effect2]) ///
        (effect1: _b[effect1]) (shortrun: _b[shortrun]) ///
        (lag1: _b[lag1]) (lag2: _b[lag2]) ///
        (lag3: _b[lag3]) (lag4: _b[lag4]), post

    local previous (effect4: _b[effect4]) (effect3: _b[effect3]) ///
                   (effect2: _b[effect2]) (effect1: _b[effect1])

    forvalues j = 5(1)$limit {
        local j1 = `j'-1
        local j2 = `j'-2
        local j3 = `j'-3
        local j4 = `j'-4

        quietly: nlcom ///
            (effect`j': _b[effect`j1']*_b[lag1]+_b[effect`j2']*_b[lag2]+ ///
                        _b[effect`j3']*_b[lag3]+_b[effect`j4']*_b[lag4]+_b[shortrun]) ///
            `previous' ///
            (shortrun: _b[shortrun]) ///
            (lag1: _b[lag1]) (lag2: _b[lag2]) ///
            (lag3: _b[lag3]) (lag4: _b[lag4]), post

        local previous (effect`j': _b[effect`j']) `previous'
    }

    ereturn display
end

/**********************************************************************
* ESTIMATION
**********************************************************************/
use "${project}/data/DDCGdata_final.dta", clear
lort wbcode2 year

/* Within estimator (Table 2, col 3 — 4 lags of GDP) */
quietly: xtreg y l(1/4).y dem yy*, fe r cluster(wbcode2)
nlcom (shortrun: _b[dem]) (lag1: _b[L.y]) (lag2: _b[L2.y]) ///
      (lag3: _b[L3.y])    (lag4: _b[L4.y]), post
vareffects1

/* Save impulse response to disk via parmest */
parmest, format(estimate min95 max95) ///
    saving("${project}/results/impulse_var1", replace)

/**********************************************************************
* PLOT FIGURE 2
**********************************************************************/
use "${project}/results/impulse_var1", clear

/* Extract effect number and convert to time axis */
split parm, p("effect")
keep if parm2 != ""
destring parm2, force replace
gen time = parm2 - 1        /* effect1 = year 0, effect30 = year 29 */
tsset time

/* Figure 2: Dynamic path of democracy effect with 95% CI
   FIX: export as .png — Stata 19 .eps preview unreliable on Mac
        To use .eps instead, swap the graph export line at the bottom */
twoway ///
    (tsline estimate, lcolor(black)  lpattern(solid)) ///
    (tsline min95,    lcolor(gray)   lpattern(dash))  ///
    (tsline max95,    lcolor(gray)   lpattern(dash))  ///
    , ///
    ytitle("Change in GDP per capita log points") ///
    xtitle("Years around democratization") ///
    legend(off) ///
    xlabel(0(5)30) ///
    graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) ///
    plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))

/* Export
   For .eps: graph export "${project}/results/ImpVar1.eps", as(eps) preview(off) replace */
graph export "${project}/results/ImpVar1.png", as(png) replace
di "Figure 2 saved to ${project}/results/ImpVar1.png"
