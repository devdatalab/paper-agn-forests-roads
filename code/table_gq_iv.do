cap prog drop gen_gq_dist_cuts_iv
prog def gen_gq_dist_cuts_iv
{
  egen dist_ivgq_cut = cut(dist_gq_instr), at(0 50 100 150 200 250)
  egen dist_ivns_cut = cut(dist_ns_instr), at(0 50 100 150 200 250)
  
  /* generate all group variables */
  forval i = 2001/2014 {
    gen dist_ivgq_cut_`i'_0   = dist_ivgq_cut == 0 & year == `i'
    gen dist_ivgq_cut_`i'_50  = dist_ivgq_cut == 50 & year == `i'
    gen dist_ivgq_cut_`i'_100 = dist_ivgq_cut == 100 & year == `i'
    gen dist_ivgq_cut_`i'_150 = dist_ivgq_cut == 150 & year == `i'
    gen dist_ivgq_cut_`i'_200 = dist_ivgq_cut == 200 & year == `i'
  }
  
  /* repeat for NS */
  forval i = 2001/2014 {
    gen dist_ivns_cut_`i'_0   = dist_ivns_cut == 0 & year == `i'
    gen dist_ivns_cut_`i'_50  = dist_ivns_cut == 50 & year == `i'
    gen dist_ivns_cut_`i'_100 = dist_ivns_cut == 100 & year == `i'
    gen dist_ivns_cut_`i'_150 = dist_ivns_cut == 150 & year == `i'
    gen dist_ivns_cut_`i'_200 = dist_ivns_cut == 200 & year == `i'
  }
  
  tab dist_ivgq_cut, gen(c)
  
  ren c1 c_ivgq_0
  ren c2 c_ivgq_50
  ren c3 c_ivgq_100
  ren c4 c_ivgq_150
  ren c5 c_ivgq_200
  
  /* repeat cuts for NS */
  tab dist_ivns_cut, gen(c_ivns)
  ren c_ivns1 c_ivns_0
  ren c_ivns2 c_ivns_50
  ren c_ivns3 c_ivns_100
  ren c_ivns4 c_ivns_150
  ren c_ivns5 c_ivns_200
  
  /* make sure gq/ns dists aren't missing so we can have arbitrary constrol groups */
  foreach i in 0 50 100 150 200 {
    replace c_ivgq_`i' = 0 if mi(c_ivgq_`i')
    replace c_ivns_`i' = 0 if mi(c_ivns_`i')
  }
}
end

/**********************************************/
/* PRIMARY GQ/NS DISTANCE PLOTS / REGRESSIONS */
/**********************************************/

/* regression version of these plots.
- to reduce dimensions, create three year groups:
  2000: pre
  2001-2004: construction
  2005-end: post                                   */
use $tmp/gq_pre_regs_subd, clear

ren dist_gq_instr2 dist_gq_instr
drop dist_gq_instr1 dist_gq_instr3

gen_gq_dist_cuts_iv

/* first stage of IV */
reg dist_gq dist_gq_instr
reg dist_ns dist_ns_instr

global gq_cons_start 2001
global gq_cons_end   2004
global gq_post_start 2005
global gq_post_end   2008

global ns_cons_start 2004
global ns_cons_end   2008
global ns_post_start 2009
global ns_post_end   2012

/* interact year groups with distance groups for GQ dates */
foreach i in pre cons post post2014 set1 set2 set3 {
  gen dist_ivgq_cut_gq_`i'_0   = dist_ivgq_cut == 0   & gq_year_`i' == 1
  gen dist_ivgq_cut_gq_`i'_50  = dist_ivgq_cut == 50  & gq_year_`i' == 1
  gen dist_ivgq_cut_gq_`i'_100 = dist_ivgq_cut == 100 & gq_year_`i' == 1
  gen dist_ivgq_cut_gq_`i'_150 = dist_ivgq_cut == 150 & gq_year_`i' == 1
  gen dist_ivgq_cut_gq_`i'_200 = dist_ivgq_cut == 200 & gq_year_`i' == 1

/* create placebo NS cuts */
  gen dist_ivns_cut_gq_`i'_0   = dist_ivns_cut == 0   & gq_year_`i' == 1
  gen dist_ivns_cut_gq_`i'_50  = dist_ivns_cut == 50  & gq_year_`i' == 1
  gen dist_ivns_cut_gq_`i'_100 = dist_ivns_cut == 100 & gq_year_`i' == 1
  gen dist_ivns_cut_gq_`i'_150 = dist_ivns_cut == 150 & gq_year_`i' == 1
  gen dist_ivns_cut_gq_`i'_200 = dist_ivns_cut == 200 & gq_year_`i' == 1
}

/* interact year groups with distance groups for NS dates */
foreach i in pre cons post set1 set2 set3 {
  gen dist_ivns_cut_ns_`i'_0   = dist_ivns_cut == 0   & ns_year_`i' == 1
  gen dist_ivns_cut_ns_`i'_50  = dist_ivns_cut == 50  & ns_year_`i' == 1
  gen dist_ivns_cut_ns_`i'_100 = dist_ivns_cut == 100 & ns_year_`i' == 1
  gen dist_ivns_cut_ns_`i'_150 = dist_ivns_cut == 150 & ns_year_`i' == 1
  gen dist_ivns_cut_ns_`i'_200 = dist_ivns_cut == 200 & ns_year_`i' == 1
}
regroup pc01_state_id pc01_district_id 

