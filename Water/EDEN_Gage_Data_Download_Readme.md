## Readme File for EDEN Gage Data Download - http://sofia.usgs.gov/eden

The information below contains explanations for several of the fields available as part of the data download.

### Station information

Explanations of Water-Level Values:

    + Operating Agency
    + Station Name
    + Location Area
    + Data Links
    + Methods used to Compute NAVD88 vertical datum
    + Ground Elevation and Vegetation Information
    + Vegetation Community
    + Type of Station
    + Station Used in Surfacing Program


__________________


#### Operating Agency:
BCNP 	Big Cypress National Preserve
ENP 	Everglades National Park
SFWMD 	South Florida Water Mangement District
USGS 	U.S. Geological Survey

#### Station Name:
The station name used in the site is specific to the EDEN site. It generally is the same name as the agency station name, but there could be slight variations (either this is a shortened form, or a modified form). For example:

    * EDEN name: 3A9; Station name used by operating agency: 3A9+
    * EDEN name: 3AN1W1; Station name used by operating agency: 3AN1W1+

Please note: for station S150_T, there are two separate records. The USGS station has historical data (prior to 2004) for daily data and historical hourly data back to 1999. The SFWMD station only has data starting in 2004. This data download program only includes information for the SFWMD station (2004-current); information for the USGS station is available on EDEN web at http://sofia.usgs.gov/eden.

#### Location Area:
Area of Everglades where gage is located (gages along canals are reported by the canal name, gages across canals are reported by what area the headwater or tailwater gage measures)
	Choices for Marsh Stations: 	Choice for Canal Stations:
	BCNP 				Hillsboro Canal
	ENP 				Tamiami Canal
	WCA1 				L-40
	WCA2A 				etc.
	WCA2B 	 
	WCA3A 	 
	WCA3B 	 
	Pennsuco Wetlands 

#### Methods used to Compute NAVD88 vertical datum:
Note: For more information on NAVD88, see the CERP Geodetic Vertical Control Survey project.
	* Optical survey, provided by agency: Datum conversion value computed using line-of-sight optical survey methods from a known bench mark and provided by operating agency
	* Optical survey, provided by USACE: Datum conversion value computed using optical survey methods from a known bench mark and provided by USACE
	* CORPSCON 6.0 with modified CERP grid: Datum conversion value computed using VERTCON grid modified by the USACE Jacksonville District to incorporate the CERP vertical control network established in 2001-2002 (Rory Sutton, USACE)  More information about Corpscon 6.0: http://crunch.tec.army.mil/software/corpscon/corpscon.html
	* Tapedown: Tapedown from NAVD88 benchmark to water surface at station to determine water level (NAVD88). Subtracted value from measured water level (NGVD29) at station to determine conversion value.

#### Ground Elevation and Vegetation Information:
Water depths were measured at a minimum of 6 locations in the major vegetation community surrounding the water level of line drawing showing methodology for obtaining water depthsgaging station. The ground elevation at each site was calculated by subtracting the water depth from the water level reading at the gage. The ground elevations were averaged to compute the reported value.

#### Average Ground Elevation within a Vegetation Community

Water depths were measured at a minimum of 6 locations in the major vegetation community surrounding the water level gaging station. The ground elevation at each site was calculated by subtracting the water depth from the water level reading at the gage. The ground elevations were averaged to compute the reported value.

The basic protocol for collection of data at a water level (stage) gage:

    * The water level was recorded from the staff gage at the stage gage or at a nearby location. In the case of an unavailable or missing staff gage, the water depth was measured at an reference mark (R.M.) or well. GPS coordinates were collected at every staff gage.
    * The major vegetative community at the stage gage was identified.
    * Water depth was recorded at 6 random locations at least 10 meters apart and distributed around the gage in the major vegetative community. Data was collected along 6 spokes radiating out from the gage that are 10 paces long (approximately 10 meters) . The spokes were aligned in the following directions: 0?, 60?, 120?, 180?, 240?, and 300?. The measurements were performed using a surveyor's level rod with a flared rubber base. The measuring stick was allowed to rest on top of the bottom surface. Every data measurement was recorded. Measurements were not made in disturbed locations, such as in airboat trail or where a helicopter has landed. If a disturbed area was located, the data collector continued walking away from the gage and measured in an undisturbed area. GPS coordinates were collected at every measured point.
    * If the gage was on the edge or transition of a community, a judgment was made to determine the major vegetation community. The data collector walked 20 paces from the gage into the adjacent major community and used that as the center point to begin walking the "spokes".
    * Water depth was also recorded at 3 random locations at least 10 meters apart and not more than 400 meters from the gage in the next major vegetative community. If there was no next major vegetative community within 400 meters of the gage, none available was recorded. If more than one vegetative community was identified, then both are reported. These points were centered twenty paces into the community from the edge, with the 10-pace spokes oriented at 0?, 120?, and 240?. Measurements were not collected in communities that were too small to conduct the random measurements.
    * NA is recorded if the major or secondary vegetation community was dry during the site visit and no ground elevation could be computed.

