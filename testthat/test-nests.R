context("checks nest check data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
species <- read.csv("../SiteandMethods/species_list.csv") 
nests <- read.csv("../Nesting/nest_checks.csv") %>%
  dplyr::mutate(date = lubridate::ymd(date))
nest_cols <- colnames(nests)
success <- read.csv("../Nesting/nest_success.csv")
success_cols <- colnames(success)

test_that("required column names in nests df", {
  
  expect_identical(nest_cols, 
                   c("year","colony","nest","species","date","eggs","chicks","stage", "notes"))
  expect_identical(success_cols, 
                   c("year","colony","nest_number","species","n_days_incubation","incubation_success",
                     "n_days_nestling","nestling_success","clutch","brood","fledged","clutch_type",
                     "young_lost","real_success","real_failure","start_date","end_date","notes"))    
})

test_that("Colony and species valid", {
  
  expect_true(all(nests$colony %in% colonies$colony))
  expect_true(all(nests$species %in% species$species))
  expect_true(all(success$colony %in% success$colony))
  expect_true(all(success$species %in% success$species))
})

test_that("Dates valid", {
  
  expect_false(any(is.na(nests$date)))
  expect_false(any(is.na(nests$year)))
})

test_that("Egg and chick counts valid", {
  
  expect_true(all(nests$eggs %in% c(0,1,2,3,4,5,6,7, NA)))
  expect_true(all(nests$chicks %in% c(0,1,2,3,4,5,6,7, NA)))
})

# test_that("no duplicated rows", {
#   
#   expect_false(any(duplicated(nests)))
# })
