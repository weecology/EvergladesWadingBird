context("checks nest check data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
species <- read.csv("../SiteandMethods/species_list.csv") 
nests <- read.csv("../Nesting/nest_checks.csv") %>%
  dplyr::mutate(date = lubridate::ymd(date))
nest_cols <- colnames(nests)

test_that("required column names in nests df", {
  
  expect_identical(nest_cols, 
                   c("year","colony","nest","species","date","eggs","chicks","stage", "notes"))
})

test_that("Colony and species valid", {
  
  expect_true(all(nests$colony %in% colonies$colony))
  expect_true(all(nests$species %in% species$species))
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
