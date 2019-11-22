use $tmp/pmgsy_trees, clear
drop if total_forest_2000 == 0

/* keep if road completed some time during sample period */
keep if inrange(comp_year, 2001, 2013)

/* save the subset of pmgsy tree dataset */
save $tmp/pmgsy_trees_rural_panel, replace

/***********************************************/
/* MAIN TABLE -- OVERALL DEFORESTATION EFFECTS */
/***********************************************/
eststo clear

/* main result -- include post-award indicator */
eststo: reghdfe ln_forest award_only treatment_comp, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* fake result -- no award period: district-year, village fixed effects */
eststo: reghdfe ln_forest             treatment_comp, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* main result -- award indicator and treatment indicator */
eststo: reghdfe avg_forest award_only treatment_comp, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* fake result -- average forest */
eststo: reghdfe avg_forest            treatment_comp, absorb(svgroup sdygroup c.avg_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

do label_vars.do

global prefoot1 "\hline District-Year F.E.           & Yes & Yes & Yes & Yes \\ "
global prefoot2 "       Village F.E.        & Yes & Yes & Yes & Yes \\ \hline "
estout_default using $out/table_panel, order(award_only treatment_comp ) prefoot("$prefoot1" "$prefoot2") 
estout_default using $out/table_panel, order(award_only treatment_comp ) prefoot("\hline District-Year F.E.           & Yes & Yes & Yes & Yes \\" "       Village F.E.        & Yes & Yes & Yes & Yes \\ \hline ") 
estmod_header  using $out/table_panel.tex, cstring(" & \multicolumn{2}{c}{\underline{Log Forest}} & \multicolumn{2}{c}{\underline{Average Forest}}")

/*****************************/
/* ROBUSTNESS OF MAIN EFFECT */
/*****************************/
eststo clear

/* village time trend */
eststo: reghdfe ln_forest  award_only treatment_comp, absorb(i.svgroup##c.year sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* subdistrict*year fixed effects (this spec only) */
eststo: reghdfe ln_forest  award_only treatment_comp, absorb(svgroup sdsygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* balanced panel, require 5 years pre/post treatment */
eststo: reghdfe ln_forest award_only treatment_comp if has_comp_5 == 1, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* balanced panel, require 4 years pre/post treatment */
eststo: reghdfe ln_forest award_only treatment_comp if has_comp_4 == 1, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* store estimates */
do label_vars.do
global prefoot "\hline    District-Year F.E.     & Yes & No  & Yes & Yes \\ "
global prefoot $prefoot " Subdistrict-Year F.E.  & No  & Yes & No  & No  \\ "
global prefoot $prefoot " Village F.E.           & Yes & Yes & Yes & Yes \\ "
global prefoot $prefoot " Village Time Trends    & Yes & No  & No  & No  \\ "
global prefoot $prefoot " Panel Sample           & Full & Full & +/- 5 Years & +/- 4 Years  \\ \hline "
estout_default using $out/table_panel_robust, order(award_only treatment_comp) prefoot($prefoot) 

/*****************/
/* HETEROGENEITY */
/*****************/
use $tmp/pmgsy_trees, clear
drop if total_forest_2000 == 0
eststo clear
keep if inrange(comp_year, 2001, 2013)

/* set sample to main regression sample */
reghdfe ln_forest award_only treatment_comp, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)
keep if e(sample)

/* high vs low baseline forest */
sum ln_forest_2000, d
gen baseline_forest_high = ln_forest_2000 >= `r(p50)' 
eststo: reghdfe ln_forest award_only treatment_comp if baseline_forest_high == 0, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)
eststo: reghdfe ln_forest award_only treatment_comp if baseline_forest_high == 1, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* high vs low ST share */
sum pc01_st_share, d
gen st_share_high = pc01_st_share >= `r(p50)' 
eststo: reghdfe ln_forest award_only treatment_comp if st_share_high == 0, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)
eststo: reghdfe ln_forest award_only treatment_comp if st_share_high == 1, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* high vs low assets */
sum bpl_assets_none_share, d
gen bpl_poor = bpl_assets_none_share >= `r(p50)' 
eststo: reghdfe ln_forest award_only treatment_comp if bpl_poor == 0, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)
eststo: reghdfe ln_forest award_only treatment_comp if bpl_poor == 1, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

do label_vars.do
global prefoot "\hline"
estout_default using $out/table_panel_het, order(award_only treatment_comp) prefoot($prefoot) mlabel("High" "Low"  "High"  "Low"   "Poor" "Not Poor")
estmod_header  using $out/table_panel_het.tex, cstring(" & \multicolumn{2}{c}{\underline{Baseline Forest}} & \multicolumn{2}{c}{\underline{ST Share}} & \multicolumn{2}{c}{\underline{Asset Poverty}} ")

/*******************************************/
/* MORE HETEROGENEITY FOR REFEREE RESPONSE */
/*******************************************/

/* set sample */
use $tmp/pmgsy_trees, clear
drop if total_forest_2000 == 0
eststo clear
keep if inrange(comp_year, 2001, 2013)
reghdfe ln_forest award_only treatment_comp, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)
keep if e(sample)

/* high vs low town distance */
sum distance100, d
local cut `r(p50)'
gen distance100_high = distance100 > `cut' if !mi(distance100)
eststo: reghdfe ln_forest award_only treatment_comp if distance100_high == 0, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)
eststo: reghdfe ln_forest award_only treatment_comp if distance100_high == 1, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* high vs low market access */
sum market_access, d
local cut `r(p50)'
gen market_access_high = market_access > `cut' if !mi(market_access)
eststo: reghdfe ln_forest award_only treatment_comp if market_access_high == 0, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)
eststo: reghdfe ln_forest award_only treatment_comp if market_access_high == 1, absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* high subdistrict logging */
sum ec98_emp_logging_only, d
local cut `r(p50)'
eststo: reghdfe ln_forest award_only treatment_comp if ec98_emp_logging_only > `cut' & !mi(ec98_emp_logging_only), absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

/* high subd wood use */
sum ec98_emp_wood_use, d
local cut `r(p50)'
eststo: reghdfe ln_forest award_only treatment_comp if ec98_emp_wood_use > `cut' & !mi(ec98_emp_wood_use), absorb(svgroup sdygroup c.ln_forest_2000##i.year c.pc01_pca_tot_p##i.year) cluster(svgroup)

do label_vars.do
global prefoot "\hline"
estout_default using $out/table_panel_het_app, order(award_only treatment_comp) prefoot($prefoot) mlabel("Low" "High"  "Low"  "High"   "High" "High" )
estmod_header  using $out/table_panel_het_app.tex, cstring(" & \multicolumn{2}{c}{\underline{Dist. to Town}} & \multicolumn{2}{c}{\underline{Market Access}} & \underline{Logging} & \underline{Ind. Wood Use}")

/**************/
/* COEF PLOTS */
/**************/
use $tmp/pmgsy_trees, clear
drop if total_forest_2000 == 0
keep if inrange(comp_year, 2001, 2013)

/* constant 4, constant 5 samples */
do label_vars.do
set scheme s2color
qui reghdfe ln_forest tm4_minus_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_plus_comp if has_comp_4 , absorb(svgroup sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year) cluster(svgroup)
coefplot, keep(tm4_minus_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_plus_comp) vert xtitle("Years after Road Completion") ytitle("Residual Log Forest Cover") graphregion(color(white))
graphout coefplot_bal_comp_4, pdf

qui reghdfe ln_forest tm5_minus_comp tm4_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_comp t5_plus_comp if has_comp_5, absorb(svgroup sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year) cluster(svgroup)
coefplot, keep(tm5_minus_comp tm4_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_comp t5_plus_comp) vert  xtitle("Years after Road Completion") ytitle("Residual Log Forest Cover") graphregion(color(white))
graphout coefplot_bal_comp_5, pdf

/* high average forest sample */
preserve
sum ln_forest_2000, d
keep if ln_forest_2000 >= `r(p50)' & !mi(ln_forest_2000)

qui reghdfe ln_forest tm4_minus_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_plus_comp if has_comp_4 , absorb(svgroup sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year) cluster(svgroup)
coefplot, keep(tm4_minus_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_plus_comp) vert xtitle("Years after Road Completion") ytitle("Residual Log Forest Cover") graphregion(color(white))
graphout coefplot_bal_comp_4_thick, pdf
qui reghdfe ln_forest tm5_minus_comp tm4_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_comp t5_plus_comp if has_comp_5, absorb(svgroup sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year) cluster(svgroup)
coefplot, keep(tm5_minus_comp tm4_comp tm3_comp tm2_comp omitted_tm1 t0_comp t1_comp t2_comp t3_comp t4_comp t5_plus_comp) vert  xtitle("Years after Road Completion") ytitle("Residual Log Forest Cover") graphregion(color(white))
graphout coefplot_bal_comp_5_thick, pdf
