library(dplyr)
library(lubridate)
library(sf)
library(stringr)

# Load field nests
field_nests <- read.csv("Nesting/UAV_Flagged_Nest_Coordinates.csv")

# Load field nest samples
sample_locations <- read.csv("Nesting/field_nest_sample_locations.csv")

# Load bird predictions
bird_codes <- data.frame(
  row.names = c("Great Egret", "Great Blue Heron", "Roseate Spoonbill",
                "Wood Stork", "Snowy Egret", "White Ibis"),
  val = c("greg", "gbhe", "rosp", "wost", "sneg", "whib")
)

bird_predictions_url = "https://github.com/weecology/EvergladesTools/blob/main/App/Zooniverse/data/PredictedBirds.zip?raw=true"
download.file(bird_predictions_url, "PredictedBirds.zip")
unzip("PredictedBirds.zip", exdir = "Nesting")

birds <- st_read("Nesting/PredictedBirds.shp") %>%
  filter(score > 0.3) %>% #Make sure there's a good chance we're focusing on an area with a bird
  st_transform(4326) %>%
  st_centroid() #Force values to points
bird_coords <- st_coordinates(birds) %>%
  as.data.frame() %>%
  select(lat = Y, long = X)
birds <- birds %>%
  as.data.frame() %>%
  bind_cols(bird_coords) %>%
  mutate(species = bird_codes[label,]) %>%
  mutate(event = as.Date(event, "%m_%d_%Y")) %>%
  mutate(year = year(event)) %>%
  select(site, year, species, lat, long)

# Add random bird locations to field nests
# Provides the sampling locations so reviewers don't know that a
# region they are shown is definitely a field nest

set.seed(26) # Keep same nest number and fake nest locations across runs

get_new_samp_locs <- function(focal_birds, focal_field_nests, site, year){
  random_birds <- focal_birds %>%
    mutate(real_nest = "no", field_nest_id = "") %>%
    slice(sample(1:nrow(focal_field_nests))) %>%
    select(site, year, real_nest, field_nest_id, lat, long, species)

  field_nests <- focal_field_nests %>%
    mutate(real_nest = "yes") %>%
    select(site, year, real_nest, field_nest_id, lat, long, species) %>%
    rbind(random_birds) %>%
    slice(sample(1:n())) %>% # Randomize order to not give clues to real nests
    mutate(sample_id = seq_len(n())) %>%
    select(site, year, sample_id, real_nest, field_nest_id, species, lat, long)

  return(field_nests)
}

field_nest_surveys <- unique(field_nests[c("site", "year")])
samp_locs_updated <- sample_locations
changes_made <- FALSE
for (i in seq_len(nrow(field_nest_surveys))) {
  focal_site <- field_nest_surveys[i, ]["site"][[1]]
  focal_year <- field_nest_surveys[i, ]["year"][[1]]
  focal_field_nests <- filter(field_nests, site == focal_site, year == focal_year)
  focal_sample_locations <- filter(sample_locations, site == focal_site, year == focal_year)
  focal_birds <- filter(birds, site == focal_site, year == focal_year)
  field_nest_count <- nrow(focal_field_nests)
  samp_count_yes <- nrow(filter(focal_sample_locations, real_nest == "yes"))
  samp_count_no <- nrow(filter(focal_sample_locations, real_nest == "no"))
  if (samp_count_yes == 0 & samp_count_no == 0) {
    new_samp_locs <- get_new_samp_locs(focal_birds, focal_field_nests, site, year)
    samp_locs_updated <- rbind(samp_locs_updated, new_samp_locs)
    changes_made <- TRUE
  } else if (samp_count_yes != field_nest_count | samp_count_no != field_nest_count) {
    stop("Field nest counts and sample counts don't match and sample counts are not zero. Help!")
  }
}

if (changes_made){
  message("Updating sampling file with for new field nests")
  write.csv(samp_locs_updated, "Nesting/field_nest_sample_locations.csv", row.names = FALSE)
} else {
  message("No updates required")
}