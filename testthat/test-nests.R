context("checks nest check data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
species <- read.csv("../SiteandMethods/species_list.csv") 
nests <- read.csv("../Nesting/nest_checks.csv", stringsAsFactors = FALSE) %>%
         dplyr::mutate(year = as.integer(year),
                       date = lubridate::ymd(date))
nest_cols <- colnames(nests)
success <- read.csv("../Nesting/nest_success.csv")
success_cols <- colnames(success)
success_summary <- read.csv("../Nesting/nest_success_summary.csv")
success_summary_cols <- colnames(success_summary)

test_that("required column names in nests df", {
  
  expect_identical(nest_cols, 
                   c("year","colony","nest","species","date","eggs","chicks","stage", "notes"))
  expect_identical(success_cols, 
                   c("year","colony","nest_number","species","n_days_incubation","incubation_success",
                     "n_days_nestling","nestling_success","clutch","brood","fledged","clutch_type",
                     "young_lost","real_success","real_failure","start_date","end_date","notes")) 
  expect_identical(success_summary_cols,
                   c("year","colony","species","incubation_k","incubation_sumy","incubation_e","incubation_p",
                     "incubation_j","incubation_pj","incubation_varp","incubation_varpj","incubation_sdp",
                     "incubation_sdpj","nestling_k","nestling_sumy","nestling_e","nestling_p","nestling_j",
                     "nestling_pj","nestling_varp","nestling_varpj","nestling_sdp","nestling_sdpj","overall_p",
                     "overall_varp","overall_sd"))
})

test_that("Colony and species valid", {
  
  expect_true(all(nests$colony %in% colonies$colony))
  expect_true(all(nests$species %in% species$species))
  expect_true(all(success$colony %in% colonies$colony))
  expect_true(all(success$species %in% species$species))
  expect_true(all(success_summary$colony %in% colonies$colony))
  expect_true(all(success_summary$species %in% species$species))
})

test_that("Dates valid", {
  
  expect_false(any(is.na(nests$date)))
  expect_false(any(is.na(nests$year)))
  expect_false(any(is.na(success$year)))
  expect_false(any(is.na(success_summary$year)))
  expect_false(any(is.na(success_summary$colony)))
})

test_that("Egg and chick counts valid", {
  
  expect_true(all(nests$eggs %in% c(0,1,2,3,4,5,6,7, NA)))
  expect_true(all(nests$chicks %in% c(0,1,2,3,4,5,6,7, NA)))
})

test_that("Nest stage valid", {
  
  expect_true(all(nests$stage %in% c("empty", "fledged", "failed", "incubating", "nestling","hatching",   
                                     "wet_chick", "missed", "pipping", "pre_flagged", "collapsed", "pre_marked",
                                     "pulled", "branchling", "chick_dry", "re_lay", "unknown", "", NA)))
})

test_that("no duplicated rows", {
  
  expect_false(any(duplicated(success_summary)))
})
