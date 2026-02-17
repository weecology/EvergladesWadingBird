# Indicators

These indicators are used to judge the progress of the Comprehensive Everglades Restoration Plan 
(CERP) (as well as non-CERP restoration projects) toward achieving restoration goals. 
Indicators are based on the maximum estimated counts of nesting pairs. 
These counts are coordinated across groups working in Loxahatchee NWR (aka WCA 1), 
Water Conservation Areas 2 and 3, and Everglades National Park. 
They have been compiled from many sources, including monitoring efforts conducted by Everglades 
National Park and Peter Frederick's work compiling historical and recent wading bird data.

### Max Counts
These are the yearly reported maximum observed number of nesting pairs.  
[Max_count_all](../Indicators/max_count_all.csv) records the reported numbers of nesting pairs 
for each species across all regions (currently equivalent to sums of counts in the 
[Counts/maxcounts](../Counts/maxcounts.csv) table), which are used to calculate the other 
indicators. 

* year
* region - all only, which is the sum of Loxahatchee NWR, Water Conservation areas 2 and 3, 
and Everglades National Park
* species - see [species table](../SiteandMethods/species_list.csv), also 2 non-species: 
    `cerp` is the total of the CERP target species only (GREG, SNEG, WHIB, WOST) 
    `total` is the official yearly total of all species.
* count - Max estimate of total nesting pairs across all surveyed regions

[Indicators/Max_count](../Indicators/max_count.csv) is a similar table but separated 
into different regions. This table ends in 2020, as the current numbers can be retrieved 
directly from [Counts/maxcounts](../Counts/maxcounts.csv).

* year
* region - Loxahatchee NWR, Water Conservation areas 2 and 3, WCAs (loxahatchee + wca2-3), 
and Everglades National Park
* species - see [species table](../SiteandMethods/species_list.csv)
* count - Max estimate of nesting pairs

The max counts are used to calculate 4 other indicators of restoration progress. 
Reported values for 3 indicators are provided here.

### Coastal Nesting
Proportion of all species nesting in coastal Everglades National Park colonies, 
as opposed to the inland Everglades. The data for this calculation only include numbers 
reported in the South Florida Wading Bird report. Florida Bay is not included.

### Stork Initiation Date
This is the earliest nesting initiation date for the everglades region, which includes 
mainland Everglades National Park and the Water Conservation Areas. Historical records 
(1953-1973) from Kushlan et al 1975. Recent records (1997-2024) from UF or ENP survey 
efforts and double checked using either field notes or South Florida Wading Bird Report. 
Region where earliest nesting occurred was added by M. Ernest in March 2025 using field notes 
and the South Florida Wading Bird Report. Corrections to 1953-1973 data were made by M. Ernest 
in March 2025 upon review of Kushlan et al 1975. 

Earliest nesting date for Wood Storks each year, across all colonies. 
Before 2010, only a month and score were recorded. 
Score indicates how early/late in the month nesting began:

|month|score for middle of the month|
|---------------|:-------------------------------:|
|Nov  |	5                           |
|Dec  |	4                           |
|Jan  |	3                           |
|Feb  |	2                           |
|Mar  |	1                           |
|examples:                          | 	
|Early February|	2.5               |
|Early January |	3.5               |
|Early December|	4.5               |
|Mid December  |	4                 |  

### Supercolony
Supercolony interval is the number of years since the previous supercolony year, 
recorded for WHIB and WOST. The threshold required to reach a supercolony 
(an exceptional nesting event) is 16977 for WHIB and 1458 for WOST.

### Foraging Ratio
The ratio of tactile/sight foraging species, is an indicator of the perceived 
resource availability for the target species. This is calculated as (whib + wost)/greg, 
and is calculated directly from the data in [max_count_all](../Indicators/max_count_all.csv). 
Thus a table is not provided here.

Please see the [methods](https://everglades-wading-bird-data.netlify.app/) for details 
about collection and how to use the data.
