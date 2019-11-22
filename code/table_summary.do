global village_int_vars comp_year 
global village_2d_vars no_asset st agland fw import nonwood r2011

global subdistrict_int_vars 
global subdistrict_2d_vars avg_forest_2000 avg_forest_2014 dist_gq dist_ns wood_emp log_emp

/***********************************************************/
/* create a single dataset with village stats of interest  */
/***********************************************************/
use $tmp/pmgsy_trees, clear

keep if year == 2001
gen r2011 = comp_year <= 2011
drop if inrange(comp_year, 2012, 2014)

keep pc01_state_id pc01_village_id r2011 comp_year bpl_assets_none_share pc01_st_share

merge 1:1 pc01_state_id pc01_village_id using $tmp/gq_covars, keepusing(pc01_ag_land_share pc01_cook_fuel_fw pc01_cook_fuel_import pc01_cook_fuel_nonwood) nogen

/* shorten varnames */
ren bpl_assets_none_share no_asset
ren pc01_st_share st
ren pc01_ag_land_share agland
ren pc01_cook_fuel_fw fw
ren pc01_cook_fuel_import import
ren pc01_cook_fuel_nonwood nonwood

replace st = st / 1000
save $tmp/deforest_sumstats_village, replace

/******************************************/
/* create subdistrict dataset of interest */
/******************************************/
use $tmp/gq_trees_subd, clear
keep pc01_state_id pc01_district_id pc01_subdistrict_id year avg_forest dist_gq dist_ns

/* generate forest cover in 2000 and 2014 */
gen tmp = avg_forest if year == 2014
bys pc01_state_id pc01_district_id pc01_subdistrict_id: egen avg_forest_2014 = max(tmp)
drop tmp
gen tmp = avg_forest if year == 2001
bys pc01_state_id pc01_district_id pc01_subdistrict_id: egen avg_forest_2000 = max(tmp)
drop tmp

drop year avg_forest
duplicates drop

/* get 1998 village level employment in wood-using and logging firms  */
merge 1:m pc01_state_id pc01_district_id pc01_subdistrict_id using $tmp/gq_covars, keepusing(ec98_emp_wood_use ec98_emp_logging_only) nogen 

/* collapse back down to subdistrict level */
collapse (sum) ec98_emp_wood_use ec98_emp_logging_only (firstnm) dist* avg*, by(pc01_state_id pc01_district_id pc01_subdistrict_id)

/* shorten varnames */
ren ec98_emp_wood_use wood_emp
ren ec98_emp_logging_only log_emp
drop if mi(dist_gq)

save $tmp/deforest_sumstats_subdistrict, replace

/*****************************************/
/* write data for summary stats template */
/*****************************************/

/* erase current summary stat data file */
cap erase $tmp/summary.csv

/* do villages, then subdistricts */
foreach type in village subdistrict {

  /* open the short data file */
  use $tmp/deforest_sumstats_`type', clear
  
  /* loop over and store integer vars */
  foreach v in ${`type'_int_vars} {
    sum `v'
    store_val_tpl using $tmp/summary.csv, name(mean_`v') value(`r(mean)') format(%1.0f)
    store_val_tpl using $tmp/summary.csv, name(sd_`v') value(`r(sd)') format(%1.0f)
    store_val_tpl using $tmp/summary.csv, name(n_`v') value(`r(N)') format(%1.0f)
  }
  
  /* loop over and store decimal vars */
  foreach v in ${`type'_2d_vars} {
    sum `v'
    store_val_tpl using $tmp/summary.csv, name(mean_`v') value(`r(mean)') format(%5.2f)
    store_val_tpl using $tmp/summary.csv, name(sd_`v') value(`r(sd)') format(%5.2f)
    store_val_tpl using $tmp/summary.csv, name(n_`v') value(`r(N)') format(%1.0f)
  }
}

table_from_tpl, t($tmp/summary_tpl.tex) r($tmp/summary.csv) o($out/table_summary.tex)
