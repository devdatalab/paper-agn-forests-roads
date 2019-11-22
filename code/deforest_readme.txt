These code and data files replicate the results in "The Ecological
Impact of Transportation Infrastructure," by Sam Asher, Teevrat Garg,
and Paul Novosad.

If you are seeking village-level data on India, including forest
cover, we would recommend downloading data from the India
Socioeconomic High-Resolution Rural-Urban Geographic panel (SHRUG), currently
available at http://www.dartmouth.edu/~novosad/data.html. These data
include annual forest cover estimates for all Indian villages from
2000--2014. Users of the forest cover data in the SHRUG should
nevertheless cite this paper as that is the source of the forest cover
data.

The present data package serves primarily to replicate the main
results of the paper, "The Ecological Impact of Transportation
Infrastructure." 

To regenerate the tables and figures from the paper, take the
following steps:

1. Unzip the code and data files from agn-roads-forests-code.zip and
   agn-roads-forests-data.zip into the same folder.

2. Open the do file make_deforest_ej.do, and set the globals "out" and
   "tmp".  "out" is the target folder for all outputs. "tmp" is the
   folder for both input data files and temporary data files that will be
   created during the rebuild.

3. Run the do file make_deforest_ej.do.  This will run through all the
   other do files to regenerate all of the results.

We have included all the required programs to generate the main
results. However, some of the estimation output commands (like estout)
may fail if certain Stata packages are missing. These can be replaced
by the estimation output commands preferred by the user.

This code requires at least the following stata packages to be installed
with ssc install.
- reghdfe
- estout
- ftools
- coefplot

The data files can be found at [this
link](https://www.dropbox.com/s/7yovx9usx2xoiry/agn-roads-forests-data.zip?dl=0).
The replication files can be found at
<https://github.com/devdatalab/paper-agn-forests-roads>.

