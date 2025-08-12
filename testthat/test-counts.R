context("checks count data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
species <- read.csv("../SiteandMethods/species_list.csv") 
counts <- read.csv("../Counts/maxcounts.csv")
counts_cols <- colnames(counts)
counts_under40 <- read.csv("../Counts/maxcounts_under40.csv")
counts_under40_cols <- colnames(counts_under40)
flight_surveys <- read.csv("../Counts/flight_surveys.csv")
flight_surveys_cols <- colnames(flight_surveys)
image_counts <- read.csv("../Counts/image_counts.csv")
image_counts_cols <- colnames(image_counts)
ground_counts <- read.csv("../Counts/ground_counts.csv")
ground_counts_cols <- colnames(ground_counts)

test_that("required column names in counts df", {
  
  expect_identical(counts_cols, 
                   c("group_id","year","colony","colony_old","latitude","longitude",      
                     "species","count","notes"))
  expect_identical(counts_under40_cols, 
                   c("group_id","year","colony","colony_old", "latitude","longitude","wca","greg",     
                     "whib","wost","gbhe","rosp","sneg","anhi","trhe","bcnh","lbhe","ycnh","glib",
                     "caeg","dcco","grhe","smhe","lawh","lada","smwh","total","notes"))
  expect_identical(flight_surveys_cols, 
                   c("year","date","colony","colony_old","latitude","longitude","start_transect",
                     "end_transect","start_time","end_time","observer","photo_sets",
                     "photos","species","behavior","count","notes"))
  expect_identical(image_counts_cols, 
                   c("year","date","colony","colony_old","latitude","longitude",
                     "type","camera","filenames","counter",
                     "species","behavior","count","notes"))
  expect_identical(ground_counts_cols, 
                   c("year","date","transect","colony_waypoint","colony", "latitude","longitude",
                     "species","count","nests","chicks","notes"))
})

test_that("Lat and long valid", {
  
  expect_true(all((counts$latitude <= 27 | counts$latitude > 25)))
  expect_true(all((counts$longitude <= -80 | counts$longitude > -81.3)))
  expect_true(all((counts_under40$latitude <= 27 | counts_under40$latitude > 25)))
  expect_true(all((counts_under40$longitude <= -80 | counts_under40$longitude > -81.3)))
  expect_true(all((na.omit(flight_surveys$latitude) <= 27 | na.omit(flight_surveys$latitude) > 25)))
  expect_true(all((na.omit(flight_surveys$longitude) <= -80 | na.omit(flight_surveys$longitude > -81.3))))
  expect_true(all((na.omit(image_counts$latitude) <= 27 | na.omit(image_counts$latitude) > 25)))
  expect_true(all((na.omit(image_counts$longitude) <= -80 | na.omit(image_counts$longitude > -81.3))))
  expect_true(all((na.omit(ground_counts$latitude) <= 27 | na.omit(ground_counts$latitude) > 25)))
  expect_true(all((na.omit(ground_counts$longitude) <= -80 | na.omit(ground_counts$longitude > -81.3))))
})

test_that("Colony and species valid", {
  
  expect_true(all(counts$colony %in% colonies$colony))
  expect_true(all(counts$group_id %in% colonies$group_id))
  expect_true(all(counts$species %in% species$species))
  expect_true(all(counts_under40$wca %in% c(colonies$region,colonies$subregion,"3a","")))
  expect_true(all(na.omit(flight_surveys$colony) %in% c(colonies$colony,"")))
  expect_true(all(flight_surveys$species %in% species$species))
  expect_true(all(na.omit(image_counts$colony) %in% c(colonies$colony,"")))
  expect_true(all(image_counts$species %in% species$species))
  expect_true(all(na.omit(ground_counts$colony) %in% c(colonies$colony,"")))
  expect_true(all(ground_counts$species %in% species$species))
})

test_that("Year valid", {

  expect_false(any(is.na(counts$year)))
  expect_false(any(is.na(counts_under40$year)))
  expect_false(any(is.na(flight_surveys$year)))
  expect_false(any(is.na(image_counts$year)))
  expect_false(any(is.na(ground_counts$year)))
})

test_that("Counts valid", {
  
  expect_true(all(is.integer(counts$count)))
  expect_true(all(is.integer(flight_surveys$count)))
  expect_true(all(is.integer(image_counts$count)))
  expect_true(all(is.integer(na.omit(ground_counts$count))))
  expect_true(all(is.integer(na.omit(ground_counts$nests))))
  expect_true(all(is.integer(na.omit(ground_counts$chicks))))
})
