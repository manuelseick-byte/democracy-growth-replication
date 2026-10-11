/**********************/
/*Clean and set memory*/
/**********************/
clear all
set matsize 11000
set more off

/******************/
/*Install programs*/
/******************/
cap ssc install estout, replace
cap ssc install ivreg2, replace

/*********************/
/*Sets base directory*/
/*********************/
if "${project}" == "" global project "`c(pwd)'"
cd "$project"
cap mkdir "${project}/results"

/****************************/
/*Create auxiliary variables*/
/****************************/
use "${project}/data/DDCGdata_final.dta", clear

/* Identify transitions: 1 = democratization, 0 = stable nondemocracy */
gen tdemoc = .
replace tdemoc = 1 if dem == 1 & l.dem == 0
replace tdemoc = 0 if dem == 0 & l.dem == 0

/* Define lags of GDP needed for probit */
gen lag1y = l1.y
gen lag2y = l2.y
gen lag3y = l3.y
gen lag4y = l4.y

/* Drop observations with missing lags (needed for propensity score) */
keep if lag1y != .
keep if lag2y != .
keep if lag3y != .
keep if lag4y != .

/* GDP changes relative to t-1: pre-transition years (s = -15 to -1) */
gen ydep0  = L15.y - L.y
gen ydep1  = L14.y - L.y
gen ydep2  = L13.y - L.y
gen ydep3  = L12.y - L.y
gen ydep4  = L11.y - L.y
gen ydep5  = L10.y - L.y
gen ydep6  = L9.y  - L.y
gen ydep7  = L8.y  - L.y
gen ydep8  = L7.y  - L.y
gen ydep9  = L6.y  - L.y
gen ydep10 = L5.y  - L.y
gen ydep11 = L4.y  - L.y
gen ydep12 = L3.y  - L.y
gen ydep13 = L2.y  - L.y
gen ydep14 = 0                  /* year -1: zero by construction */

/* GDP changes relative to t-1: post-transition years (s = 0 to +30) */
gen ydep15 = y      - L.y
gen ydep16 = F1.y   - L.y
gen ydep17 = F2.y   - L.y
gen ydep18 = F3.y   - L.y
gen ydep19 = F4.y   - L.y
gen ydep20 = F5.y   - L.y
gen ydep21 = F6.y   - L.y
gen ydep22 = F7.y   - L.y
gen ydep23 = F8.y   - L.y
gen ydep24 = F9.y  - L.y
gen ydep25 = F10.y  - L.y
gen ydep26 = F11.y  - L.y
gen ydep27 = F12.y  - L.y
gen ydep28 = F13.y  - L.y
gen ydep29 = F14.y  - L.y
gen ydep30 = F15.y  - L.y
gen ydep31 = F16.y  - L.y
gen ydep32 = F17.y  - L.y
gen ydep33 = F18.y   - L.y
gen ydep34 = F19.y  - L.y
gen ydep35 = F20.y  - L.y
gen ydep36 = F21.y  - L.y
gen ydep37 = F22.y  - L.y
gen ydep38 = F23.y  - L.y
gen ydep39 = F24.y  - L.y
gen ydep40 = F25.y  - L.y
gen ydep41 = F26.y  - L.y
gen ydep42 = F27.y  - L.y
gen ydep43 = F28.y  - L.y
gen ydep44 = F29.y  - L.y
gen ydep45 = F30.y  - L.y

/* Keep only transition and stable nondemocracy observations */
keep if tdemoc != .

/**********************************************************************
* PROGRAM: tefpas_ra
* Regression adjustment estimator (ATET) for each year around
* democratization. Loops over all 46 time periods (s = -15 to +30).
*
* FIXES vs original:
*   1. Added "define" keyword — was missing, caused silent failure
*   2. Removed iterate(7) — no longer valid syntax in Stata 15+;
*      teffects ra uses its own convergence criteria automatically
*   3. Added "nolog" to suppress verbose output during loop
**********************************************************************/
capture program drop tefpas_ra
program define tefpas_ra, eclass

    /* --- Year -15 (s=0 in loop, ydep0) --- */
    quietly: tab year if ydep0 != . & tdemoc != ., gen(dumyears)
    cap: teffects ra (ydep0 dumyears*, noconstant) (tdemoc), atet nolog
    if _rc == 0 {
        matrix b = (_b[ATET:r1vs0.tdemoc])
    }
    else {
        matrix b = (.)
    }
    quietly: drop dumyears*

    /* --- Years -14 to -2 (ydep1 to ydep13) --- */
    forvalues s = 1(1)13 {
        quietly: tab year if ydep`s' != . & tdemoc != ., gen(dumyears)
        cap: teffects ra (ydep`s' dumyears*, noconstant) (tdemoc), atet nolog
        if _rc == 0 {
            matrix b = (b, _b[ATET:r1vs0.tdemoc])
        }
        else {
            matrix b = (b, .)
        }
        quietly: drop dumyears*
    }

    /* --- Year -1: zero by construction (ydep14 = 0) --- */
    matrix b = (b, 0)

    /* --- Years 0 to +30 (ydep15 to ydep45) --- */
    forvalues s = 15(1)45 {
        quietly: tab year if ydep`s' != . & tdemoc != ., gen(dumyears)
        cap: teffects ra (ydep`s' dumyears*, noconstant) (tdemoc), atet nolog
        if _rc == 0 {
            matrix b = (b, _b[ATET:r1vs0.tdemoc])
        }
        else {
            matrix b = (b, .)
        }
        quietly: drop dumyears*
    }

    /* Post results — variance computed by bootstrapping in Table 5 */
    ereturn post b
end

/**********************************************************************
* RUN ESTIMATOR AND PLOT FIGURE 1
**********************************************************************/
di "Running regression adjustment estimator for Figure 1..."
di "This may take a few minutes (46 teffects ra calls)..."

tefpas_ra

/* Collect point estimates into a dataset */
preserve
    clear
    set obs 46
    gen estimate = .
    gen time     = .
    forvalues j = 1(1)46 {
        replace estimate = _b[c`j'] in `j'
        replace time     = `j' - 16  in `j'   /* maps to -15 ... +30 */
    }
    tsset time

    /* Figure 1: GDP per capita before and after democratization
       FIX: export as .png (crisp, universally supported in Stata 19)
            If your paper requires .eps, change the export line below  */
    twoway ///
        (tsline estimate, lcolor(black) lpattern(solid)) ///
        , ///
        ytitle("Change in GDP per capita log points") ///
        xtitle("Years around democratization") ///
        legend(off) ///
        xlabel(-15(5)30) ///
        ylabel(-5(5)27) ///
        graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) ///
        plotregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white))

    /* Export — use .png for Stata 19 compatibility
       To get .eps instead, replace the line below with:
       graph export "${project}/results/FigureDip.eps", as(eps) preview(off) replace */
    graph export "${project}/results/FigureDip.png", as(png) replace
    di "Figure 1 saved to ${project}/results/FigureDip.png"

restore
