/* all of the following paths must be set */
global out
global tmp

if mi("$out") | mi("$tmp") {
  display as error "Globals 'out' and 'tmp' must be set for this to run."
  error 1
}

cap log close
log using $out/agn-roads-forests.log, text replace

/* Stata programs used by code files */
do include_deforest_pub.do

/* summary statistics */
do table_summary.do

/* rural roads analysis */
do table_rural_panel.do
do table_rural_rd.do
do table_rd_balance.do

/* highway analysis */
do table_gq.do
do table_gq_mech_subd.do

/* highways -- figures */
do figure_group_plots_village.do

cap log close
