/* public programs used in "The Ecological Impact of Transportation Infrastructure" */

/**************************************************************************************************/
/* program rd : produce a nice RD graph, using polynomial (quartic default) for fits         */
/**************************************************************************************************/
global rd_start -250
global rd_end 250
cap prog drop rd
prog def rd
{
  syntax varlist(min=2 max=2) [aweight pweight] [if], [degree(real 4) name(string) Bins(real 100) Start(real -9999) End(real -9999) MSize(string) YLabel(string) NODRAW bw xtitle(passthru) title(passthru) ytitle(passthru) xlabel(passthru) xline(passthru) absorb(string) control(string) xq(varname) cluster(passthru) nofit]

  tokenize `varlist'
  local xvar `2'

  preserve

  // Create convenient weight local
  if ("`weight'"!="") local wt [`weight'`exp']

  /* set start/end to global defaults (from include) if unspecified */
  if `start' == -9999 & `end' == -9999 {
    local start $rd_start
    local end   $rd_end
  }

  if "`msize'" == "" {
    local msize small
  }

  if "`ylabel'" == "" {
    local ylabel ""
  }
  else {
    local ylabel "ylabel(`ylabel') "
  }

  if "`name'" == "" {
    local name `1'_rd
  }

  /* set colors */
  if mi("`bw'") {
    local color_b "red"
    local color_se "blue"
  }
  else {
    local color_b "black"
    local color_se "gs8"
  }

  if "`se'" == "nose" {
    local color_se "white"
  }

  capdrop pos_rank neg_rank xvar_index xvar_group_mean rd_bin_mean rd_tag mm2 mm3 mm4 l_hat r_hat l_se l_up l_down r_se r_up r_down total_weight rd_resid
  qui {
    /* restrict sample to specified range */
    if !mi("`if'") {
      keep `if'
    }
    keep if inrange(`xvar', `start', `end')

    /* get residuals of yvar on absorbed variables */
    if !mi("`absorb'")  | !mi("`control'") {
      if !mi("`absorb'") {
        areg `1' `wt' `control' `if', absorb(`absorb')
      }
      else {
        reg `1' `wt' `control' `if'
      }
      predict rd_resid, resid
      local 1 rd_resid
    }

    /* GOAL: cut into `bins' equally sized groups, with no groups crossing zero, to create the data points in the graph */
    if mi("`xq'") {

      /* count the number of observations with margin and dependent var, to know how to cut into 100 */
      count if !mi(`xvar') & !mi(`1')
      local group_size = floor(`r(N)' / `bins')

      /* create ranked list of margins on + and - side of zero */
      egen pos_rank = rank(`xvar') if `xvar' > 0 & !mi(`xvar'), unique
      egen neg_rank = rank(-`xvar') if `xvar' < 0 & !mi(`xvar'), unique

      /* hack: multiply bins by two so this works */
      local bins = `bins' * 2

      /* index `bins' margin groups of size `group_size' */
      /* note this conservatively creates too many groups since 0 may not lie in the middle of the distribution */
      gen xvar_index = .
      forval i = 0/`bins' {
        local cut_start = `i' * `group_size'
        local cut_end = (`i' + 1) * `group_size'

        replace xvar_index = (`i' + 1) if inrange(pos_rank, `cut_start', `cut_end')
        replace xvar_index = -(`i' + 1) if inrange(neg_rank, `cut_start', `cut_end')
      }
    }
    /* on the other hand, if xq was specified, just use xq for bins */
    else {
      gen xvar_index = `xq'
    }

    /* generate mean value in each margin group */
    bys xvar_index: egen xvar_group_mean = mean(`xvar') if !mi(xvar_index)

    /* generate value of depvar in each X variable group */
    if mi("`weight'") {
      bys xvar_index: egen rd_bin_mean = mean(`1')
    }
    else {
      bys xvar_index: egen total_weight = total(wt)
      bys xvar_index: egen rd_bin_mean = total(wt * `1')
      replace rd_bin_mean = rd_bin_mean / total_weight
    }

    /* generate a tag to plot one observation per bin */
    egen rd_tag = tag(xvar_index)

    /* run polynomial regression for each side of plot */
    gen mm2 = `xvar' ^ 2
    gen mm3 = `xvar' ^ 3
    gen mm4 = `xvar' ^ 4

    /* set covariates according to degree specified */
    if "`degree'" == "4" {
      local mpoly mm2 mm3 mm4
    }
    if "`degree'" == "3" {
      local mpoly mm2 mm3
    }
    if "`degree'" == "2" {
      local mpoly mm2
    }
    if "`degree'" == "1" {
      local mpoly
    }

    reg `1' `xvar' `mpoly' `wt' if `xvar' < 0, `cluster'
    predict l_hat
    predict l_se, stdp
    gen l_up = l_hat + 1.65 * l_se
    gen l_down = l_hat - 1.65 * l_se

    reg `1' `xvar' `mpoly' `wt' if `xvar' > 0, `cluster'
    predict r_hat
    predict r_se, stdp
    gen r_up = r_hat + 1.65 * r_se
    gen r_down = r_hat - 1.65 * r_se
  }

  if "`fit'" == "nofit" {
    local color_b white
    local color_se white
  }

  /* fit polynomial to the full data, but draw the points at the mean of each bin */
  sort `xvar'
  twoway ///
    (line r_hat  `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_b') msize(vtiny)) ///
    (line l_hat  `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_b') msize(vtiny)) ///
    (line l_up   `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_se') msize(vtiny)) ///
    (line l_down `xvar' if inrange(`xvar', `start', 0) & !mi(`1'), color(`color_se') msize(vtiny)) ///
    (line r_up   `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_se') msize(vtiny)) ///
    (line r_down `xvar' if inrange(`xvar', 0, `end') & !mi(`1'), color(`color_se') msize(vtiny)) ///
    (scatter rd_bin_mean xvar_group_mean if rd_tag == 1 & inrange(`xvar', `start', `end'), xline(0, lcolor(black)) msize(`msize') color(black)),  `ylabel'  name(`name', replace) legend(off) `title' `xline' `xlabel' `ytitle' `xtitle' `nodraw' graphregion(color(white))
  restore
}
end
/* *********** END program rd ***************************************** */


/**********************************************************************************************/
/* program quireg : display a name, beta coefficient and p value from a regression in one line */
/***********************************************************************************************/
cap prog drop quireg
prog def quireg, rclass
{
  syntax varlist(fv ts) [pweight aweight] [if], [cluster(varlist) title(string) vce(passthru) noconstant s(real 40) absorb(varlist) disponly]
  tokenize `varlist'
  local depvar = "`1'"
  local xvar = subinstr("`2'", ",", "", .)

  if "`cluster'" != "" {
    local cluster_string = "cluster(`cluster')"
  }

  if mi("`disponly'") {
    if mi("`absorb'") {
      cap qui reg `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' `constant'
      if _rc == 1 {
        di "User pressed break."
      }
      else if _rc {
        display "`title': Reg failed"
        exit
      }
    }
    else {
      cap qui areg `varlist' [`weight' `exp'] `if',  `cluster_string' `vce' absorb(`absorb') `constant'
      if _rc == 1 {
        di "User pressed break."
      }
      else if _rc {
        display "`title': Reg failed"
        exit
      }
    }
  }
  local n = `e(N)'
  local b = _b[`xvar']
  local se = _se[`xvar']

  quietly test `xvar' = 0
  local star = ""
  if r(p) < 0.10 {
    local star = "*"
  }
  if r(p) < 0.05 {
    local star = "**"
  }
  if r(p) < 0.01 {
    local star = "***"
  }
  di %`s's "`title' `xvar': " %10.5f `b' " (" %10.5f `se' ")  (p=" %5.2f r(p) ") (n=" %6.0f `n' ")`star'"
  return local b = `b'
  return local se = `se'
  return local n = `n'
  return local p = r(p)
}
end
/* *********** END program quireg**********************************************************************************************/


/*********************************************************************************/
/* program winsorize: replace variables outside of a range(min,max) with min,max */
/*********************************************************************************/
cap prog drop winsorize
prog def winsorize
{
  syntax anything,  [REPLace GENerate(name) centile]

  tokenize "`anything'"

  /* require generate or replace [sum of existence must equal 1] */
  if (!mi("`generate'") + !mi("`replace'") != 1) {
    display as error "winsorize: generate or replace must be specified, not both"
    exit 1
  }

  if ("`1'" == "" | "`2'" == "" | "`3'" == "" | "`4'" != "") {
    di "syntax: winsorize varname [minvalue] [maxvalue], [replace generate] [centile]"
    exit
  }
  if !mi("`replace'") {
    local generate = "`1'"
  }
  tempvar x
  gen `x' = `1'


  /* reset bounds to centiles if requested */
  if !mi("`centile'") {

    centile `x', c(`2')
    local 2 `r(c_1)'

    centile `x', c(`3')
    local 3 `r(c_1)'
  }

  di "replace `generate' = `2' if `1' < `2'  "
  replace `x' = `2' if `x' < `2'
  di "replace `generate' = `3' if `1' > `3' & !mi(`1')"
  replace `x' = `3' if `x' > `3' & !mi(`x')

  if !mi("`replace'") {
    replace `1' = `x'
  }
  else {
    generate `generate' = `x'
  }
}
end
/* *********** END program winsorize ***************************************** */


/**********************************************************************************/
/* program get_var_labels : Labels all variables from a source file               */
/***********************************************************************************/
cap prog drop get_var_labels
prog def get_var_labels
{
  do label_vars
}
end
/* *********** END program get_var_labels ***************************************** */


/**********************************************************************************/
/* program disp_nice : Insert a nice title in stata window */
/***********************************************************************************/
cap prog drop disp_nice
prog def disp_nice
{
  di _n "+--------------------------------------------------------------------------------------" _n `"| `1'"' _n  "+--------------------------------------------------------------------------------------"
}
end
/* *********** END program disp_nice ***************************************** */


/**********************************************************************************/
/* program drop_prefix : Insert description here */
/***********************************************************************************/
cap prog drop drop_prefix
prog def drop_prefix
{
  syntax, [EXCept(varlist)]
  local x ""

  foreach i of varlist _all {
    local x `x' `i'
    continue, break
  }

  local prefix = substr("`x'", 1, strpos("`x'", "_"))

  /* do it var by var instead of using renpfix so can pass exception parameters */
  local line = `"renpfix `prefix' """'
  di `"`line'"'
  `line'

  /* rename exception list */
  if "`except'" != "" {
    foreach var in `except' {
      local newvar = substr("`var'", strpos("`var'", "_") + 1 ,.)
      ren `newvar' `prefix'`newvar'
    }
  }

}
end
/* *********** END program drop_prefix ***************************************** */


/**********************************************************************************/
/* program lf : Better version of lf */
/***********************************************************************************/
cap prog drop lf
prog def lf
{
  syntax anything
  d *`1'*, f
}
end
/* *********** END program lf ***************************************** */


/**********************************************************************************/
/* program make_binary: make a numeric binary variable out of string data */
/***********************************************************************************/
cap prog drop make_binary
prog def make_binary
{
  syntax varlist, one(string) zero(string) [label(string)]

  /* cycle over varlist, replacing strings with 1s and 0s */
  foreach var in `varlist' {
    replace `var' = trim(lower(`var'))
    assert inlist(`var', "`one'", "`zero'", "")
    replace `var' = "1" if `var' == "`one'"
    replace `var' = "0" if `var' == "`zero'"
  }

  /* destring variables */
  destring `varlist', replace

  /* create value label */
  if !mi("`label'") {
    label define `label' 1 "`one'" 0 "`zero'", modify
    label values `varlist' `label'
  }

}
end
/* *********** END program make_binary ***************************************** */


/**********************************************************************************************/
/* program binscatter_rd : Produce binscatter graphs that absorb variables on the Y axis only */
/**********************************************************************************************/
cap prog drop binscatter_rd
prog def binscatter_rd
{
  syntax varlist [aweight pweight] [if], [RD(passthru) NQuantiles(passthru) XQ(passthru) SAVEGRAPH(passthru) REPLACE LINETYPE(passthru) ABSORB(string) XLINE(passthru) XTITLE(passthru) YTITLE(passthru) BY(passthru)]
  cap drop yhat
  cap drop resid

  tokenize `varlist'

  // Create convenient weight local
  if ("`weight'"!="") local wt [`weight'`exp']

  reg `1' `absorb' `wt' `if'
  predict yhat
  gen resid = `1' - yhat

  local cmd "binscatter resid `2' `wt' `if', `rd' `xq' `savegraph' `replace' `linetype' `nquantiles' `xline' `xtitle' `ytitle' `by'"
  di `"RUNNING: `cmd'"'
  `cmd'
}
end
/* *********** END program binscatter_rd ***************************************** */


/**********************************************************************************/
/* program tag : Fast way to run egen tag(), using first letter of var for tag    */
/**********************************************************************************/
cap prog drop tag
prog def tag
{
  syntax anything [if]

  tokenize "`anything'"

  local x = ""
  while !mi("`1'") {

    if regexm("`1'", "pc[0-9][0-9][ru]?_") {
      local x = "`x'" + substr("`1'", strpos("`1'", "_") + 1, 1)
    }
    else {
      local x = "`x'" + substr("`1'", 1, 1)
    }
    mac shift
  }

  display `"RUNNING: egen `x'tag = tag(`anything') `if'"'
  egen `x'tag = tag(`anything') `if'
}
end
/* *********** END program tag ***************************************** */

/**********************************************************************************/
/* program group : Fast way to use egen group()                  */
/**********************************************************************************/
cap prog drop regroup
prog def regroup
  syntax anything [if]
  group `anything' `if', drop
end

cap prog drop group
prog def group
{
  syntax anything [if], [drop]

  tokenize "`anything'"

  local x = ""
  while !mi("`1'") {

    if regexm("`1'", "pc[0-9][0-9][ru]?_") {
      local x = "`x'" + substr("`1'", strpos("`1'", "_") + 1, 1)
    }
    else {
      local x = "`x'" + substr("`1'", 1, 1)
    }
    mac shift
  }

  if ~mi("`drop'") cap drop `x'group

  display `"RUNNING: egen int `x'group = group(`anything')" `if''
  egen int `x'group = group(`anything') `if'
}
end
/* *********** END program group ***************************************** */




/********************************************************************/
/* program appendmodels : append stored estimates for making tables */
/********************************************************************/

/* version 1.0.0  14aug2007  Ben Jann*/

cap prog drop appendmodels
prog def appendmodels, eclass
{
  // using first equation of model version 8
  syntax namelist
  tempname b V tmp
  foreach name of local namelist {
    qui est restore `name'
    mat `tmp' = e(b)
    local eq1: coleq `tmp'
    gettoken eq1 : eq1
    mat `tmp' = `tmp'[1,"`eq1':"]
    local cons = colnumb(`tmp',"_cons")
    if `cons'<. & `cons'>1 {
      mat `tmp' = `tmp'[1,1..`cons'-1]
    }
    mat `b' = nullmat(`b') , `tmp'
    mat `tmp' = e(V)
    mat `tmp' = `tmp'["`eq1':","`eq1':"]
    if `cons'<. & `cons'>1 {
      mat `tmp' = `tmp'[1..`cons'-1,1..`cons'-1]
    }
    capt confirm matrix `V'
    if _rc {
      mat `V' = `tmp'
    }
    else {
      mat `V' = ( `V' , J(rowsof(`V'),colsof(`tmp'),0) ) \ ( J(rowsof(`tmp'),colsof(`V'),0) , `tmp' )
    }
  }

  local names: colfullnames `b'
  mat coln `V' = `names'
  mat rown `V' = `names'
  eret post `b' `V'
  eret local cmd "whatever"
}
end

/* *********** END program appendmodels *****************************************/


/**********************************************************************************/
/* program append_to_file : Append a passed in string to a file                   */
/**********************************************************************************/
cap prog drop append_to_file
prog def append_to_file
{
  syntax using/, String(string) [format(string) erase]

  cap file close fh

  if !mi("`erase'") cap erase `using'

  file open fh using `using', write append
  file write fh  `"`string'"'  _n
  file close fh
}
end
/* *********** END program append_to_file ***************************************** */


/**********************************************************************************/
/* program append_est_to_file : Appends a regression estimate to a csv file       */
/**********************************************************************************/
cap prog drop append_est_to_file
prog def append_est_to_file
{
  syntax using/, b(string) Suffix(string)

  /* get number of observations */
  qui count if e(sample)
  local n = r(N)

  /* get b and se from estimate */
  local beta = _b["`b'"]
  local se   = _se["`b'"]

  /* get p value */
  qui test `b' = 0
  local p = `r(p)'
  if "`p'" == "." {
    local p = 1
    local beta = 0
    local se = 0
  }
  append_to_file using `using', s("`beta',`se',`p',`n',`suffix'")
}
end
/* *********** END program append_est_to_file ***************************************** */


/*****************************************************************/
/* program collapse_save_labels: Save var labels before collapse */
/*****************************************************************/

/* save var labels before collapse, saving varname if no label */
cap prog drop collapse_save_labels
prog def collapse_save_labels
{
  foreach v of var * {
    local l`v' : variable label `v'
    global l`v'__ `"`l`v''"'
    if `"`l`v''"' == "" {
      global l`v'__ "`v'"
    }
  }
}
end
/* **** END program collapse_save_labels *********************** */


