/**********************************************************************
* EXTENSION 2 — Distributional Effects of Democracy on GDP per Capita
* Replication of Acemoglu et al. (2019), "Democracy Does Cause Growth"
*
* Output: results/TableExt2.tex
*         results/FigureExt2_coef.png
*         results/FigureExt2_coef_IV.png
**********************************************************************/

cap ssc install estout, replace

use "${project}/data/DDCGdata_final.dta", clear
sort wbcode2 year
xtset wbcode2 year

* --------------------------------------------------------------------
* 1. Define estimation sample and check quintile coverage
* --------------------------------------------------------------------
xtreg y l(1/4).y dem yy*, fe
gen samp_full = e(sample)
gen samp = (samp_full==1 & !missing(quintile50s))

di "Obs per quintile in restricted sample:"
tab quintile50s if samp==1

* --------------------------------------------------------------------
* 2. Store coefficients manually — avoids eststo/quietly issues
* --------------------------------------------------------------------
* We collect: dem coef, se, N for each quintile, for FE and IV
* Store in matrices: rows=quintiles 1-5, cols = coef / se / N

matrix RFE = J(5, 3, .)   // col1=coef, col2=se, col3=N
matrix RIV = J(5, 3, .)

forvalues q = 1/5 {

    quietly count if samp==1 & quintile50s==`q'
    local nq = r(N)
    di "Quintile `q': `nq' obs"

    if `nq' > 100 {

        * FE
        cap xtreg y l(1/4).y dem yy* if samp==1 & quintile50s==`q', ///
            fe vce(cluster wbcode2)
        if _rc == 0 {
            matrix RFE[`q', 1] = _b[dem]
            matrix RFE[`q', 2] = _se[dem]
            matrix RFE[`q', 3] = e(N)
            di "FE Q`q': coef=" _b[dem] " se=" _se[dem]
        }
        else {
            di "FE Q`q' FAILED with rc=" _rc
        }

        * IV
        cap xtivreg2 y l(1/4).y (dem = l(1/4).demreg) yy* ///
            if samp==1 & quintile50s==`q', fe robust cluster(wbcode2)
        if _rc == 0 {
            matrix RIV[`q', 1] = _b[dem]
            matrix RIV[`q', 2] = _se[dem]
            matrix RIV[`q', 3] = e(N)
            di "IV Q`q': coef=" _b[dem] " se=" _se[dem]
        }
        else {
            di "IV Q`q' FAILED with rc=" _rc
        }
    }
    else {
        di "Quintile `q' skipped — too few obs"
    }
}

* Check results
di "FE results matrix:"
mat list RFE
di "IV results matrix:"
mat list RIV

* --------------------------------------------------------------------
* 3. Write LaTeX table manually from matrices
* --------------------------------------------------------------------
cap mkdir "${project}/results"
file open fh using "${project}/results/TableExt2.tex", write replace

* Header rows (input into a larger table in the paper)
* Rows: Democracy coef, SE, Observations
* Cols: Q1-Q5 for FE, then Q1-Q5 for IV

* Democracy row
file write fh "Democracy"
forvalues q = 1/5 {
    if RFE[`q',1] != . {
        local b = string(RFE[`q',1], "%9.3f")
        file write fh " & `b'"
    }
    else {
        file write fh " & --"
    }
}
forvalues q = 1/5 {
    if RIV[`q',1] != . {
        local b = string(RIV[`q',1], "%9.3f")
        file write fh " & `b'"
    }
    else {
        file write fh " & --"
    }
}
file write fh " \\" _n

* SE row
file write fh " "
forvalues q = 1/5 {
    if RFE[`q',2] != . {
        local se = string(RFE[`q',2], "%9.3f")
        file write fh " & (`se')"
    }
    else {
        file write fh " & "
    }
}
forvalues q = 1/5 {
    if RIV[`q',2] != . {
        local se = string(RIV[`q',2], "%9.3f")
        file write fh " & (`se')"
    }
    else {
        file write fh " & "
    }
}
file write fh " \\" _n

* Significance stars — add manually based on t-stat
file write fh "\midrule" _n

* Observations row
file write fh "Observations"
forvalues q = 1/5 {
    if RFE[`q',3] != . {
        local n = string(RFE[`q',3], "%9.0f")
        file write fh " & `n'"
    }
    else {
        file write fh " & --"
    }
}
forvalues q = 1/5 {
    if RIV[`q',3] != . {
        local n = string(RIV[`q',3], "%9.0f")
        file write fh " & `n'"
    }
    else {
        file write fh " & --"
    }
}
file write fh " \\" _n

file close fh
di "TableExt2.tex written."

* --------------------------------------------------------------------
* 4. Coefficient plots from matrices
* --------------------------------------------------------------------

* --- FE plot ---
preserve
clear
svmat RFE, names(col)
rename c1 coef
rename c2 se
rename c3 nobs
gen quintile = _n
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
drop if missing(coef)

twoway ///
    (rcap lb ub quintile, lcolor(gs8) lwidth(medthin)) ///
    (scatter coef quintile, mcolor(navy) msize(medlarge) msymbol(circle)) ///
    (line coef quintile, lcolor(navy) lpattern(shortdash) lwidth(thin)) ///
    , ///
    yline(0, lcolor(red) lpattern(dash) lwidth(thin)) ///
    xlabel(1 "Q1 (Poorest)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (Richest)", ///
           labsize(small) angle(15)) ///
    ylabel(, labsize(small) format(%5.1f)) ///
    ytitle("Effect of Democracy on Log GDP per Capita (×100)", size(small)) ///
    xtitle("Initial Income Quintile (based on 1950s GDP)", size(small)) ///
    title("Democracy and Growth: Heterogeneity by Initial Income", ///
          size(medsmall)) ///
    subtitle("Within (FE) estimates with 95% confidence intervals", size(small)) ///
    note("Each point = democracy coefficient from separate dynamic panel" ///
         "regression. Four lags of log GDP, country + year FE.", size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))

