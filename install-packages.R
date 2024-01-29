# Install pacman if it isn't already installed
if ("pacman" %in% rownames(installed.packages()) == FALSE) install.packages("pacman")

# Install packages required for analysis
pacman::p_load(cubelyr, dplyr, git2r, httr, lubridate, rvest, semver, sf, stars, terra, testthat, tidyr, yaml)