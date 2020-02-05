# EDEN Gage Data 

Everglades Depth Estimation Network (EDEN) for Support of Biological and Ecological Assessments

Accessed via - http://sofia.usgs.gov/eden

## Station data

### Agency:

Operating agency: 

BCNP 	Big Cypress National Preserve
ENP 	Everglades National Park
SFWMD 	South Florida Water Mangement District
USGS 	U.S. Geological Survey

### Station 

Station Name:

The station name used in the site is specific to the EDEN site. It generally is the same name as the agency station name, but there could be slight variations (either this is a shortened form, or a modified form). For example:

    * EDEN name: 3A9; Station name used by operating agency: 3A9+
    * EDEN name: 3AN1W1; Station name used by operating agency: 3AN1W1+

Please note: for station S150_T, there are two separate records. The USGS station has historical data (prior to 2004) for daily data and historical hourly data back to 1999. The SFWMD station only has data starting in 2004. This data download program only includes information for the SFWMD station (2004-current); information for the USGS station is available on EDEN web at http://sofia.usgs.gov/eden.

### Area

Location Area:

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

### datum

Methods used to Compute NAVD88 vertical datum:

Note: For more information on NAVD88, see the CERP Geodetic Vertical Control Survey project.
	* Optical survey, provided by agency: Datum conversion value computed using line-of-sight optical survey methods from a known bench mark and provided by operating agency
	* Optical survey, provided by USACE: Datum conversion value computed using optical survey methods from a known bench mark and provided by USACE
	* CORPSCON 6.0 with modified CERP grid: Datum conversion value computed using VERTCON grid modified by the USACE Jacksonville District to incorporate the CERP vertical control network established in 2001-2002 (Rory Sutton, USACE)  More information about Corpscon 6.0: http://crunch.tec.army.mil/software/corpscon/corpscon.html
	* Tapedown: Tapedown from NAVD88 benchmark to water surface at station to determine water level (NAVD88). Subtracted value from measured water level (NGVD29) at station to determine conversion value.
	
### locationtype:

Physical Location: Canal and marsh indicate stations located in uncontrolled regions, canal structure indicates a station located within a canal at a structure, usually with an associated station on the other side of the structure, marsh structure indicates a station located in the marsh at a structure, usually with an associated station on the other side of the structure. In both cases, the associated station does not have to be of the same type (canal or marsh). Values:

    * Canal
    * Canal structure
    * Marsh
    * Marsh structure 
    
### watertype

Water type location: There are only two options for this value:

    * Freshwater
    * Tidal

### used_in_program

Station Used in Surfacing Program
Notes whether or not station is used in the creation of EDEN modeled water surfaces.


## Vegetation data

### Vegetation Community:

Vegetation community at the gage, field descriptions were categorized into 6 major communities. Choices:

    * Slough or open water
    * Wet prairie
    * Ridge or sawgrass and emergent marsh
    * Exotics and cattail
    * Upland
    * Canal (gage constructed in a canal along a levee or in the marsh but not at a canal structure)
    * Other (mostly wetland shrub and wetland forested)

### Ground Elevation (_ground_elev) and Vegetation Information:

Water depths were measured at a minimum of 6 locations in the major vegetation community surrounding the water level of line drawing showing methodology for obtaining water depthsgaging station. The ground elevation at each site was calculated by subtracting the water depth from the water level reading at the gage. The ground elevations were averaged to compute the reported value.

Average Ground Elevation within a Vegetation Community

Water depths were measured at a minimum of 6 locations in the major vegetation community surrounding the water level gaging station. The ground elevation at each site was calculated by subtracting the water depth from the water level reading at the gage. The ground elevations were averaged to compute the reported value.

The basic protocol for collection of data at a water level (stage) gage:

    * The water level was recorded from the staff gage at the stage gage or at a nearby location. In the case of an unavailable or missing staff gage, the water depth was measured at an reference mark (R.M.) or well. GPS coordinates were collected at every staff gage.
    * The major vegetative community at the stage gage was identified.
    * Water depth was recorded at 6 random locations at least 10 meters apart and distributed around the gage in the major vegetative community. Data was collected along 6 spokes radiating out from the gage that are 10 paces long (approximately 10 meters) . The spokes were aligned in the following directions: 0∞, 60∞, 120∞, 180∞, 240∞, and 300∞. The measurements were performed using a surveyor's level rod with a flared rubber base. The measuring stick was allowed to rest on top of the bottom surface. Every data measurement was recorded. Measurements were not made in disturbed locations, such as in airboat trail or where a helicopter has landed. If a disturbed area was located, the data collector continued walking away from the gage and measured in an undisturbed area. GPS coordinates were collected at every measured point.
    * If the gage was on the edge or transition of a community, a judgment was made to determine the major vegetation community. The data collector walked 20 paces from the gage into the adjacent major community and used that as the center point to begin walking the "spokes".
    * Water depth was also recorded at 3 random locations at least 10 meters apart and not more than 400 meters from the gage in the next major vegetative community. If there was no next major vegetative community within 400 meters of the gage, none available was recorded. If more than one vegetative community was identified, then both are reported. These points were centered twenty paces into the community from the edge, with the 10-pace spokes oriented at 0∞, 120∞, and 240∞. Measurements were not collected in communities that were too small to conduct the random measurements.
    * NA is recorded if the major or secondary vegetation community was dry during the site visit and no ground elevation could be computed.


## Suggested Data Citation
The only provision for use of these datasets is that the creators request acknowledgement of the EDEN website and the USGS in all instances of publication or reference. They suggest using the following text:

The authors acknowledge the Everglades Depth Estimation Network (EDEN) project and the US Geological Survey for providing the [insert data type here] for the purpose of this research/report.