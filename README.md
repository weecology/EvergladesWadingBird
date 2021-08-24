# EvergladesWadingBird Data
<!-- badges: start -->
[![Build Status](https://github.com/weecology/EvergladesWadingBird/workflows/CI/badge.svg)](https://github.com/weecology/EvergladesWadingBird/actions)
[![License](http://i.creativecommons.org/p/zero/1.0/88x31.png)](https://raw.githubusercontent.com/weecology/PortalData/main/LICENSE)
<!-- badges: end -->

Data from the Everglades breeding bird monitoring project

Detailed descriptions of individual data components are located in README.md files in the individual data folders.

Additional data to complement the wading bird data can be found at [Florida Coastal Everglades LTER](http://fcelter.fiu.edu/).


Project Organization
------------

    ├── LICENSE
    ├── README.md          <- The top-level README for developers using this project.
    ├── App                <- Shiny App for visualizing results from Zooniverse and predictions 
    |-- DataCleaningScripts <- 
    |-- Hg                 <-
    |-- Nesting            <-
    |-- SiteandMethods    <-
    |-- SuperPopulationModel <- Data Exploration and Simulations for a Wading Bird Population Model
    |-- Water              <-
    |-- Weather            <-
    |-- Zooniverse         <- bird detection model training, bird-bird-bird prediction and parsing Zooniverse annotations
        |-- SLURM            <- SLURM scripts for submitting jobs on Hipergator
        |-- species_model    <- Multi-class species model
        |-- aggregate.py     <- Main script for downloading and cleaning Zooniverse annotatiosn
        |-- extract.py       <- Download images that match annotations from Zooniverse
        |-- cron.txt         <- Cron job to run a model and sync the dropbox
        |-- manifest.py      <- upload images to Zooniverse
        |-- nest_aggregate.py <- Download and clean nest label series from Zooniverse
        |-- nest_detection.py <- Generate predicted nests using Bird-Bird-Bird
        |-- predict.py       <- Predict bird locations
        |-- start_cluster.py <- Useful dask utilities for parallel data processing
        |-- tile_raster.py   <- Split a large orthomosaic into smaller tiles
        |-- upload_mapbox.py <- Upload data to mapbox for visualization server
--------

# Bird-Bird-Bird

## Environment

Conda or mamba (faster)
```
mamba env create -f=environment.yml
```
The environment can be sensitive to the new CUDA version. Its often useful to first install torch and torch vision from -c pytorch and then install the rest of the environment. 

0. Sync dropbox to hipergator

```
rclone sync everglades2021:"Wading Bird 2021/Deliverables/" /orange/ewhite/everglades/2021
```

1. Predict bird locations using trained model using predict.py. If you need to train a new model see the [BirdDetectorRepo](https://github.com/weecology/BirdDetector/blob/main/everglades.py). To create the annotations for the bird detector model run [this](https://github.com/weecology/EvergladesWadingBird/blob/main/Zooniverse/create_bird_detector_annotations.py)

```
python Zooniverse/predict.py
```
This will run the everglades bird detector on all selected files in /orange/ewhite/everglades/2021 and save predicted bird locations to /orange/ewhite/everglades/predictions. A subset of sites can be selected using the find_files() function. An aggregate .shp of all bird detections is written this repo at

```
App/Zooniverse/data/PredictedBirds.shp
```
The output shapefile contains the predicted polygon, confidence score, site and event date.
```
>>> import geopandas as gpd
>>> gdf[["score","site","event"]]
          score     site       event
0      0.246132   Jerrod  03_24_2020
1      0.349666   Jerrod  03_24_2020
...         ...      ...         ...
14033  0.270656  Yonteau  04_27_2020
14034  0.237832  Yonteau  04_27_2020
```

2. Predict nest-locations using bird-bird-bird 

```
python Zooniverse/nest_detection.py
```

This will save nest series images to 

```
/orange/ewhite/everglades/nest_crops/
```
and a aggregate shapefile at /orange/ewhite/everglades/nest_crops/nest_detections.shp

The shapefile contains the predicted next polygon, site, date and a unique identifier.
```
>>> gdf[["Site","Date","target_ind"]].head()
          Site        Date  target_ind
0        Aerie  04_27_2020         880
1        Aerie  04_27_2020         880
2  CypressCity  03_11_2020           7
3  CypressCity  04_29_2020           7
4  CypressCity  04_01_2020           8
```
