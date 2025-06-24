# EvergladesWadingBird Data
<!-- badges: start -->
[![Build Status](https://github.com/weecology/EvergladesWadingBird/actions/workflows/main.yml/badge.svg)](https://github.com/weecology/EvergladesWadingBird/actions/workflows/main.yml)
[![License](http://i.creativecommons.org/p/zero/1.0/88x31.png)](https://raw.githubusercontent.com/weecology/PortalData/main/LICENSE)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.7734553.svg)](https://doi.org/10.5281/zenodo.7734553)
[![USACE-W912HZ-20-2-0022/3](https://img.shields.io/badge/USACE-W912HZ--20--2--0022%2F3-blue)](https://www.saj.usace.army.mil/Missions/Environmental/Ecosystem-Restoration/)

<!-- badges: end -->

Data from the Everglades breeding bird monitoring project

Detailed descriptions of individual data components are located in README.md files in the individual data folders. Please see the [methods](https://everglades-wading-bird-data.netlify.app/) for details about collection and how to use the data.

Water depth is crucial to wading bird behavior. Water depth data are available from the [Everglades Depth Estimation Network (EDEN)](http://sofia.usgs.gov/eden), via their [EDEN THREDDS server](http://sflthredds.er.usgs.gov/) or the [Explore and View EDEN (EVE) web application](https://sofia.usgs.gov/eden/eve/). We also have created the [edenR package](https://github.com/weecology/edenR) to streamline downloads, data processing, and statistics for forecasting.

Additional data to complement the wading bird data can be found at [South Florida Water Management District](https://www.sfwmd.gov/) and [Florida Coastal Everglades LTER](http://fcelter.fiu.edu/).

### Data Organization
------------
    |-- Counts              <- Time series of count data from aerial and UAV images, and ground transects
    |-- DataCleaningScripts <- Scripts used to add new data
    |-- Hg                  <- Time series of feather mercury content
    |-- Historic            <- Pre-1986 data, or outside data sources
    |-- Indicators          <- Time series of indicators used in restoration assessment
    |-- Methods             <- Data paper wiki outlining detailed methods
    |-- Nesting             <- Time series of nest checks and nest success
    |-- SiteandMethods      <- Site details, site-level data tables
    |-- Weather             <- Weather station data (from NOAA)
--------

## Developer Setup

**Prerequisites:** Quarto, Git, R (4.0+) and or RStudio

1. Clone and install dependencies:
   ```bash
   git clone https://github.com/weecology/EvergladesWadingBird.git
   cd EvergladesWadingBird
   R -e "source('install-packages.R')"
   ```

2. Run the methods website locally:
   ```bash
   cd Methods
   quarto preview
   ```
