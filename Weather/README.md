# Weather Data
Data are from [NOAA Custom GHCN-Daily](https://www.ncei.noaa.gov/metadata/geoportal/rest/metadata/item/gov.noaa.ncdc:C00861/html#)

## [Weather Stations](weather_stations.csv)

station	name

latitude

longitude

elevation

min_date

max_date

## [Weather](weather.csv)

STATION - station ID

DATE - yyyy-mm-dd

DAEV - Number of days included in the multiday evaporation total (MDEV)

DAPR - Number of days included in the multiday precipitation total (MDPR)

DAWM - Number of days included in the multiday wind movement (MDWM)

EVAP - Evaporation of water from evaporation pan

MDEV - Multiday evaporation total (use with DAEV)

MDPR - Multiday precipitation total (use with DAPR and DWPR, if available)

MDWM - Multiday wind movement

MNPN - Daily minimum temperature of water in an evaporation pan

MXPN - Daily maximum temperature of water in an evaporation pan

PRCP - Precipitation (mm)

TAVG - Average temperature (C)

TMAX - Maximum temperature (C)

TMIN - Minimum temperature (C)

TOBS - Temperature at the time of observation (C)

WDMV - Total wind movement

WT01 - Fog, ice fog, or freezing fog (may include heavy fog)

WT03 - Thunder

WT05 - Hail (may include small hail)

WT06 - Glaze or rime

WT08 - Smoke or haze

WT11 - High or damaging winds

WT14 - Drizzle

WT16 - Rain (may include freezing rain, drizzle, and freezing drizzle)	

### _ATTRIBUTES Columns

All _ATTRIBUTES columns list data flags for that value. When applicable, flags are listed as MFLAG, QFLAG, SFLAG (not all flags always apply).

#### MFLAG 

Measurement flag. There are ten possible values:

Blank = no measurement information applicable

B = precipitation total formed from two 12-hour totals

D = precipitation total formed from four six-hour totals

H = represents highest or lowest hourly temperature (TMAX or TMIN) or the average of hourly values (TAVG)

K = converted from knots 

L = temperature appears to be lagged with respect to reported hour of observation 

O = converted from oktas 

P = identified as "missing presumed zero" in DSI 3200 and 3206

T = trace of precipitation, snowfall, or snow depth

W = converted from 16-point WBAN code (for wind direction)

#### QFLAG 

Quality flag. There are fourteen possible values:

Blank = did not fail any quality assurance check

D = failed duplicate check

G = failed gap check

I = failed internal consistency check

K = failed streak/frequent-value check

L = failed check on length of multiday period 

M = failed megaconsistency check

N = failed naught check

O = failed climatological outlier check

R = failed lagged range check

S = failed spatial consistency check

T = failed temporal consistency check

W = temperature too warm for snow

X = failed bounds check

Z = flagged as a result of an official Datzilla investigation

#### SFLAG  

Source flag.  There are thirty possible values (including numbers, upper and lower case letters):

Blank = No source (i.e., data value missing)

0 = U.S. Cooperative Summary of the Day (NCDC DSI-3200)

6 = CDMP Cooperative Summary of the Day (NCDC DSI-3206)

7 = U.S. Cooperative Summary of the Day -- Transmitted via WxCoder3 (NCDC DSI-3207)

A = U.S. Automated Surface Observing System (ASOS) real-time data (since January 1, 2006)

a = Australian data from the Australian Bureau of Meteorology

B = U.S. ASOS data for October 2000-December 2005 (NCDC DSI-3211)  

b = Belarus update

C = Environment Canada

D = Short time delay US National Weather Service CF6 daily summaries provided by the High Plains Regional 
Climate Center

E = European Climate Assessment and Dataset (Klein Tank et al., 2002)	   

F = U.S. Fort data 

G = Official Global Climate Observing System (GCOS) or other government-supplied data

H = High Plains Regional Climate Center real-time data

I = International collection (non U.S. data received through personal contacts)

K = U.S. Cooperative Summary of the Day data digitized from paper observer forms (from 2011 to present)

M = Monthly METAR Extract (additional ASOS data)

m = Data from the Mexican National Water Commission (Comision National del Agua -- CONAGUA)

N = Community Collaborative Rain, Hail,and Snow (CoCoRaHS)

Q = Data from several African countries that had been "quarantined", that is, withheld from public release 
until permission was granted from the respective meteorological services

R = NCEI Reference Network Database (Climate Reference Network and Regional Climate Reference Network)

r = All-Russian Research Institute of Hydrometeorological Information-World Data Center

S = Global Summary of the Day (NCDC DSI-9618)
                   NOTE: "S" values are derived from hourly synoptic reports
                   exchanged on the Global Telecommunications System (GTS).
                   Daily values derived in this fashion may differ significantly
                   from "true" daily data, particularly for precipitation
                   (i.e., use with caution).

s = China Meteorological Administration/National Meteorological Information Center/Climatic Data Center (http://cdc.cma.gov.cn)

T = SNOwpack TELemtry (SNOTEL) data obtained from the U.S. Department of Agriculture's Natural Resources Conservation Service

U = Remote Automatic Weather Station (RAWS) data obtained from the Western Regional Climate Center	   

u = Ukraine update	   

W = WBAN/ASOS Summary of the Day from NCDC's Integrated Surface Data (ISD).  

X = U.S. First-Order Summary of the Day (NCDC DSI-3210)

Z = Datzilla official additions or replacements 

z = Uzbekistan update
	   When data are available for the same time from more than one source,
	   the highest priority source is chosen according to the following
	   priority order (from highest to lowest):
	   Z,R,D,0,6,C,X,W,K,7,F,B,M,m,r,E,z,u,b,s,a,G,Q,I,A,N,T,U,H,S

## Cite as:

Menne, Matthew J., Imke Durre, Bryant Korzeniewski, Shelley McNeal, Kristy Thomas, Xungang Yin, Steven Anthony, Ron Ray, Russell S. Vose, Byron E.Gleason, and Tamara G. Houston (2012): Global Historical Climatology Network - Daily (GHCN-Daily), Version 3. [indicate subset used]. NOAA National Climatic Data Center. doi:10.7289/V5D21VHZ [access date].

## PRISM Normals Data
We use the PRISM dataset to calculate anomalies at the site (% average precipitation and temperature)

Location: Location:  Lat: 26.0832   Lon: -80.6252   Elev: 2m Spatial resolution: 4km

PRISM day definition: 24 hours ending at 1200 UTC on the day shown

Details: http://www.prism.oregonstate.edu/documents/PRISM_datasets.pdf

#### [Monthly 1991-2020 Normals](prism_normals.csv)
Dataset: Norm91m

#### [PRISM Time Series Data](prism_data.csv)
Dataset: AN81m
