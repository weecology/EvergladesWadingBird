# get max counts

library(dplyr)

experts <- c("LG","MJR","LG MJR","L. Garner","M. Rickershauser") 

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
  
max_counts <- counts %>%
  slice_max(count, n = 1, by = c(colony,species)) %>%
  select(colony, species, count, date, count_type, image_count, flight_count) %>%
  arrange(colony,species)


%>%
  pivot_wider(names_from = species, values_from = max_count)

write.table(max_counts, "~/Desktop/max_counts_2025.csv", 
            row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",")