/************************************************************************/
/* program collapse_apply_labels: Apply saved var labels after collapse */
/************************************************************************/

/* apply retained variable labels after collapse */
cap prog drop collapse_apply_labels
prog def collapse_apply_labels
{
  foreach v of var * {
    label var `v' "${l`v'__}"
    macro drop l`v'__
  }
}
end
/* **** END program collapse_apply_labels ***************************** */


/**********************************************************************************/
/* program gen_rd_bins : regression discontinuity with binned data                */
/**********************************************************************************/
cap prog drop gen_rd_bins
prog def gen_rd_bins
{
  /* N is number of bins, gen is the new variable name, cut breaks
  bins into two sections (e.g. positive and negative). e.g. cut(0)
  will proportionally split desired bins into positive and negative,
  with 0 inclusive in positive bins. */
  syntax varlist(min=1 max=1), gen(string) [n(real 20) Cut(integer -999999999999) if(string)]

  cap drop rd_tmp_id
  
  /* if there is an `if' statement, we need a preserve/restore, and to
  execute the condition. */
  if !mi(`"`if'"') {
    gen rd_tmp_id = _n
    preserve
    foreach cond in `if' {
      `cond'
    }
  }

  /* get our xvar into a more legible macro */
  local xvar `varlist'

  /* create empty index var */
  cap drop `gen'
  gen `gen' = .

  /* calculate the proportionate number of bins above/below `cut',
  which defaults to -99999999999 - a value which just about guarantees
  all obs will be in the `above' split - so will divide into bins
  normally. */

  /* count below cut */
  count if !mi(`xvar')  & `xvar' < `cut'
  local below_count = `r(N)'

  /* count above cut, inclusive */
  count if !mi(`xvar') & `xvar' >= `cut'
  local above_count = `r(N)'

  /* number of below-cut groups, then above */
  local below_num_bins = floor((`below_count'/_N) * `n')
  local above_num_bins = `n' - `below_num_bins'

  /* number of obs in each group */
  local below_num_obs = floor(`below_count'/`below_num_bins')
  local above_num_obs = floor(`above_count'/`above_num_bins')

  /* rank our obs above and below cut */
  cap drop below_rank above_rank
  egen below_rank = rank(-`xvar') if `xvar' < `cut' & !mi(`xvar'), unique
  egen above_rank = rank(`xvar') if `xvar' >= `cut' & !mi(`xvar'), unique

  /* split into groups above/below cut */
  foreach side in above below {

    /* set a multiplier - negative bins will be < `cut', positive
    will be above */
    if "`side'" == "below" {
      local multiplier = -1
    }
    else if "`side'" == "above" {
      local multiplier = 1
    }

    /* loop over the number of bins either above or below, to
    reclassify our index */
    forval i = 1/``side'_num_bins' {

      /* get start and end of this specific bin (obs count) */
      local cut_start = (`i' - 1) * ``side'_num_obs'
      local cut_end = `i' * ``side'_num_obs'

      /* replace our bin categorical with the right group */
      replace `gen' = `multiplier' * (`i') if inrange(`side'_rank, `cut_start', `cut_end')
    }
  }

  /* now the restore and merge, if we have a subset condition */
  if !mi(`"`if'"') {

    /* save our new data */
    save $tmp/rd_bins_tmp, replace

    /* get our original data back, and merge in new index */
    restore
    merge 1:1 rd_tmp_id using $tmp/rd_bins_tmp, keepusing(`gen') nogen
    drop rd_tmp_id

    /* remove our temporary file */
    rm $tmp/rd_bins_tmp.dta
  }
}
end
/* *********** END program gen_rd_bins ***************************************** */

/**********************************************************************************/
/* program capdrop : Drop a bunch of variables without errors if they don't exist */
/**********************************************************************************/
cap prog drop capdrop
prog def capdrop
{
  syntax anything
  foreach v in `anything' {
    cap drop `v'
  }
}
end
/* *********** END program capdrop ***************************************** */

/**********************************************************************************/
/* program add_to_global : Shortcut variable [or anything] to a global declaration*/
/* add_to_global FOO v1 v2
       is equivalent to:
   global FOO $FOO v1 v2                                                          */
/***********************************************************************************/
cap prog drop add_to_global
prog def add_to_global
{
  syntax anything
  tokenize `anything'
  global `1' ${`1'} `2' `3' `4' `5' `6' `7' `8' `9' `10' `11' `12'
  if !mi("`13'") {
    di "add_to_global only works with 12 vars. Sorry! Modify it to take any number in include.do."
    error 123
  }
}
end
/* *********** END program add_to_global ***************************************** */

/************************************************************/
/* program mccrary - clean wrapper for dc_density function  */
/************************************************************/
cap prog drop mccrary
prog def mccrary
{
  syntax varlist [if], BReakpoint(real) [b(real 0) h(real 0) name(passthru) graphregion(passthru) qui graph xtitle(passthru) ytitle(passthru) xlabel(passthru) ylabel(passthru)]
  if "`graph'" == "graph" {
    local nograph = ""
  }
  else {
    local nograph = "nograph"
  }
  `qui' {
    dc_density `varlist' `if', breakpoint(`breakpoint') h(`h') b(`b') generate(Xj Yj r0 fhat se_fhat) `nograph' `name' `graphregion' `xtitle' `ytitle' `xlabel' `ylabel'
    drop Xj Yj r0 fhat se_fhat
  }
}
end
/* *********** END program mccrary ************************* */

/* placeholders for estimation commands that should be supplied by users */
cap prog drop graphout
prog def graphout
  syntax anything, [pdf large]
  graph export $out/`anything'.eps, replace
end

cap prog drop gt
prog def gt
  syntax anything, [pdf large]
  graph export $out/`anything'.eps, replace
end

cap prog drop estmod_header
prog def estmod_header
qui di "..."
end

cap prog drop estout_default
prog def estout_default
qui di "..."
end

cap prog drop store_est_tpl
prog def store_est_tpl
qui di "..."
end

cap prog drop store_val_tpl
prog def store_val_tpl
qui di "..."
end

cap prog drop table_from_tpl
prog def table_from_tpl
qui di "..."
end

cap prog drop count_stars
prog def count_stars
qui di "..."
end

cap prog drop insert_into_file
prog def insert_into_file
qui di "..."
end

