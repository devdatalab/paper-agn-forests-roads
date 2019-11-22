/************************/
/* GQ MECHANISM REGS    */
/************************/
/**********************************************************************************/
/* program store_deforest_ests : write regression estimates to a file */
/***********************************************************************************/
cap prog drop store_deforest_ests
prog def store_deforest_ests
{
  syntax, yearlist(numlist) name(string)

  foreach dist in 0 100 {
    foreach year in `yearlist' {
      append_est_to_file using $tmp/gq_mech_ests.csv, b(d_gq_`dist'_`year') s(`dist',`year',`name')
    }
  }

}
end
cap prog drop store_deforest_means
prog def store_deforest_means
{
  syntax varlist, yearlist(numlist) name(string)
  tokenize `varlist'

  reghdfe `1' tdist10 tdist50 tdist500 tdist1000 if dist_gq < 300, ///
    absorb(f1=sygroup f2=c.tdist100##i.year f3=c.pc01_vd_t_p##i.year)
  capdrop resid
  predict resid, resid

  foreach dist in 0 100 200 {
    foreach year in `yearlist' {
      semean resid if year == `year' & dist_gq_cut == `dist'
      local b = `r(mean)'
      local se = `r(semean)'
      append_to_file using $tmp/gq_mech_means.csv, s(`b',`se',`dist',`year',`name')
    }
  }
  drop resid
}
end
/* *********** END program store_deforest_means ***************************************** */

use $tmp/gq_long_regs_subd, clear

/* set global vars */
global controls tdist10 tdist50  tdist500 tdist1000 tdist100 pc01_vd_t_p
global year_controls tdist10 tdist50  tdist500 tdist1000 c.tdist100##i.year c.pc01_vd_t_p##i.year

global cut_size 100
global cut_end 300
global cut_end_less_1 250
global cut_reg_end 199

/* build regression globals */
global d_gq_base
global d_gq_1990
global d_gq_1998
global d_gq_2005
global d_gq_2013
global d_gq_1991
global d_gq_2001
global d_gq_2011
global d_ns_base
global d_ns_1990
global d_ns_1998
global d_ns_2005
global d_ns_2013
global d_ns_1991
global d_ns_2001
global d_ns_2011
forval c = 0($cut_size)$cut_reg_end {
  global d_gq_base $d_gq_base d_gq_`c'
  global d_ns_base $d_ns_base d_ns_`c'
  foreach y in 1990 1991 1998 2001 2005 2011 2013 {
    global d_gq_`y' ${d_gq_`y'} d_gq_`c'_`y'
    global d_ns_`y' ${d_ns_`y'} d_ns_`c'_`y'
  }
}

cap erase $tmp/gq_mech_ests.csv
cap erase $tmp/gq_mech_means.csv
append_to_file using $tmp/gq_mech_ests.csv, s("beta,se,p,n,dist,year,est")

eststo clear
global cluster cluster(sdsgroup)

/* EC WOOD USE */
eststo: reghdfe ln_emp_wood_use $d_gq_1990 $d_gq_1998 $d_gq_2005 $d_gq_2013  ///
  tdist10 tdist50 tdist500 tdist1000 ///
  if dist_gq < 300, absorb(sygroup c.tdist100##i.year c.pc01_vd_t_p##i.year) $cluster
store_deforest_ests, yearlist(1990 1998 2005 2013) name(wood_use) 

/* EC LOGGING */
eststo: reghdfe ln_emp_logging_only $d_gq_1990 $d_gq_1998 $d_gq_2013  ///
  tdist10 tdist50 tdist500 tdist1000 ///
  c.tdist100##i.year c.pc01_vd_t_p##i.year ///  
  if dist_gq < 300, absorb(sygroup) $cluster
store_deforest_ests, yearlist(1990 1998 2013) name(logging_only)

do label_vars
estout_default using $out/gq_mech_ec, order($d_gq_1990 $d_gq_1998 $d_gq_2005 $d_gq_2013) mlabel("Wood Use" "Logging")

eststo clear

/* PC AG LAND SHARE */
eststo: reghdfe ag_land_share $d_gq_1991 $d_gq_2001 $d_gq_2011  ///
  tdist10 tdist50 tdist500 tdist1000 ///
  c.tdist100##i.year c.pc01_vd_t_p##i.year ///  
  if dist_gq < 300, absorb(sygroup) $cluster
store_deforest_ests, yearlist(1991 2001 2011) name(ag_land_share)

/* COOKING FUELS */
eststo: reghdfe cook_fuel_fw $d_gq_2001 $d_gq_2011  ///
  tdist10 tdist50 tdist500 tdist1000 ///
  c.tdist100##i.year c.pc01_vd_t_p##i.year ///  
  if dist_gq < 300, absorb(sygroup) $cluster
store_deforest_ests, yearlist(2001 2011) name(cook_fuel_fw)

eststo: reghdfe cook_fuel_import $d_gq_2001 $d_gq_2011  ///
  tdist10 tdist50 tdist500 tdist1000 ///
  c.tdist100##i.year c.pc01_vd_t_p##i.year ///  
  if dist_gq < 300, absorb(sygroup)  $cluster
store_deforest_ests, yearlist(2001 2011) name(cook_fuel_import)

eststo: reghdfe cook_fuel_nonwood $d_gq_2001 $d_gq_2011  ///
  tdist10 tdist50 tdist500 tdist1000 ///
  c.tdist100##i.year c.pc01_vd_t_p##i.year ///  
  if dist_gq < 300, absorb(sygroup)  $cluster
store_deforest_ests, yearlist(2001 2011) name(cook_fuel_nonwood)

estout_default using $out/gq_mech_land_fuel, order($d_gq_1991 $d_gq_2001 $d_gq_2011) mlabel("Ag Land Share" "Fuel: Firewood" "Fuel: Imported" "Fuel: Local Non-wood")

/******************/
/* GRAPH RESULTS  */
/******************/
insheet using $tmp/gq_mech_ests.csv, clear names
gen beta_high = beta + 1.96 * se
gen beta_low = beta - 1.96 * se

/* dropping estimates with missing data */
drop if inlist(est, "logging_only", "forestry_only") & year == 2005

/* generate all graphs */
levelsof est, local(ests)
foreach est in `ests' {

  if "`est'" == "wood_use" local lab "Log Employment (Wood Products)"
  if "`est'" == "logging_only" local lab "Log Employment (Logging)"
  if "`est'" == "ag_land_share" local lab "Cropped Share of Land"
  if "`est'" == "cook_fuel_fw" local lab "Fuel Share of Firewood"
  if "`est'" == "cook_fuel_import" local lab "Fuel Share of Imported Fuels"
  if "`est'" == "cook_fuel_nonwood" local lab "Fuel Share of Local Non-Wood Products"
    
  /* generate estimates graph */
  twoway ///
    (scatter beta year               if est == "`est'" & dist == 0, msize(small) color("0 0 0"))  ///
       (line beta year               if est == "`est'" & dist == 0, msize(small) lcolor("0 0 0")) ///
       (rcap beta_high beta_low year if est == "`est'" & dist == 0, color("0 0 0")) ///
    , legend(off) graphregion(color(white)) ytitle("Coefficient on Indicator 1(0-100km from GQ)") xtitle("Year") xline(2001) xlabel(1990(5)2015) name(`est', replace) yline(0, lcolor("125 125 125") lpattern("dash"))

  graphout gq_mech_`est', pdf
}
