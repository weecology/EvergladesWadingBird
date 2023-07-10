context("checks indicator data")

max_count <- read.csv("../Indicators/max_count_all.csv")
initiation <- read.csv("../Indicators/stork_initiation.csv") 
foraging <- read.csv("../Indicators/coastal_nesting.csv")
max_count_cols <- colnames(max_count)

test_that("required column names in max counts df", {
  
  expect_identical(max_count_cols, 
                   c("year", "region", "species", "count"))
})

test_that("Year valid", {

  expect_true(all(is.integer(max_count$year)))
  expect_true(all(is.integer(initiation$year)))
  expect_true(all(is.integer(foraging$year)))
})

test_that("Counts valid", {
  
  expect_true(all(is.integer(max_count$count)))
  
})
