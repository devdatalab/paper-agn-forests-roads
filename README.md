# paper-agn-forests-roads

These code and data files replicate the results in "The Ecological
Impact of Transportation Infrastructure," by Sam Asher, Teevrat Garg,
and Paul Novosad, forthcoming (as of Nov. 2019) in *The Economic
Journal*.  A working paper version of the manuscript can be found
[here](http://www.paulnovosad.com/pdf/agn-roads-forests.pdf).

If you are seeking village-level data on India, including forest
cover, we would recommend downloading data from the
[SHRUG](devdatalab.org/shrug), which has more recent versions of all
of the data underlying this project.  The SHRUG includes annual forest
cover estimates for all Indian villages from 2000--2014. Users of the
forest cover data in the SHRUG should cite Townshend et al. (2011) as
described in the SHRUG documentation.

The present data package contains code that will replicate the main
results of the paper, "The Ecological Impact of Transportation
Infrastructure."

To regenerate the tables and figures from the paper, take the
following steps:

1. Download and unzip the replication data package from [this
   link](https://www.dropbox.com/s/z3qimv5yzbzkpmy/agn-roads-forests-data.zip?dl=0). To
   get the files in CSV format, use [this link](https://www.dropbox.com/s/ardumusrboqssy1/agn-roads-forests-csv.zip?dl=0).

2. Clone this repo and switch to the code folder.

3. Open the do file make_deforest_ej.do, and set the globals `out` and
   `tmp`.  `out` is the target folder for all outputs, such as tables
   and graphs. `tmp` is the folder for the data files and
   temporary data files that will be created during the rebuild.
   Make sure that `tmp` points to the folder where you have downloaded
   the data packet above.
   
4. Use `ssc` to install the Stata packages below.

5. Run the do file make_deforest_ej.do.  This will run through all the
   other do files to regenerate all of the results.

We have included all the required programs to generate the main
results. However, some of the estimation output commands (like estout)
may fail if certain Stata packages are missing. These can be replaced
by the estimation output commands preferred by the user.

Please note we use globals for pathnames which will cause errors if
filepaths have spaces in them. Please store code and data in paths
that can be accessed without spaces in filenames. 

This code requires at least the following stata packages to be installed
with ssc install.
- reghdfe
- estout
- ftools
- coefplot
- running
- binscatter

This code was tested using Stata 14.0. Tables 5 and A9 may be
difficult to generate from a personal computer. We generated them on a
server with max memory of 429 GB. The EJ replicators ran the analysis on a machine with 32 GB RAM, with peak memory consumption of 35 GB. Run time to generate all results on our server was about 35 minutes.

The code does not generate Figures 1 and A2, which are maps that
were constructed manually in QGIS. The source data for the maps is the
2011 village-level polygon file available from MLInfoMap.

## Data availability

The primary data sources used for this paper are Vegetation Continuous Fields (Townshend et al. 2011), the Indian Population Census, and administrative data from the PMGSY (Asher and Novosad 2020). While all sources were public, their web sites have changed repeatedly since paper publication, and it is not realistic to actively maintain links.

The data packets linked above can be used for replication. Almost all of the underlying data can be accessed via the [SHRUG dataset](http://devdatalab.org/shrug).

### References:

* Townshend, J., M. Hansen, M. Carroll, C. DiMiceli, R. Sohlberg, and C. Huang.
2011. “User Guide for the MODIS Vegetation Continuous Fields product Collection 5
version 1.”

* Asher, Sam, and Paul Novosad. "Rural roads and local economic development." American economic review 110.3 (2020): 797-823.

