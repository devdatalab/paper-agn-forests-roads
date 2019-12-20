/*************/
/* Rural OLS */
/*************/
use $tmp/pmgsy_trees, clear

keep if year == 2000

/* get town distance vars */
merge 1:1 pc01_state_id pc01_village_id using $tmp/pc01_village_town_distances, keep(match) nogen keepusing(distance10 distance50 distance100)

replace pc01_pca_tot_p = pc01_pca_tot_p / 1000
forval i = 1/4 {
  gen p`i' = pc01_pca_tot_p^ `i'
}

group pc01_state_id pc01_district_id
group pc01_state_id

/* run regressions */
eststo clear
eststo: reg ln_forest app_pr
eststo: reg ln_forest app_pr p1-p2, 
eststo: areg ln_forest app_pr p1-p2, absorb(sgroup)
eststo: areg ln_forest app_pr p1-p2, absorb(sdgroup)
eststo: areg ln_forest app_pr p1-p2 distance50 distance100, absorb(sdgroup)
do label_reg_vars.do

/* export regression table */
global prefoot "\hline Fixed Effects              & None & None & State & State & District \\ " 
estout_default using $out/table_ols, prefoot($prefoot)


