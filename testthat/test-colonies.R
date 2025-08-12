context("checks site data")

colonies <- read.csv("../SiteandMethods/colonies.csv")
colonies_cols <- colnames(colonies)

species <- read.csv("../SiteandMethods/species_list.csv") 
species_cols <- colnames(species)

test_that("required column names in colonies df", {
  
  expect_identical(colonies_cols, 
                   c("group_id","colony","region","subregion","latitude","longitude",
                     "aka","display_name"))
})

test_that("required column names in species df", {
  
  expect_identical(species_cols, 
                   c("species","commonname","scientificname","target_species",
                     "incubation_j","nestling_j","clutch_size","egg_color",
                     "nest_size","nest_materials","nest_microhabitat","colony_habitat",
                     "brood_size","nest_success","chick_description","typical_timing_range",
                     "courtship_period","nestbuilding_period","reproductive_period",
                     "nestling_period","incubation_period","branchling_period","feeding_methods",
                     "foraging_depth","foraging_type","niche_description","prey"))
})

test_that("Lat and long valid", {
  
  expect_true(all((colonies$latitude <= 27 | colonies$latitude > 25)))
  expect_true(all((colonies$longitude <= -80 | colonies$longitude > -81.3)))
})

test_that("No duplications", {
  
  expect_false(any(duplicated(colonies$group_id)))
  expect_false(any(duplicated(colonies$colony)))
  expect_false(any(duplicated(colonies)))
  expect_false(any(duplicated(species)))
})
