/* REGRESSION ESTIMATES THAT EXPLOIT TIMING OF GQ CONSTRUCTION */

/* Note that we don't like this estimation as much as the main
estimation in the paper because there are big network externalities to
highways -- your piece doesn't matter if the pieces around it aren't
built, and the converse--if the pieces around you are built and yours
is not, you still get huge benefits. Esp. since this is an expansion
of existing roads. */

use $tmp/gq_trees_subd, clear

drop if mi(end_year) | mi(start_year)
drop if dist_gq > 300

gen close = dist_gq < 100

/* create some relative year variables */
gen relative_year = year - round(end_year)
gen pos_rel_year = relative_year
replace pos_rel_year = 0 if relative_year < 0

/* create three year groups corresponding to pre, during, and post */
gen cons_year = year <= end_year & year >= start_year
gen pre_year = year < start_year
gen post_year = year > end_year

/* create more details versions of close */
gen close_50_1 = inrange(dist_gq, 0, 50)
gen close_50_2 = inrange(dist_gq, 50, 100)
gen close_50_3 = inrange(dist_gq, 100, 150)
gen close_50_4 = inrange(dist_gq, 150, 200)
gen close_50_5 = inrange(dist_gq, 200, 250)
gen close_100_1 = inrange(dist_gq, 0, 100)
gen close_100_2 = inrange(dist_gq, 100, 200)

/* interact these three variables with close */
foreach v in cons pre post {
  gen close_`v'_year = `v'_year * close
  forval c = 1/5 {
    gen close_50_`c'_`v'_year = `v'_year * close_50_`c'
  }
  forval c = 1/2 {
    gen close_100_`c'_`v'_year = `v'_year * close_100_`c'
  }
}

/* Column 1: Single indicator for close = within 100 km close definition */
eststo clear
eststo: reghdfe ln_forest close cons_year post_year close_cons_year close_post_year tdist10 tdist50 tdist500 tdist1000, absorb(sygroup c.tdist100##i.year c.p1##i.year c.ln_forest_2000##i.year) cluster(sdsgroup)

/* Column 2: Break up close into two 100km bands */
capdrop close_100_1_cons_year close_100_1_post_year
eststo: reghdfe ln_forest close close_100_2 close_cons_year close_100_*cons* close_post_year close_100_*post* cons_year post_year tdist10 tdist50 tdist500 tdist1000, absorb(sygroup c.tdist100##i.year c.p1##i.year c.ln_forest_2000##i.year) cluster(sdsgroup)

label var close  "Distance_{GQ} $\leq$ 100 km"
label var cons_year "Construction Year"
label var post_year "Post-Construction Year"
label var close_cons_year "Construction Year * Distance_{GQ} $\leq$ 100 km"
label var close_post_year "Post-Construction Year * Distance_{GQ} $\leq$ 100 km"
label var close_100_2 "Distance_{GQ} $\in$ (100, 200) km"
label var close_100_2_cons_year "Construction Year * Distance_{GQ} $\in$ (100, 200) km"
label var close_100_2_post_year "Post-Construction Year * Distance_{GQ} $\in$ (100, 200) km"

estout_default using $out/table_gq_timing, prefoot("\hline") keep(close cons_year post_year close_cons_year close_post_year close_100_2 close_100_2_cons_year close_100_2_post_year)

