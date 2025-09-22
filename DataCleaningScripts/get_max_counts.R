# get max counts

library(dplyr)
library(tidyr)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
            mutate(group_id = as.numeric(group_id),
                   latitude = as.numeric(latitude),
                   longitude = as.numeric(longitude))

experts <- c("MJR","mjr","LG","LG MJR","L. Garner","M. Rickershauser") 

count_year <- 2025

imagecounts <- read.csv("Counts/image_counts.csv") %>% 
  mutate(across(c("year","count"), as.numeric),
         date = as.Date(date)) %>% 
  filter(year==count_year, behavior=="nesting") %>%
  group_by(date,colony,species) %>%
  summarise(expert_count = mean(count[counter %in% experts]), 
            mean_count = mean(count), 
            image_sd = sd(count),
            .groups = 'drop') %>%
  mutate(image_count = expert_count,
         image_count = ifelse(is.nan(image_count),mean_count,image_count),
         image_sd = ifelse(is.nan(expert_count),image_sd,NA)) %>%
  select(date,colony,species,image_count,image_sd) 

flightsurveys <- read.csv("Counts/flight_surveys.csv") %>% 
  mutate(across(c("year","count"), as.numeric),
         date = as.Date(date)) %>% 
  filter(year==count_year, behavior=="nesting") %>%
  group_by(date,colony,species) %>%
  summarise(expert_count = mean(count[observer %in% experts]), 
            mean_count = mean(count), 
            flight_sd = sd(count),
            .groups = 'drop') %>%
  mutate(flight_count = expert_count,
         flight_count = ifelse(is.nan(flight_count),mean_count,flight_count),
         flight_sd = ifelse(is.nan(expert_count),flight_sd,NA)) %>%
  select(date,colony,species,flight_count,flight_sd) 

counts <- full_join(imagecounts,flightsurveys,by = c("date","colony","species")) %>%
  mutate(count = image_count,
         count_type = "image",
         count_type = ifelse(is.na(image_count),"flight","image"),
         count = ifelse(is.na(image_count),flight_count,image_count)) 

## Tables for review  
max_counts <- counts %>%
  slice_max(count, n = 1, by = c(colony,species)) %>%
  select(colony, species, count, date, count_type, image_count, flight_count) %>%
  arrange(colony,species)
## %>% pivot_wider(names_from = species, values_from = max_count)

# write.table(max_counts, "~/Desktop/max_counts_2025.csv", 
#             row.names = FALSE, col.names = TRUE, 
#             na = "", sep = ",")

# Write final table
max_counts_final <- max_counts %>% 
                left_join(colonies, by="colony") %>%
                mutate(year = count_year,
                       colony_old = colony,
                       notes = NA) %>%
                select(group_id,year,colony,colony_old,latitude,longitude,species,count,notes) %>%
                arrange(year,group_id) %>% distinct()

write.table(max_counts_final, "Counts/maxcounts.csv", row.names = FALSE, col.names = FALSE,
            append = TRUE, na = "", sep = ",", quote = 9) 

## Under 40 max counts
groundcounts <- read.csv("Counts/ground_counts.csv") %>% 
                mutate(across(c("year","latitude","longitude","count"), as.numeric),
                       date = as.Date(date)) %>%
                filter(year==count_year,
                       !(colony %in% max_counts_final$colony)) %>%
                slice_max(count, n = 1, by = c(transect,colony_waypoint,species)) %>%
                left_join(colonies[,-c(5:6)], by="colony") %>%              
                mutate(wca="3", colony_old=colony_waypoint) %>%
                select("year","wca","group_id","colony","colony_old","latitude",
                       "longitude","species","count","notes") 

write.table(groundcounts, "Counts/maxcounts_under40.csv", row.names = FALSE, col.names = FALSE,
            append = TRUE, na = "", sep = ",", quote = 10) 

############################## Add ENP data ###################################################
filepath <- "~/UFL Dropbox/Glenda Yenni/Everglades/2025 Data/Field Data/Clean data/"
enp_filename <- "ENP_max_count_2025.xlsx"

species <- read.csv("SiteandMethods/species_list.csv")

enp_data <- readxl::read_excel(paste(filepath,enp_filename,sep=""), 
                               sheet = 1, col_types = "text") %>%
  rename_with(tolower) %>%
  mutate(colony_old = colony,
          colony = tolower(colony),
          colony = gsub(" ", "_", colony),
          colony = gsub("/", "_", colony),
          colony = replace(colony, colony=="colony_13", "colony13"),
          colony = replace(colony, colony=="cuthbert", "cuthbert_lake"),
          colony = replace(colony, colony=="paurotis", "paurotis_pond"),
          colony = replace(colony, colony=="colony_14", "colony14"),
          colony = replace(colony, colony %in% c("colony_15", "colony_2022"), "colony15"),
          colony = replace(colony, colony %in% 
                                        c("shark_valley_observation_tower",
                                          "shark_valley_tower"), "shark_valley"),
          colony = replace(colony, colony %in% c("shark_valley_tram_road_nw",
                                                 "w_of_tram_rd"), "shark_valley_tram"),
          colony = replace(colony, colony=="shark_river_slough_se", "shark_river_slough"),
          colony = replace(colony, colony %in% 
                                        c("rodgers_river_bay_large_island",
                                          "rodgers_river_bay_small_island",
                                          "rodgers_river"), "rodgers_river_bay"),
          colony = replace(colony, colony=="grossman_ridge_willowhead", 
                                                  "grossman_willowhead")) %>%
  left_join(colonies, by = join_by(colony)) %>%
  pivot_longer(cols = any_of(species$species), 
                      names_to = "species",
                      values_to = "count") %>%
  mutate(year = count_year) %>%
  filter(!is.na(count),count!=0) %>%
  mutate(year = as.numeric(year),
         latitude = as.numeric(latitude),
         longitude = as.numeric(longitude),
         count = as.numeric(count)) %>%
  select("group_id","year","colony","colony_old","latitude","longitude",
                "species","count","notes")

if(!all(enp_data$colony %in% colonies$colony)| 
   !all(enp_data$species %in% species$species)) {
  print(unique(enp_data$colony[which(!(enp_data$colony %in% colonies$colony))]))
  print(unique(enp_data$species[which(!(enp_data$species %in% species$species))]))
}

# Write
write.table(enp_data, "Counts/maxcounts.csv", row.names = FALSE, col.names = FALSE,
            append = TRUE, na = "", sep = ",", quote = 9) 
