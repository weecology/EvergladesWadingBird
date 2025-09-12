# get max counts

library(dplyr)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
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
