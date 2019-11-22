/**********************************************/
/* PRIMARY GQ/NS DISTANCE PLOTS / REGRESSIONS */
/**********************************************/

/* regression version of these plots.
- to reduce dimensions, create three year groups:
  2000: pre
  2001-2004: construction
  2005-end: post                                   */
use $tmp/gq_trees_subd, clear

global gq_cons_start 2001
global gq_cons_end   2004
global gq_post_start 2005
global gq_post_end   2008

global ns_cons_start 2004
global ns_cons_end   2008
global ns_post_start 2009
global ns_post_end   2012

gen gq_year_pre = year == 2000
gen gq_year_cons = inrange(year, $gq_cons_start, $gq_cons_end)
gen gq_year_post = inrange(year, $gq_post_start, $gq_post_end)
gen gq_year_post2014 = inrange(year, $gq_post_start, 2014)

/* create NS treatment vars */
gen ns_year_pre = inrange(year, 2000, $ns_cons_start - 1)
gen ns_year_cons = inrange(year, $ns_cons_start, $ns_cons_end)
gen ns_year_post = inrange(year, $ns_post_start, $ns_post_end)

/* create a set of 4-year bands covering the entire study period */
gen ns_year_set1 = inrange(year, 2001, 2004)
gen ns_year_set2 = inrange(year, 2005, 2008)
gen ns_year_set3 = inrange(year, 2009, 2012)
gen ns_year_set3_full = inrange(year, 2009, 2014)
gen gq_year_set1 = inrange(year, 2001, 2004)
gen gq_year_set2 = inrange(year, 2005, 2008)
gen gq_year_set3 = inrange(year, 2009, 2012)
gen gq_year_set3_full = inrange(year, 2009, 2014)

/* interact year groups with distance groups for GQ dates */
foreach i in pre cons post post2014 set1 set2 set3 set3_full {
  gen dist_gq_cut_gq_`i'_0   = dist_gq_cut == 0   & gq_year_`i' == 1
  gen dist_gq_cut_gq_`i'_50  = dist_gq_cut == 50  & gq_year_`i' == 1
  gen dist_gq_cut_gq_`i'_100 = dist_gq_cut == 100 & gq_year_`i' == 1
  gen dist_gq_cut_gq_`i'_150 = dist_gq_cut == 150 & gq_year_`i' == 1
  gen dist_gq_cut_gq_`i'_200 = dist_gq_cut == 200 & gq_year_`i' == 1

/* create placebo NS cuts */
  gen dist_ns_cut_gq_`i'_0   = dist_ns_cut == 0   & gq_year_`i' == 1
  gen dist_ns_cut_gq_`i'_50  = dist_ns_cut == 50  & gq_year_`i' == 1
  gen dist_ns_cut_gq_`i'_100 = dist_ns_cut == 100 & gq_year_`i' == 1
  gen dist_ns_cut_gq_`i'_150 = dist_ns_cut == 150 & gq_year_`i' == 1
  gen dist_ns_cut_gq_`i'_200 = dist_ns_cut == 200 & gq_year_`i' == 1

}

/* interact year groups with distance groups for NS dates */
foreach i in pre cons post set1 set2 set3 set3_full {
  gen dist_ns_cut_ns_`i'_0   = dist_ns_cut == 0   & ns_year_`i' == 1
  gen dist_ns_cut_ns_`i'_50  = dist_ns_cut == 50  & ns_year_`i' == 1
  gen dist_ns_cut_ns_`i'_100 = dist_ns_cut == 100 & ns_year_`i' == 1
  gen dist_ns_cut_ns_`i'_150 = dist_ns_cut == 150 & ns_year_`i' == 1
  gen dist_ns_cut_ns_`i'_200 = dist_ns_cut == 200 & ns_year_`i' == 1
}
regroup pc01_state_id pc01_district_id 

save $tmp/gq_pre_regs_subd, replace
use $tmp/gq_pre_regs_subd, clear

/****************************/
/* gq / ns regression table */
/****************************/
global end_dist 300
global forest_var ln_forest

