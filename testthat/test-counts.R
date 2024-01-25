context("checks count data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
species <- read.csv("../SiteandMethods/species_list.csv") 
counts <- read.csv("../Counts/maxcounts.csv")
counts_cols <- colnames(counts)
counts_under40 <- read.csv("../Counts/maxcounts_under40.csv")
counts_under40_cols <- colnames(counts_under40)

test_that("required column names in counts df", {
  
  expect_identical(counts_cols, 
                   c("group_id","year","colony","colony_old","latitude","longitude",      
                     "species","count","notes"))
  expect_identical(counts_under40_cols, 
                   c("group_id","year","colony","colony_old", "latitude","longitude","wca","greg",     
                     "whib","wost","gbhe","rosp","sneg","anhi","trhe","bcnh","lbhe","ycnh","glib",
                     "caeg","dcco","grhe","smhe","lawh","lada","smda","smwh","notes","total"))
})

test_that("Lat and long valid", {
  
  expect_true(all((counts$latitude <= 27 | counts$latitude > 25)))
  expect_true(all((counts$longitude <= -80 | counts$longitude > -81.3)))
  expect_true(all((counts_under40$latitude <= 27 | counts_under40$latitude > 25)))
  expect_true(all((counts_under40$longitude <= -80 | counts_under40$longitude > -81.3)))
})

test_that("Colony and species valid", {
  
  expect_true(all(counts$colony %in% colonies$colony))
  expect_true(all(counts$species %in% species$species))
  expect_true(all(counts_under40$wca %in% c(colonies$region,colonies$subregion,"3a","")))
})

test_that("Year valid", {

  expect_false(any(is.na(counts$year)))
  expect_false(any(is.na(counts_under40$year)))
})

test_that("Counts valid", {
  
  expect_true(all(is.integer(counts$count)))
  
})
