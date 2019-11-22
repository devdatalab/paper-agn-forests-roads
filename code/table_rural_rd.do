/* open VCF RD dataset */
use $tmp/trees_rd_working, clear

/*****************************/
/* MAIN TABLE: 2013 OUTCOMES */
/*****************************/
eststo clear

/* Column 1: First Stage */
eststo: reghdfe got_road t left right ln_forest_2000 if rd_band_2_ & year == 2013, absorb(dist_high_fe) 

/* Column 2: RF logs */
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013, absorb(dist_high_fe) 

/* Column 3: RF average */
eststo: reghdfe avg_forest t left right avg_forest_2000 if rd_band_2_ & year == 2013, absorb(dist_high_fe) 

/* Column 4: >50% baseline forest */
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & ln_forest_2000 >= 4.343805, absorb(dist_high_fe) 

/* Column 5: lotsa STs */
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & pc01_st_share >= 184.0278, absorb(dist_high_fe) 

/* Column 6: poor places */
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & bpl_assets_none_share  <= 0.9150327, absorb(dist_high_fe) 

/* Column 7: IV logs */
eststo: ivregress 2sls ln_forest (got_road=t) left right ln_forest_2000 i.dist_high_fe if rd_band_2_ & year == 2013, 

/* Column 8: IV average forest */
eststo: ivregress 2sls avg_forest (got_road=t) left right ln_forest_2000 i.dist_high_fe if rd_band_2_ & year == 2013, 

/* label variables */
do label_vars.do
global prefoot "\hline" 
estout_default using $out/table_rd, order(t got_road) prefoot($prefoot) mlabel("Any Road" "Log Forest" "Avg Forest" "High Baseline" "High ST" "Low Assets" "Log Forest" "Avg Forest")
estmod_header  using $out/table_rd.tex, cstring(" & \underline{First Stage} & \multicolumn{5}{c}{\underline{Reduced Form}} & \multicolumn{2}{c}{\underline{IV}}")

/**********************************/
/* APPENDIX TABLE: ALL BANDWIDTHS */
/**********************************/
eststo clear

/* Columns 1-4: RF logs */
foreach b in 50 100 150 200 {
  eststo: reghdfe ln_forest t left right ln_forest_2000 if abs(left) <= `b' & abs(right) <= `b' & year == 2013, absorb(dist_high_fe) 
}

/* Columns 5-8: RF averages */
foreach b in 50 100 150 200 {
  eststo: reghdfe avg_forest t left right avg_forest_2000 if abs(left) <= `b' & abs(right) <= `b' & year == 2013, absorb(dist_high_fe) 
}

do label_vars.do
global prefoot "\hline Bandwidth              & 50 & 100 & 150 & 200 & 50 & 100 & 150 & 200 \\ " 
estout_default using $out/table_rd_band, order(t) prefoot($prefoot) 
estmod_header  using $out/table_rd_band.tex, cstring(" & \multicolumn{4}{c}{\underline{Log Forest (2013)}} & \multicolumn{4}{c}{\underline{Average Forest (2013)}}")

/****************************/
/* APPENDIX TABLE: FUEL USE */
/****************************/
eststo clear
foreach w in cook_fuel_import cook_fuel_nonwood cook_fuel_fw {
  eststo: reghdfe pc11_`w' t left right ln_forest_2000 pc01_`w' if rd_band_2_ & year == 2013, absorb(dist_high_fe)
}
do label_vars.do
global prefoot "\hline" 
estout_default using $out/table_rd_fuel, order(t) prefoot($prefoot) mlabel("Imports" "Local Non-Wood" "Firewood")

/**********************************************************************/
/* APPENDIX TABLE: RD FOR FOUR OTHER VARIABLES PREDICTING WOOD DEMAND */
/**********************************************************************/

/* open VCF RD dataset */
use $tmp/trees_rd_working, clear
eststo clear

/* set sample */
reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013, absorb(dist_high_fe) 
keep if e(sample)

/* Column 1: Close to town */
sum distance100, d
local cut `r(p50)'
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & distance100 <= `cut', absorb(dist_high_fe) 

/* Column 2: Far from town */
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & distance100 >= `cut' & !mi(distance100), absorb(dist_high_fe)

/* Column 3: High Market Access */
sum market_access, d
local cut `r(p50)'
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & market_access <= `cut', absorb(dist_high_fe) 

/* Column 4: Low Market Access */
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & market_access >= `cut' & !mi(market_access), absorb(dist_high_fe)

/* Column 5: High Subdistrict Logging */
sum ec98_emp_logging_only, d
local cut `r(p50)'
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & ec98_emp_logging_only >= `cut' & !mi(ec98_emp_logging_only), absorb(dist_high_fe)

/* Column 6: High Subdistrict Wood-Using Industries */
sum ec98_emp_wood_use, d
local cut `r(p50)'
eststo: reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == 2013 & ec98_emp_wood_use >= `cut' & !mi(ec98_emp_wood_use), absorb(dist_high_fe)

