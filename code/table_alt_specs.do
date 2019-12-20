/*************************************************************************/
/* calculate forest cover in 5km, 25km and 50km "radius" of each village */
/*************************************************************************/

/* prepare village coordinates */
use $tmp/village_coords_clean, clear

/* calculate total forest in lati/longi grid cell */
egen lat_cut_5 = cut(latitude), at(8(.045)35)
egen lat_cut_25 = cut(latitude), at(8(.225)35)
egen lat_cut_50 = cut(latitude), at(8(.45)35)

egen lon_cut_5 = cut(longitude), at(68(.045)97.1)
egen lon_cut_25 = cut(longitude), at(68(.225)97.1)
egen lon_cut_50 = cut(longitude), at(68(.45)97.1)

foreach i in 5 25 50 {
  egen grid_`i' = group(lat_cut_`i' lon_cut_`i')
}

keep pc01_state_id pc01_village_id grid_*
save $tmp/cells, replace

use $tmp/village_vcf_new, clear

keep pc01_state_id pc01_village_id year total_forest 

/* get village grid cells */
merge m:1 pc01_state_id pc01_village_id using $tmp/cells, keep(match) nogen

/* calculate total forest in each grid cell */
foreach i in 5 25 50 {
  bys grid_`i' year: egen total_forest_cell_`i' = total(total_forest)
  gen ln_forest_cell_`i' = ln(total_forest_cell_`i' + 1)
}

drop total_forest
save $tmp/vcf_grids, replace

/******************************************/
/* generate table with missing award year */
/******************************************/
use $tmp/pmgsy_trees, clear

/* get high radius forest cover measures */
merge 1:1 pc01_state_id pc01_village_id year using $tmp/vcf_grids, keep(master match) nogen

/* calculate baseline high radius forest cover in each group */
foreach i in 5 25 50 {
  cap drop tmp
  gen tmp = (year == 2000) * ln_forest_cell_`i'
  bys pc01_state_id pc01_village_id: egen ln_forest_cell_2000_`i' = max(tmp)
  drop tmp
}

/* drop if zero forest to begin with */
drop if total_forest_2000 == 0

/* generate award-based treatment variable, as in kaczan */
gen award_comp = year >= award_year

/* generate FE groups */
group pc01_state_id pc01_district_id pc01_subdistrict_id 

save $tmp/misspecs, replace

/*******************************************************/
/* MIS-SPECIFICATION TABLE: MORE VILLAGES, WEIRD RADII */
/*******************************************************/
use $tmp/misspecs, clear

/* keep necessary variables for regression and save them into another scratch file */
keep ln_forest* award_only treatment_comp svgroup sdygroup sdsgroup pc01_pca_tot_p *year

/* save the subset of misspecs dataset */
save $tmp/misspecs_reg, replace

eststo clear

/* kaczan estimate -- award period only, few controls  */
eststo: reghdfe ln_forest award_only treatment_comp, absorb(svgroup sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year) cluster(svgroup)

/* add village-specific time trend */
eststo: reghdfe ln_forest award_only treatment_comp, absorb(i.svgroup##c.year sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year) cluster(svgroup)

/* our estimator -- award period only, few controls  */
eststo: reghdfe ln_forest award_only treatment_comp if inrange(comp_year, 2001, 2013), absorb(svgroup sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year ) cluster(svgroup)

/* add village-specific time trend to our estimator */
eststo: reghdfe ln_forest award_only treatment_comp if inrange(comp_year, 2001, 2013), absorb(i.svgroup##c.year sdygroup  c.pc01_pca_tot_p##i.year c.ln_forest_2000##i.year) cluster(svgroup)

/* show wider geographic range results */
foreach i in 5 50 {
  disp_nice "`i'"
  eststo: reghdfe ln_forest_cell_`i' award_only treatment_comp if inrange(comp_year, 2001, 2013), absorb(svgroup sdygroup c.pc01_pca_tot_p##i.year c.ln_forest_cell_2000_`i'##i.year) cluster(sdsgroup)
}

do label_vars

global prefoot1 "\hline District-Year F.E.        & Yes & Yes & Yes & Yes & Yes & Yes \\ "
global prefoot2 "       Village F.E.              & Yes & Yes & Yes & Yes & Yes & Yes \\ "
global prefoot3 "       Village Time Trends.      & No  & Yes & No  & Yes & No  & No \\ "
global prefoot4 "       Village Definition        & Boundary  & Boundary & Boundary  & Boundary & 5 km radius  & 50 km radius \\ \hline "
estout_default using $out/mis_ests, keep(award_only treatment_comp) prefoot("$prefoot1" "$prefoot2" "$prefoot3" "$prefoot4")
