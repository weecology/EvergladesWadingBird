context("checks new water data")

depth <- read.csv(file = "../Water/eden_depth.csv",header=T) %>%
  dplyr::mutate(date = lubridate::ymd(date))
depth_names <- colnames(depth)
covariates <- read.csv(file = "../Water/eden_covariates.csv",header=T)
covariates_names <- colnames(covariates)

test_that("required column names in new water df", {

  expect_identical(depth_names,
                   c("date","region","depth_mean", "depth_sd", "depth_max", "depth_min" ))
  expect_identical(covariates_names,
                   c("year","region","init_depth","breed_season_depth", "recession",
                     "pre_recession","post_recession","dry_days","reversals"))
})

test_that("Dates valid", {

  expect_false(any(is.na(depth$date)))
})
