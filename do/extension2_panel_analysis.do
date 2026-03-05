*===============================================================================
* 1. BUILD THE T=2 PANEL
*===============================================================================
clear all

* Load Period 1 (Waves 3 & 4)
use "redistribution_merged_wave34.dta", clear
gen period = 1

* Append Period 2 (Waves 5 & 6)
append using "redistribution_merged_wave56.dta"
replace period = 2 if missing(period)

* Create a numeric Country ID and declare the panel
egen country_id = group(country)
xtset country_id period

*===============================================================================
* 2. TWFE REGRESSION
*===============================================================================
local base_controls lngdp lnpop dem_ANRR gini_mkt

eststo clear

* Model 1: Pooled OLS (Replicating cross-section logic but with double the data)
eststo m1: reghdfe rel_red_imp att_red_top att_red_mid att_red_bottom `base_controls', ///
    absorb(period) vce(cluster country_id)

* Model 2: Strict TWFE (The true panel extension)
* This absorbs country_id, isolating only WITHIN-country changes over time.
eststo m2: reghdfe rel_red_imp att_red_top att_red_mid att_red_bottom `base_controls', ///
    absorb(country_id period) vce(cluster country_id)
    
	test att_red_top = att_red_mid
	estadd scalar ptopmid = r(p)
	test att_red_top = att_red_bottom
	estadd scalar ptopbot = r(p)
	test att_red_mid = att_red_bottom
	estadd scalar pmidbot = r(p)

* Output
esttab m1 m2 using "panel_twfe.tex", replace ///
    noobs b(3) aux(se 3) nobaselevels style(tex) booktabs label ///
    mtitle("Pooled OLS" "TWFE (Within-Country)") ///
    stats(ptopmid ptopbot pmidbot r2 N, fmt(3 3 3 3 0)) nostar
