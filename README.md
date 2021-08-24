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
    |-- Zooniverse         <- Main directory for bird detection model training, bird-bird-bird prediction and parsing Zooniverse annotations
        |-- SLURM         <- SLURM scripts for submitting jobs on Hipergator
        |-- species_model <- Multi-class species model
        |-- aggregate.py  <- Main script for downloading and cleaning Zooniverse annotatiosn
        |-- extract.py    <- Download images that match annotations from Zooniverse
        |-- cron.txt     <- Cron job to run a model and sync the dropbox
        |-- manifest.py  <- upload images to Zooniverse
        |-- nest_aggregate.py <- Download and clean nest label series from Zooniverse
        |-- nest_detection.py <- Given a set of predictions in /orange/ewhite/everglades/predictions/, generate predicted nests using Bird-Bird-Bird
        |-- predict.py <- Predict bird locations
        |-- start_cluster.py <- Useful dask utilities for parallel data processing
        |-- tile_raster.py <- Split a large orthomosaic into smaller tiles
        |-- upload_mapbox.py <- Upload data to mapbox for visualization server
    ├── environment.yml   <- Conda requirements
    │
    ├── setup.py           <- makes project pip installable (pip install -e .) so src can be imported
    ├── src                <- Source code for use in this project.
    │   ├── __init__.py    <- Makes src a Python module
    │   ├── data           <- Pytorch Lighting data module for creating dataloaders for model training
    │   ├── dataset        <- Pytorch dataset for generating batches of data
    │   ├── generate       <- Convert csv of point files to tree crowns
    │   ├── main           <- Pytorch Lightning Module for model training
    │   ├── neon_paths     <- Utilities for getting paths and metadata from NEON HSI data
    │   ├── patches        <- Convert tree crowns into a set of pixels with overlapping windows
    │   ├── start_cluster  <- dask utilities for SLURM parallel processing


--------

# Bird-Bird-Bird Workflow

0. Sync dropbox to hipergator

```
rclone sync everglades2021:"Wading Bird 2021/Deliverables/" /orange/ewhite/everglades/2021
```

1. Predict bird locations using trained model using predict.py. If you need to train a new model see the [BirdDetectorRepo](https://github.com/weecology/BirdDetector/blob/main/everglades.py)

```
python Zooniverse/predict.py
```
This will run the everglades bird detector on all files in /orange/ewhite/everglades/2021 and save predicted bird locations to /orange/ewhite/everglades/predictions. 


2. Predict nest-locations using bird-bird-bird 

```
python Zooniverse/nest_detection.py
```

Both steps are run together in 
```
sbatch Zooniverse/SLURM/predict.sbatch
```