/* label variables */
do label_vars.do
global prefoot "\hline" 
estout_default using $out/table_rd_het, order(t) prefoot($prefoot) mlabel("Low" "High"  "Low"  "High"   "High" "High")
estmod_header  using $out/table_rd_het.tex, cstring(" & \multicolumn{2}{c}{\underline{Dist. to Town}} & \multicolumn{2}{c}{\underline{Market Access}} & \underline{Logging} & \underline{Ind. Wood Use}")

/******************************************/
/* FIRST STAGE AND REDUCED FORM RD GRAPHS */
/******************************************/

/* open VCF RD dataset and set sample */
use $tmp/trees_rd_working, clear

/* store estimates from regression for each year */
global f $tmp/vcf_rd.csv
cap erase $f
append_to_file using $f, s(beta,se,p,n,spec,year)
forval i = 2002/2013 {
  reghdfe got_road t left right ln_forest_2000 if rd_band_2_ & year == `i', absorb(dist_high_fe) 
  append_est_to_file using $f, b(t) s(fs,`i')

  reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & year == `i', absorb(dist_high_fe) 
  append_est_to_file using $f, b(t) s(rf,`i')
}

import delimited using $tmp/vcf_rd.csv, clear
gen beta_high = beta + 1.96 * se
gen beta_low  = beta - 1.96 * se

/* draw first stage graph */
twoway (scatter beta year, mcolor(black)) (rcap beta_high beta_low year , lcolor(black)) if spec == "fs", yline(0, lcolor(gs8)) xtitle("Year") ytitle("RD First Stage Coefficient in Year X") graphregion(color(white)) legend(off)
graphout rd_coefs_fs, pdf

twoway (scatter beta year, mcolor(black)) (rcap beta_high beta_low year , lcolor(black)) if spec == "rf", ylabel(-.1(.05).1) yline(0, lcolor(gs8)) xtitle("Year") ytitle("RD Reduced Form Coefficient" "(y = Log Forest Cover in Year X)") graphregion(color(white)) legend(off)
graphout rd_coefs_ln_forest, pdf

/***********************************************/
/* RD FIRST STAGE AND REDUCED FORM BINSCATTERS */
/***********************************************/
use $tmp/trees_rd_working, clear
binscatter got_road pop_rd if year == 2013 & inrange(pop_rd, -250, 250), linetype(none) xline(0) rd(0) name(fs, replace) xq(xq25) ytitle("New Road (by 2013)") xtitle("Population Minus Threshold")
graphout rd_bins_fs, pdf

binscatter ln_forest_resid pop_rd if year == 2013 & inrange(pop_rd, -250, 250), linetype(none) xline(0) rd(0) name(fs, replace) xq(xq25) ytitle("Log Forest Cover (2013)") xtitle("Population Minus Threshold")
graphout rd_bins_ln_forest, pdf 

/*************************************/
/* RD BALANCE GRAPHS -- REDUCED FORM */
/*************************************/
use $tmp/trees_rd_working, clear
drop if pop_rd == -100

/* get forest change 2000->2005 */
bys svgroup: egen ln_forest_2005 = max((year == 2005) * ln_forest)
gen ln_forest_change = ln_forest_2005 - ln_forest_2000

rd ln_forest_change pop_rd if rd_band_2_ & year == 2000 & !(comp_year < 2007), s(-100) e(100) degree(1) bins(20) absorb(dist_high_fe) control(ln_forest_2000) bw name(ln_change) xtitle("Population Minus Threshold") ytitle("") title("Change in Log Forest (2000-2005)", size(small))
gt rd_base_forest_trend

rd ln_forest_2000 pop_rd if rd_band_2_ & year == 2000, s(-100) e(100) degree(1) bins(20) absorb(dist_high_fe)  bw name(ln_base) xtitle("Population Minus Threshold") ytitle("") title("Log Forest Cover (2000)", size(small))
gt rd_base_forest

rd avg_forest_2000 pop_rd if rd_band_2_ & year == 2000, s(-100) e(100) degree(1) bins(20) absorb(dist_high_fe)  bw name(avg_base) xtitle("Population Minus Threshold") ytitle("") title("Average Forest Cover (2000)", size(small))
gt rd_base_avg_forest

rd pc01_cook_fuel_fw pop_rd if rd_band_2_ & year == 2000, s(-100) e(100) degree(1) bins(20) absorb(dist_high_fe)  control(ln_forest_2000) bw name(cook_fw) xtitle("Population Minus Threshold") ytitle("") title("Share of Households Using Firewood (2001)", size(small))
gt rd_base_fw

rd ln_light_2000 pop_rd if rd_band_2_ & year == 2000, s(-100) e(100) degree(1) bins(20) absorb(dist_high_fe)  control(ln_forest_2000) bw name(ln_light_2000) xtitle("Population Minus Threshold") ytitle("") title("Log Night Lights (2000)", size(small))
gt rd_ln_light_2000

rd avg_light_2000 pop_rd if rd_band_2_ & year == 2000, s(-100) e(100) degree(1) bins(20) absorb(dist_high_fe)  control(ln_forest_2000) bw name(avg_light_2000) xtitle("Population Minus Threshold") ytitle("") title("Average Night Light (2000)", size(small))
gt rd_avg_light_2000

graph combine ln_base avg_base ln_change cook_fw ln_light_2000 avg_light_2000, rows(3) xcommon graphregion(color(white))
graphout rd_baseline_graphs, pdf

