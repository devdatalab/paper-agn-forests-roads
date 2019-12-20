/**********************/
/* manual binscatters */
/**********************/
use $tmp/gq_pre_regs_subd, clear

global end_dist 200
global end_year 2008
global knn 50
global ylabel ylabel(9.5(1)12.5)
global ylabel

drop if inrange(real(pc01_state_id), 11, 18)
keep if inlist(year, 2000, $end_year)

expand 2, gen(ns)
gen gq = 1 - ns

replace dist_gq = . if ns
replace dist_ns = . if gq

gen y = ln_forest

/* create forest change */
gen tmp = y if year == 2000
bys sdsgroup: egen y_start = max(tmp)
drop tmp
gen tmp = y if year == $end_year
bys sdsgroup: egen y_end = max(tmp)
drop tmp
gen y_change = y_end - y_start

running y dist_gq if dist_gq <= $end_dist & year == 2000 , gen(gq_base) gense(gq_base_se) knn($knn)
running y dist_ns if dist_ns <= $end_dist & year == 2000 , gen(ns_base) gense(ns_base_se) knn($knn)
running y dist_gq if dist_gq <= $end_dist & year == $end_year , gen(gq_end) gense(gq_end_se) knn($knn)
running y dist_ns if dist_ns <= $end_dist & year == $end_year , gen(ns_end) gense(ns_end_se) knn($knn)
running y_change dist_gq if dist_gq <= $end_dist & year == 2000 , gen(gq_diff) gense(gq_diff_se) knn($knn)
running y_change dist_ns if dist_ns <= $end_dist & year == 2000 , gen(ns_diff) gense(ns_diff_se) knn($knn)

foreach v in base end diff {
  gen gq_`v'_low = gq_`v' + 1.96 * gq_`v'_se
  gen gq_`v'_high = gq_`v' - 1.96 * gq_`v'_se
  
  gen ns_`v'_low = ns_`v' + 1.96 * ns_`v'_se
  gen ns_`v'_high = ns_`v' - 1.96 * ns_`v'_se
}

sort dist_gq dist_ns

twoway ///
       (rarea ns_diff_high ns_diff_low dist_ns if dist_ns <= $end_dist & year == 2000, color(red*0.25)) ///
       (line ns_diff dist_ns                   if dist_ns <= $end_dist & year == 2000, lpattern(".") lcolor(red)) ///
       (rarea gq_diff_high gq_diff_low dist_gq if dist_gq <= $end_dist & year == 2000, color(gs14%30)) ///
       (line gq_diff dist_gq                   if dist_gq <= $end_dist & year == 2000, lcolor(black)) ///
 , legend(lab(2 "North-South/East-West") lab(4 "Golden Quadrilateral") order(4 2)) ytitle("Change in Log Forest 2000-2008") xtitle("Distance (km) to Highway")
graphout ns_gq_diff, pdf

twoway ///
       (rarea ns_base_high ns_base_low dist_ns if dist_ns <= $end_dist & year == 2000, color(red*0.25)) ///
       (line ns_base dist_ns                   if dist_ns <= $end_dist & year == 2000, lpattern(".") lcolor(red)) ///
       (rarea gq_base_high gq_base_low dist_gq if dist_gq <= $end_dist & year == 2000, color(gs14%30)) ///
       (line gq_base dist_gq                   if dist_gq <= $end_dist & year == 2000, lcolor(black)) ///
 , $ylabel legend(lab(2 "North-South/East-West") lab(4 "Golden Quadrilateral") order(4 2)) ytitle("Log Total Forest (2000)") xtitle("Distance (km) to Highway")
graphout ns_gq_base, pdf

