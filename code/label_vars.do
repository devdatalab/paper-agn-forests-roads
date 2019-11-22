qui {

cap label var t    "Above Population Threshold"
cap label var got_road  "New Road"
cap label var left  "Population (Below Threshold)"
cap label var right "Population (Above Threshold)"
cap label var treatment_comp "Completion Period"
cap label var award_only "Award Period"

forval i = 1/9 {
  cap label var t`i'_plus_comp ">= `i'"
  cap label var t`i'_comp "`i'"
  cap label var tm`i'_minus_comp "<= -`i'"
  cap label var tm`i'_comp "-`i'"

  cap label var t`i'_plus_award ">= `i'"
  cap label var t`i'_award "`i'"
  cap label var tm`i'_minus_award "<= -`i'"
  cap label var tm`i'_award "-`i'"
}
cap label var t0_comp "0"
cap label var omitted_tm1 "-1"

foreach i in 0 50 100 150 {
  cap label var c_gq_`i' 2000
  cap label var c_ns_`i' 2000
  forval y = 2000/2014 {
    cap label var dist_ns_cut_`y'_`i' "`y'"
    cap label var dist_cut_`y'_`i' "`y'"
  }
}

foreach c in 0 100 {
  local cp1 = `c' + 100
  foreach year in 1991 2001 2011 {
    cap label var d_gq_`c'_`year' "(`c'-`cp1'km from GQ) * 1(Year == `year')"
    cap label var d_ns_`c'_`year' "(`c'-`cp1'km from NSEW) * 1(Year == `year')"
  }
  cap label var d_gq_`c'_1990 "(`c'-`cp1'km from GQ) * 1(Year == 1990)"
  cap label var d_ns_`c'_1990 "(`c'-`cp1'km from NSEW) * 1(Year == 1990)"
  cap label var d_gq_`c'_1998 "(`c'-`cp1'km from GQ) * 1(Year == 1998)"
  cap label var d_ns_`c'_1998 "(`c'-`cp1'km from NSEW) * 1(Year == 1998)"
  cap label var d_gq_`c'_2005 "(`c'-`cp1'km from GQ) * 1(Year == 2005)"
  cap label var d_ns_`c'_2005 "(`c'-`cp1'km from NSEW) * 1(Year == 2005)"
  cap label var d_gq_`c'_2013 "(`c'-`cp1'km from GQ) * 1(Year == 2013)"
  cap label var d_ns_`c'_2013 "(`c'-`cp1'km from NSEW) * 1(Year == 2013)"
}

cap label var  ln_forest_2000 "Log Forest (2000)"
cap label var  avg_forest_2000 "Average Forest (2000)"
cap label var  ln_gforest_2000 "Log Forest (GFC, 2000)"
cap label var  avg_gforest_2000 "Average Forest (GFC, 2000)"
cap label var  ln_forest_change "Log Forest Change (2000-2005)"
cap label var  pc01_cook_fuel_fw "Share Cooking with Firewood"

cap label var base_emp_wood_use "Baseline Log Employment"
cap label var base_emp_harvest  "Baseline Log Employment"
cap label var base_emp_logging  "Baseline Log Employment"
cap label var base_emp_any_wood_use "Baseline Any Employment"
cap label var base_emp_any_harvest  "Baseline Any Employment"
cap label var base_emp_any_logging  "Baseline Any Employment"

cap label var base_ln_ag_land "Baseline Log Ag Land"
cap label var base_ag_land "Baseline Ag Land"
cap label var base_ag_land_share "Baseline Ag Land Share"
cap label var base_cook_fuel_fw "Baseline Firewood Use"
cap label var base_cook_fuel_import "Baseline Import Fuel Use"
cap label var base_cook_fuel_nonwood "Baseline Nonwood Fuel Use"

cap label var ln_light_2000 "Log Night Light (2000)"
cap label var avg_light_2000 "Mean Night Light (2000)"

cap label var start_year "Average of start year for nearest GQ part to each village in subdistrict"
cap label var end_year   "Average of end year for nearest GQ part to each village in subdistrict"
}