graph export "${project}/results/FigureExt2_coef.png", replace width(1400)
restore

* --- IV plot ---
preserve
clear
svmat RIV, names(col)
rename c1 coef
rename c2 se
rename c3 nobs
gen quintile = _n
gen lb = coef - 1.96*se
gen ub = coef + 1.96*se
drop if missing(coef)

twoway ///
    (rcap lb ub quintile, lcolor(gs8) lwidth(medthin)) ///
    (scatter coef quintile, mcolor(maroon) msize(medlarge) msymbol(circle)) ///
    (line coef quintile, lcolor(maroon) lpattern(shortdash) lwidth(thin)) ///
    , ///
    yline(0, lcolor(red) lpattern(dash) lwidth(thin)) ///
    xlabel(1 "Q1 (Poorest)" 2 "Q2" 3 "Q3" 4 "Q4" 5 "Q5 (Richest)", ///
           labsize(small) angle(15)) ///
    ylabel(, labsize(small) format(%5.1f)) ///
    ytitle("Effect of Democracy on Log GDP per Capita (×100)", size(small)) ///
    xtitle("Initial Income Quintile (based on 1950s GDP)", size(small)) ///
    title("Democracy and Growth: Heterogeneity by Initial Income (IV)", ///
          size(medsmall)) ///
    subtitle("2SLS estimates with 95% confidence intervals", size(small)) ///
    note("Each point = 2SLS democracy coefficient from separate dynamic panel" ///
         "regression. Instrument: four lags of regional democracy wave.", ///
         size(vsmall)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(color(white))

graph export "${project}/results/FigureExt2_coef_IV.png", replace width(1400)
restore

* --------------------------------------------------------------------
* 5. Clean up
* --------------------------------------------------------------------
drop samp samp_full

di ""
di "====================================================="
di " Extension 2 complete. Output files:"
di "   results/TableExt2.tex"
di "   results/FigureExt2_coef.png"
di "   results/FigureExt2_coef_IV.png"
di "====================================================="
