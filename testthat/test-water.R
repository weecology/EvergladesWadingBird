context("checks new water data")

depth <- read.csv(file = "../Water/eden_depth.csv",header=T) %>%
  dplyr::mutate(date = lubridate::ymd(date))
depth_names <- colnames(depth)
covariates <- read.csv(file = "../Water/eden_covariates.csv",header=T)
covariates_names <- colnames(covariates)
colonies <- read.csv("../SiteandMethods/colonies.csv")

test_that("required column names in new water df", {

  expect_identical(depth_names,
                   c("date","region","depth_mean", "depth_sd", "depth_max", "depth_min" ))
  expect_identical(covariates_names,
                   c("year","region","init_depth","breed_season_depth", "recession",
                     "pre_recession","post_recession","dry_days","reversals"))
})

test_that("Subregions valid", {
  
  expect_true(all(depth$region %in% c(colonies$subregion,"all","wcas","enp")))
  expect_true(all(covariates$region %in% c(colonies$subregion,"all","wcas","enp")))
})

test_that("Dates valid", {

  expect_false(any(is.na(depth$date)))
})
