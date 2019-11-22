use $tmp/gq_trees, clear

keep if dist_gq < 300 | dist_ns < 300

/* cut distance into 10km bins */
egen dist_gq_cut = cut(dist_gq), at(0(10)300)
egen dist_ns_cut = cut(dist_ns),    at(0(10)300)

tab dist_gq_cut, gen(d_gq_)
tab dist_ns_cut, gen(d_ns_)

forval d = 1/30 {
  forval y = 2000/2014 {
    gen d_gq_`d'_y`y' = d_gq_`d' * (year == `y')
    gen d_ns_`d'_y`y' = d_ns_`d' * (year == `y')
  }
}

regroup pc01_state_id year

/* drop the last distance group -- that is the omitted category */
drop d_gq_30* d_ns_30*

/* create vars for four different 4-year periods */
forval d = 1/29 {
  gen d_gq_`d'_2001_2004 = d_gq_`d'_y2001 | d_gq_`d'_y2002 | d_gq_`d'_y2003 | d_gq_`d'_y2004
  gen d_ns_`d'_2001_2004 = d_ns_`d'_y2001 | d_ns_`d'_y2002 | d_ns_`d'_y2003 | d_ns_`d'_y2004
  
  gen d_gq_`d'_2005_2008 = d_gq_`d'_y2005 | d_gq_`d'_y2006 | d_gq_`d'_y2007 | d_gq_`d'_y2008
  gen d_ns_`d'_2005_2008 = d_ns_`d'_y2005 | d_ns_`d'_y2006 | d_ns_`d'_y2007 | d_ns_`d'_y2008
  
  gen d_gq_`d'_2009_2012 = d_gq_`d'_y2009 | d_gq_`d'_y2010 | d_gq_`d'_y2011 | d_gq_`d'_y2012
  gen d_ns_`d'_2009_2012 = d_ns_`d'_y2009 | d_ns_`d'_y2010 | d_ns_`d'_y2011 | d_ns_`d'_y2012
}

/* remove distance dummies > 250km so omitted category is 250-300km */
drop d_gq_26_2001_2004-d_ns_29_2009_2012
drop d_gq_26_y2000-d_ns_29_y2000

save $tmp/v_saturated, replace
use  $tmp/v_saturated, clear

/***************************/
/* 4 YEAR GROUP REGRESSION */
reghdfe ln_forest d_gq_*_y2000 d_gq_*_20*_20* tdist10 tdist50  tdist500 tdist1000 c.tdist100##i.year c.p1##i.year [aw=num_cells] if dist_gq < 300 & inrange(year, 2000, 2012), absorb(sygroup) cluster(sdsgroup)

global fgroup_gq $tmp/gq_group_ests_village.csv
global fgroup_ns $tmp/ns_group_ests_village.csv

/* store estimates to a file */
cap erase $fgroup_gq
append_to_file  using $fgroup_gq, s("beta,se,p,n,dist,year,est")
forval d = 1/25 {

  append_est_to_file using $fgroup_gq, b(d_gq_`d'_y2000) s(`d',2000,gq_group)

  foreach y in 2001 2005 2009 {
    local yp3 = `y' + 3
    append_est_to_file using $fgroup_gq, b(d_gq_`d'_`y'_`yp3') s(`d',`y',gq_group)
  }
}

/****************/
/* NS VERSION */
/****************/
reghdfe ln_forest d_ns_*_y2000 d_ns_*_20*_20* tdist10 tdist50  tdist500 tdist1000 c.tdist100##i.year c.p1##i.year [aw=num_cells] if inrange(year, 2000, 2012) & dist_gq > 150 & dist_ns < 300, absorb(sygroup) cluster(sdsgroup)

/* store estimates to a file */
cap erase $fgroup_ns
append_to_file  using $fgroup_ns, s("beta,se,p,n,dist,year,est")
forval d = 1/25 {

  append_est_to_file using $fgroup_ns, b(d_ns_`d'_y2000) s(`d',2000,ns_group)
  
  foreach y in 2001 2005 2009 {
    local yp3 = `y' + 3
    append_est_to_file using $fgroup_ns, b(d_ns_`d'_`y'_`yp3') s(`d',`y',ns_group)
  }
}

/**************************/
/* plot 4-group GQ result */
/**************************/
insheet using $fgroup_gq, clear names
gen xpos = dist*10 + (year - 2000) / 100
gen beta_high = beta + 1.96 * se
gen beta_low = beta - 1.96 * se

global y1 2000
global y2 2001
global y3 2005
global y4 2009
twoway ///
  (scatter beta xpos if year == $y1, msymbol(o) msize(small) color("  0 0 0"))   (line beta xpos if year == $y1, msize(small)            lcolor("0 0 0"))        ///
  (scatter beta xpos if year == $y2, msymbol(T) msize(small) color(" 80 0 0"))   (line beta xpos if year == $y2, msize(small) lpattern("-") lcolor("80 0 0"))    ///
  (scatter beta xpos if year == $y3, msymbol(x) msize(small) color("160 0 0"))   (line beta xpos if year == $y3, msize(small) lpattern(".") lcolor("160 0 0"))   ///
  (scatter beta xpos if year == $y4, msymbol(sh) msize(small) color("240 0 0")) (line beta xpos if year == $y4, msize(small)   lpattern(".-") lcolor("240 0 0"))  ///
  , legend(order(1 3 5 7) lab(1 "$y1") lab(3 "$y2-2004") lab(5 "$y3-2008") lab(7 "$y4-2012")) graphregion(color(white)) ytitle("Log Forest") xtitle("Distance from GQ (km)") ylabel(-.5(.25).5)
graphout gq_group_plot_village_sparse, pdf large

/**************************/
/* 4 group NS result */
/**************************/
insheet using $fgroup_ns, clear names
gen xpos = dist*10 + (year - 2000) / 100
gen beta_high = beta + 1.96 * se
gen beta_low = beta - 1.96 * se

global y1 2000
global y2 2001
global y3 2005
global y4 2009
twoway ///
  (scatter beta xpos if year == $y1, msymbol(o) msize(small) color("  0 0 0"))   (line beta xpos if year == $y1, msize(small)            lcolor("0 0 0"))        ///
  (scatter beta xpos if year == $y2, msymbol(T) msize(small) color(" 80 0 0"))   (line beta xpos if year == $y2, msize(small) lpattern("-") lcolor("80 0 0"))    ///
  (scatter beta xpos if year == $y3, msymbol(x) msize(small) color("160 0 0"))   (line beta xpos if year == $y3, msize(small) lpattern(".") lcolor("160 0 0"))   ///
  (scatter beta xpos if year == $y4, msymbol(sh) msize(small) color("240 0 0")) (line beta xpos if year == $y4, msize(small)   lpattern(".-") lcolor("240 0 0"))  ///
  , legend(order(1 3 5 7) lab(1 "$y1") lab(3 "$y2-2004") lab(5 "$y3-2008") lab(7 "$y4-2012")) graphregion(color(white)) ytitle("Log Forest") xtitle("Distance from NS-EW (km)") ylabel(-.5(.25).5)
graphout ns_group_plot_village_sparse, pdf large
