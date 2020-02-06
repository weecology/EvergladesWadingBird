# Install pacman if it isn't already installed
if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")

# Install packages required for analysis

pacman::p_load(git2r, httr, semver, testthat, yaml, 
               dplyr, lubridate)