/* run regression on log forest */
eststo clear
eststo: reghdfe $forest_var c_gq_0 c_gq_50 c_gq_100 c_gq_150 ///
  dist_gq_cut_gq_cons_0   dist_gq_cut_gq_cons_50   dist_gq_cut_gq_cons_100   dist_gq_cut_gq_cons_150 ///
  dist_gq_cut_gq_post_0   dist_gq_cut_gq_post_50   dist_gq_cut_gq_post_100   dist_gq_cut_gq_post_150 ///
  tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $gq_post_end & dist_gq <= $end_dist [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.${forest_var}_2000##i.year) cluster(sdgroup)

/* avg forest */
global forest_var avg_forest
eststo: reghdfe $forest_var c_gq_0 c_gq_50 c_gq_100 c_gq_150 ///
  dist_gq_cut_gq_cons_0   dist_gq_cut_gq_cons_50   dist_gq_cut_gq_cons_100   dist_gq_cut_gq_cons_150 ///
  dist_gq_cut_gq_post_0   dist_gq_cut_gq_post_50   dist_gq_cut_gq_post_100   dist_gq_cut_gq_post_150 ///
  tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $gq_post_end & dist_gq <= $end_dist [aw=num_cells], absorb(sygroup   c.tdist100##i.year c.p1##i.year c.${forest_var}_2000##i.year) cluster(sdgroup)

/* LATEX TRICK --> TO GET COEFS IN SAME ROWS, WE NEED TO COPY OVER THE VARIABLES
                   AND THEN RUN THE SAME REGRESSION */
preserve
{
  foreach i in 0 50 100 150 {
    replace c_gq_`i' = c_ns_`i'
    replace dist_gq_cut_gq_cons_`i' = dist_ns_cut_gq_cons_`i'
    replace dist_gq_cut_gq_post_`i' = dist_ns_cut_gq_post_`i'
  }
  
  /* NSEW PLACEBO FOR GQ CONSTRUCTION */
  /* run regression on log forest */
  eststo: reghdfe ln_forest c_gq_0 c_gq_50 c_gq_100 c_gq_150 ///
    dist_gq_cut_gq_cons_0   dist_gq_cut_gq_cons_50   dist_gq_cut_gq_cons_100   dist_gq_cut_gq_cons_150 ///
    dist_gq_cut_gq_post_0   dist_gq_cut_gq_post_50   dist_gq_cut_gq_post_100   dist_gq_cut_gq_post_150 ///
    tdist10 tdist50 tdist500 tdist1000 ///
    if year <= $gq_post_end & dist_ns <= $end_dist & dist_gq > 100 [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.ln_forest_2000##i.year) cluster(sdgroup)
  
  /* avg forest */
  eststo: reghdfe avg_forest c_gq_0 c_gq_50 c_gq_100 c_gq_150 ///
    dist_gq_cut_gq_cons_0   dist_gq_cut_gq_cons_50   dist_gq_cut_gq_cons_100   dist_gq_cut_gq_cons_150 ///
    dist_gq_cut_gq_post_0   dist_gq_cut_gq_post_50   dist_gq_cut_gq_post_100   dist_gq_cut_gq_post_150 ///
    tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $gq_post_end & dist_ns <= $end_dist & dist_gq > 100 [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.ln_forest_2000##i.year) cluster(sdgroup)
}
restore

do label_vars.do
do label_reg_vars.do
global prefoot "\hline"
global v1
global v2
global v3
foreach i in 0 50 100 150 {
  global v1 $v1 dist_gq_cut_gq_cons_`i'
  global v2 $v2 dist_gq_cut_gq_post_`i'
  global v3 $v3 c_gq_`i'
}

estout_default using $out/table_gq, order($v1 $v2 $v3) prefoot($prefoot) mlabel("Log Forest" "Avg Forest" "Log Forest" "Average Forest")
estmod_header  using $out/table_gq.tex, cstring(" & \multicolumn{2}{c}{\underline{GQ (Treatment)}} & \multicolumn{2}{c}{\underline{NSEW (Placebo)}}")

/**************************/
/* NSEW TREATMENT EFFECTS */
/**************************/
eststo clear
eststo: reghdfe ln_forest c_ns_0 c_ns_50 c_ns_100 c_ns_150 ///
  dist_ns_cut_ns_cons_0   dist_ns_cut_ns_cons_50   dist_ns_cut_ns_cons_100   dist_ns_cut_ns_cons_150 ///
  dist_ns_cut_ns_post_0   dist_ns_cut_ns_post_50   dist_ns_cut_ns_post_100   dist_ns_cut_ns_post_150 ///
  tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $ns_post_end & dist_ns <= $end_dist & dist_gq > 100 [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.ln_forest_2000##i.year) cluster(sdsgroup)
  
/* avg forest */
eststo: reghdfe avg_forest c_ns_0 c_ns_50 c_ns_100 c_ns_150 ///
  dist_ns_cut_ns_cons_0   dist_ns_cut_ns_cons_50   dist_ns_cut_ns_cons_100   dist_ns_cut_ns_cons_150 ///
  dist_ns_cut_ns_post_0   dist_ns_cut_ns_post_50   dist_ns_cut_ns_post_100   dist_ns_cut_ns_post_150 ///
  tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $ns_post_end & dist_ns <= $end_dist & dist_gq > 100 [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.avg_forest_2000##i.year) cluster(sdsgroup)

do label_vars.do
do label_reg_vars.do
global prefoot "\hline"
global v1
global v2
global v3
foreach i in 0 50 100 150 {
  global v1 $v1 dist_ns_cut_ns_cons_`i'
  global v2 $v2 dist_ns_cut_ns_post_`i'
  global v3 $v3 c_ns_`i'
}
estout_default using $out/table_nsew, order($v1 $v2 $v3) prefoot($prefoot) mlabel("Log Forest" "Avg Forest")
