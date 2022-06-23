context("checks count data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
species <- read.csv("../SiteandMethods/species_list.csv") 
counts <- read.csv("../Counts/maxcounts.csv") %>%
  dplyr::mutate(date = lubridate::ymd(date))
counts_cols <- colnames(counts)

test_that("required column names in counts df", {
  
  expect_identical(counts_cols, 
                   c("year","colony","nest","species","date","eggs","chicks","stage", "notes"))
})

test_that("Colony and species valid", {
  
  expect_true(all(counts$colony %in% colonies$colony))
  expect_true(all(counts$species %in% species$species))
})

test_that("Year valid", {

  expect_false(any(is.na(counts$year)))
})

test_that("Counts valid", {
  
  expect_true(all(is.integer(counts$count)))
  
})

# test_that("no duplicated rows", {
#   
#   expect_false(any(duplicated(counts)))
# })