save $tmp/gq_iv_pre_regs_subd, replace
use $tmp/gq_iv_pre_regs_subd, clear

/****************************/
/* gq / ns regression table */
/****************************/

global end_dist 300

global forest_var ln_forest

/* run regression on log forest */
eststo clear
eststo: reghdfe $forest_var c_ivgq_0 c_ivgq_50 c_ivgq_100 c_ivgq_150 ///
  dist_ivgq_cut_gq_cons_0   dist_ivgq_cut_gq_cons_50   dist_ivgq_cut_gq_cons_100   dist_ivgq_cut_gq_cons_150 ///
  dist_ivgq_cut_gq_post_0   dist_ivgq_cut_gq_post_50   dist_ivgq_cut_gq_post_100   dist_ivgq_cut_gq_post_150 ///
  tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $gq_post_end & dist_gq_instr <= $end_dist [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.${forest_var}_2000##i.year) cluster(sdsgroup)

/* avg forest */
global forest_var avg_forest
eststo: reghdfe $forest_var c_ivgq_0 c_ivgq_50 c_ivgq_100 c_ivgq_150 ///
  dist_ivgq_cut_gq_cons_0   dist_ivgq_cut_gq_cons_50   dist_ivgq_cut_gq_cons_100   dist_ivgq_cut_gq_cons_150 ///
  dist_ivgq_cut_gq_post_0   dist_ivgq_cut_gq_post_50   dist_ivgq_cut_gq_post_100   dist_ivgq_cut_gq_post_150 ///
  tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $gq_post_end & dist_gq_instr <= $end_dist [aw=num_cells], absorb(sygroup   c.tdist100##i.year c.p1##i.year c.${forest_var}_2000##i.year) cluster(sdsgroup)

/* HACK --> TO GET COEFS IN SAME ROWS, WE NEED TO COPY OVER THE VARIABLES
            AND THEN RUN THE SAME REGRESSION */
preserve
{
  foreach i in 0 50 100 150 {
    replace c_ivgq_`i' = c_ivns_`i'
    replace dist_ivgq_cut_gq_cons_`i' = dist_ivns_cut_gq_cons_`i'
    replace dist_ivgq_cut_gq_post_`i' = dist_ivns_cut_gq_post_`i'
  }
  
  /* NSEW PLACEBO FOR GQ CONSTRUCTION */
  /* run regression on log forest */
  eststo: reghdfe ln_forest c_ivgq_0 c_ivgq_50 c_ivgq_100 c_ivgq_150 ///
    dist_ivgq_cut_gq_cons_0   dist_ivgq_cut_gq_cons_50   dist_ivgq_cut_gq_cons_100   dist_ivgq_cut_gq_cons_150 ///
    dist_ivgq_cut_gq_post_0   dist_ivgq_cut_gq_post_50   dist_ivgq_cut_gq_post_100   dist_ivgq_cut_gq_post_150 ///
    tdist10 tdist50 tdist500 tdist1000 ///
    if year <= $gq_post_end & dist_ns_instr <= $end_dist & dist_gq > 150 [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.ln_forest_2000##i.year) cluster(sdgroup)
  
  /* avg forest */
  eststo: reghdfe avg_forest c_ivgq_0 c_ivgq_50 c_ivgq_100 c_ivgq_150 ///
    dist_ivgq_cut_gq_cons_0   dist_ivgq_cut_gq_cons_50   dist_ivgq_cut_gq_cons_100   dist_ivgq_cut_gq_cons_150 ///
    dist_ivgq_cut_gq_post_0   dist_ivgq_cut_gq_post_50   dist_ivgq_cut_gq_post_100   dist_ivgq_cut_gq_post_150 ///
    tdist10 tdist50 tdist500 tdist1000 ///
  if year <= $gq_post_end & dist_ns_instr <= $end_dist & dist_gq > 150 [aw=num_cells], absorb(sygroup c.tdist100##i.year c.p1##i.year c.ln_forest_2000##i.year) cluster(sdgroup)
}
restore

do label_vars.do
do label_reg_vars.do
global prefoot "\hline"
global v1
global v2
global v3
foreach i in 0 50 100 150 {
  global v1 $v1 dist_ivgq_cut_gq_cons_`i'
  global v2 $v2 dist_ivgq_cut_gq_post_`i'
  global v3 $v3 c_ivgq_`i'
}

estout_default using $out/table_gq_iv, order($v1 $v2 $v3) prefoot($prefoot) mlabel("Log Forest" "Avg Forest" "Log Forest" "Average Forest")
estmod_header  using $out/table_gq_iv.tex, cstring(" & \multicolumn{2}{c}{\underline{GQ (Straight Line)}} & \multicolumn{2}{c}{\underline{NSEW (Straight Line)}}")

