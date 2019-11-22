global balance_start \begin{tabular}{l r r}\hline\hline Variable & RD Estimate \\ \hline
global balance_end "\hline\hline \multicolumn{2}{p{24em}}{\$^{*}p<0.10, ^{**}p<0.05,^{***}p<0.01\$} \\ \end{tabular} "
global sum_stat_vars 

global baseline_vars ln_forest_2000 avg_forest_2000 pc01_cook_fuel_fw ln_forest_change avg_light_2000 ln_light_2000

/* list of variables to be measured in decimals */
global dec_list $baseline_vars

/*********************/
/* RD BASELINE TESTS */
/*********************/
use $tmp/trees_rd_working, clear

/* get forest change 2000->2005 */
bys svgroup: egen ln_forest_2005 = max((year == 2005) * ln_forest)
gen ln_forest_change = ln_forest_2005 - ln_forest_2000

do label_vars.do

/* balance table preamble */
cap file close fh
file open fh using "$out/table_rd_balance.tex", write replace

/* write table header to file */
file write fh "$balance_start" _n

/* report summary statistics on all variables used on either side */
foreach v in $baseline_vars {

  /* set format type */
  if regexm("$dec_list", " `v' ") {
    local format "%6.2f"
  }
  else {
    local format "%6.0f"
  }
  
  /* store mean and N */
  /* note: not used */
  sum `v'
  local mean = "`format' (`r(mean)')"
  
  count if !mi(`v') & year == 2000
  local N `r(N)'

  /* run core RD spec on this baseline value [skip running variable pc population] */
  reghdfe `v' t left right  if rd_band_2_ & year == 2000, absorb(dist_high_fe)
  local rd_beta = _b["t"]
  local rd_se = _se["t"]
  local t = _b["t"] / _se["t"]
  
  qui test t = 0
  local p = `r(p)'
  
  local stars ""
  if `p' < 0.1 local stars2 "*"
  if `p' < 0.05 local stars2 "**"
  if `p' < 0.01 local stars2 "***"

  /* get variable label */
  local varlabel: var label `v'

  /* write varname, sample mean, RD estimate */
  file write fh "`varlabel' & " %5.3f (`rd_beta') " \\ " _n

  /* write RD standard error in parentheses */
  file write fh " & (" %5.3f (`rd_se') ") \\" _n
  
  di %55s "\\,`varlabel': " `mean' `N' `format' (`rd_beta') `format' (`rd_se') %5.2f (`t')
}

/* write sample size */
count if year == 2000
file write fh "\hline" _n
file write fh "Number of Observations & `r(N)' \\" _n

/* write table footer to file */
file write fh "$balance_end" _n

/* close file handle */
file close fh

/****************/
/* mccrary test */
/****************/
use $tmp/trees_rd_working, clear

reghdfe ln_forest t left right ln_forest_2000 if rd_band_2_ & inrange(year, 2010, 2013), absorb(dist_high_fe) cluster(svgroup)
keep if e(sample)

keep if year == 2013

/* need to run this to make sure it calls the right dc_density */
do dc_density.do

/* pooled 500 1000 */
set scheme pn
dc_density pop_rd if (inrange(pc01_pca_tot_p, 400, 599) | inrange(pc01_pca_tot_p, 900, 1099)), breakpoint(0) b(1) generate(Xj Yj r0 fhat se_fhat) xtitle("Normalized Population") ytitle("Density")
drop Xj Yj r0 fhat se_fhat
graphout deforest_mccrary, pdf

