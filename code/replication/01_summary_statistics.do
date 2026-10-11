/**********************************************************************
* TABLE 1 — Summary Statistics for Main Variables
* Replication of Acemoglu et al. (2019), "Democracy Does Cause Growth"
*
* Variable mapping (confirmed from describe output):
*   GDP per capita          -> gdppercapitaconstant2000us  (levels, 2000 USD)
*   Investment share GDP    -> ginv
*   Trade share GDP         -> tradewb
*   Primary enrollment      -> prienr
*   Secondary enrollment    -> secenr
*   Tax revenue share GDP   -> taxratio
*   Child mortality/1000    -> mortnew
*   Unrest                  -> unrest
*   Market reforms index    -> marketref
*
* Output: ${project}/results/TableSumStats.tex
* Usage:  run after:  use "${project}/data/DDCGdata_final.dta", clear
**********************************************************************/

use "${project}/data/DDCGdata_final.dta", clear
sort wbcode2 year

* -------------------------------------------------------------------
* Assign display labels
* -------------------------------------------------------------------
label variable gdppercapitaconstant2000us "GDP per capita"
label variable ginv      "Investment share of GDP"
label variable tradewb   "Trade share of GDP"
label variable prienr    "Primary-school enrollment rate"
label variable secenr    "Secondary-school enrollment rate"
label variable taxratio  "Tax revenue share of GDP"
label variable mortnew   "Child mortality per 1,000 births"
label variable unrest    "Unrest rate"
label variable marketref "Market reforms index (0--100)"

* -------------------------------------------------------------------
* Write the .tex file — 9 rows matching original Table 1
* -------------------------------------------------------------------
cap mkdir "${project}/results"
file open fh using "${project}/results/TableSumStats.tex", write replace

* Format: GDP per capita as integer, all others 2 decimal places
local vars    gdppercapitaconstant2000us ginv tradewb prienr secenr taxratio mortnew unrest marketref
local fmts    int dec dec dec dec dec dec dec dec

local i = 1
foreach v of local vars {

    local f : word `i' of `fmts'
    if "`f'" == "int" {
        local fmt "%9,0fc"
    }
    else {
        local fmt "%9.2f"
    }

    * Non-democracies (dem == 0)
    quietly summarize `v' if dem == 0
    local n0  = string(r(N),    "%9,0fc")
    local m0  = string(r(mean), "`fmt'")
    local sd0 = string(r(sd),   "`fmt'")

    * Democracies (dem == 1)
    quietly summarize `v' if dem == 1
    local n1  = string(r(N),    "%9,0fc")
    local m1  = string(r(mean), "`fmt'")
    local sd1 = string(r(sd),   "`fmt'")

    * Variable label
    local vlab : variable label `v'

    file write fh "`vlab' & `n0' & `m0' & `sd0' & `n1' & `m1' & `sd1' \\" _n

    local i = `i' + 1
}

file close fh

di "Done. Output: ${project}/results/TableSumStats.tex"
