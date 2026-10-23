# Nesting Data

Please see the [methods](https://everglades-wading-bird-data.netlify.app/) for details about 
collection and how to use the data.

### Nest Checks
Nest checks done from aerial drone surveys. These data are analogous to the main ground-based nest 
check data, though usually not as complete.

year

colony

nest - nest id

species

date

eggs - number of eggs

chicks - number of chicks

stage - nesting stage

notes

### Nest Success

We cannot use the Mayfield method to calculate nest success from aerial surveys alone. Many of the 
Mayfield assumptions are not met (eg unbiased detection probability).
However, analogous nest-level metrics are stored in this table and can be used as a roxy for nest 
success (eg nest duration).

### Nest Success Summary

This is colony-level nest success as best as we can possibly estimate from drone-based nest checks, 
using the data from the [nest_success table](../Nesting/nest_success.csv). 
Success is summarized for the incubation stage, nestling stage, and overall for the whole nesting period.

k - total number of nests

sumy - total number of nests that hatched (s(i))

e - total number of days monitored (n(i))

p - 1-((k-sumy)/e), success

j - incubation or nestling period, in days (constant by species, can be found in the [species table](../SiteandMethods/species.csv))

pj - p\^j, hatch success

varp - (p\*(1-p))/e, variation of p

varpj - varp\*((j\*(p\^(j-1)))\^2), variation of pj

sdp - standard deviation of p

sdpj - standard deviation of pj
