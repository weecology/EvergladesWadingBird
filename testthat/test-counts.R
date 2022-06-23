context("checks count data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
species <- read.csv("../SiteandMethods/species_list.csv") 
counts <- read.csv("../Counts/maxcounts.csv")
counts_cols <- colnames(counts)

test_that("required column names in counts df", {
  
  expect_identical(counts_cols, 
                   c("group_id","year","colony","colony_old","latitude","longitude","region",      
                     "species","count","notes"))
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
