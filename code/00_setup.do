/**********************************************************************
* Replication and Extension of "Democracy Does Cause Growth"
* Project setup
*
* Run this file from the repository root before running other scripts.
**********************************************************************/

clear all
set more off
set matsize 11000
set maxvar 10000

* Repository root: assumes Stata's working directory is the repo root.
global project "`c(pwd)'"

capture mkdir "${project}/results"

* User-written packages required across the replication scripts.
local packages xtabond2 xtivreg2 ivreg2 ranktest moremata estout parmest geodist
foreach pkg of local packages {
    capture which `pkg'
    if _rc ssc install `pkg'
}

di "Project root: ${project}"
di "Setup complete."
