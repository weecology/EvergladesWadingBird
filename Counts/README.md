# Count Data

Please see the [methods](../SiteandMethods/methods.md) for details about collection and how to use the data.

### Flight Surveys
Raw counts observed from plane. Typically 2 counters.
* year
* date
* colony
* latitude
* longitude
* start_transect
* end_transect
* start_time
* end_time
* observer
* photo_sets
* photos - photos or slides taken, may have a corresponding count in image counts table
* species
* behavior - nesting or roosting
* count
* notes   

### Max Counts
Primary max count table, time series of all significant colonies (over 40 in any year)
* group_id - unique colony id number
* year 
* colony - official colony name
* colony_old - name used at time of observation
* latitude
* longitude
* wca
* species
* count
* notes

### Max Counts under 40
Other max counts for minor colonies (under 40 nests)
* group_id - unique colony id number
* year 
* colony - official colony name
* colony_old - name used at time of observation
* latitude
* longitude
* species
* count
* notes

### Ground Counts
Raw field counts from ground surveys

Locations are along a transect, not necessarily at a named colony. Colony is only reported 
when it is overlapped by the transect.
* year
* date
* transect
* colony_waypoint
* colony
* latitude
* longitude
* species
* count
* nests
* chicks
* notes  

### Ground Transects
Index of transect location data used in ground surveys

#### Ground Counts Table
Summary table from reports

#### Max Count 1993
Original version of max count table

#### Max Count New
Alternate format years 2020, 2021
