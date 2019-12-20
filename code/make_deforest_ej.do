clear all

/* all of the following paths must be set */
global out ~/tmp/deforest/out
global tmp ~/tmp/deforest

if mi("$out") | mi("$tmp") {
  display as error "Globals 'out' and 'tmp' must be set for this to run."
  error 1
}

cap log close
log using $out/agn-roads-forests.log, text replace

/* Stata programs used by code files */
do include_deforest_pub.do

/* Table 1 -- summary stats */
do table_summary.do

/* RURAL ROADS ANALYSIS */

/* Figure 3, Table 3, Table 4, Figure A5, Table A6, Table A8 */
do table_rural_panel.do

/* Figure 2, Table 2, Figure A3, Table A3, Table A4, Table A5 */
do table_rural_rd.do

/* Figure A4, Table A2 */
do table_rd_balance.do

/* HIGHWAY ANALYSIS */
/* Table 5 */
do table_gq.do

/* Figure 6, Table A11, Table A12 */
do table_gq_mech_subd.do

/* Figure 5 -- highways */
// do figure_group_plots_village.do

/* figure 4 */
do graph_end_base.do

/* additional appendix plots and tables */

/* figure A1 */
do figure_road_dates.do

/* Table A1 */
do ols.do

/* table A7 */
do table_alt_specs.do

/* table A9 */
do table_gq_iv.do

/* Table A10 */
do table_gq_timing.do

cap log close