#### Vegetation Community:
Vegetation community at the gage, field descriptions were categorized into 6 major communities. Choices:

    * Slough or open water
    * Wet prairie
    * Ridge or sawgrass and emergent marsh
    * Exotics and cattail
    * Upland
    * Canal (gage constructed in a canal along a levee or in the marsh but not at a canal structure)
    * Other (mostly wetland shrub and wetland forested)

#### Type of Station:
Physical Location: Canal and marsh indicate stations located in uncontrolled regions, canal structure indicates a station located within a canal at a structure, usually with an associated station on the other side of the structure, marsh structure indicates a station located in the marsh at a structure, usually with an associated station on the other side of the structure. In both cases, the associated station does not have to be of the same type (canal or marsh). Values:

    * Canal
    * Canal structure
    * Marsh
    * Marsh structure 

#### Water: There are only two options for this value:

    * Freshwater
    * Tidal

#### Station Used in Surfacing Program
Notes whether or not station is used in the creation of EDEN modeled water surfaces.=


### Water-Level Data

Water-level gages in the EDEN network are operated and maintained by multiple agencies which are responsible for the accuracy of the measured data. EDEN's ADAM software quality assures the measured data, identifies erroneous data, and estimates missing data. Data are identified as 'dry' (see note below for 'data type') based on the measurements of ground elevation in the vicinity of the gage by EDEN staff or on ground elevation data provided by the operating agencies.

The file contains the following information for each gage:

Station = EDEN station name
Date = date of data (YYYYMMDD)
Daily median water level (feet, NAVD88) = daily median of the hourly water level data at gage for date specified, in feet
Water level data type = type of data collected at the gage for specified date; "O" for observed or measured data, "M" for missing data, "E" for estimated data, and "D" for dry conditions at the gage (see detailed description below)
Water level quality flag = identifies the level of quality assurance of the data; "F" for final data, "P" for provisional data where data have received some review from the operating agency, and "R" for real-time data that have received little or no review from the operating agency.

For Data type: If a single hourly value is measured, a daily median is computed and identified as data type of measured (O). Missing data (M) means that all hourly data for that day is missing for the gage. Estimated data (E) means that all hourly values are estimated at the gage for that day. Conditions at the gage are considered dry (D) if the daily median is equal to or below the average ground elevation at the gage. If the data at a gage is determined to be dry, the data is not identified as measured, estimated, or missing.

#### WARNING
Water-level data are reviewed periodically to ensure accuracy. All data are considered provisional and subject to revision until it is approved by the operating agency and identified as final. Provisional data must be cited as provisional and subject to change. The data are released on the conditions that neither the USGS nor the United States Government may be held liable for any damages resulting from its use.


### Rainfall Data
Rainfall data is based on Next Generation Radar (NEXRAD) data from the U.S. National Weather Service which provides complete spatial coverage of rainfall amounts for the State of Florida. The accuracy of NEXRAD data is enhanced when adjusted using the local rain-gage data. The rainfall data is provided by the South Florida Water Management District and the point of contact is Qinglong (Gary) Wu (qwu@sfwmd.gov). For more information about the rainfall data, go to http://sofia.usgs.gov/eden/nexrad.php.

The file contains the following information for each gage:
Station = EDEN station name
Date = date of data (YYYYMMDD)
Rainfall (inches) = daily total rainfall (in inches) for specified date

### Evapotranspiration Data

Evapotranspiration (ET) data is based on a network of 15 data collection sites operated by the USGS throughout Florida. Go to http://fl.water.usgs.gov/et/ for information about Florida's evapotranspiration data resources.
The file contains the following information for each gage:
Station = EDEN station name
Date = date of data (YYYYMMDD)
Evapotranspiration (millimeters) = daily total evapotranspiration (in millimeters) for specified date



