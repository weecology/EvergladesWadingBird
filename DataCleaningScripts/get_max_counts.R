# get max counts

library(dplyr)

experts <- c("LG","MJR","LG MJR","L. Garner","M. Rickershauser") 

count_year <- 2024

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
         count = ifelse(is.na(image_count),flight_count,image_count))
  
max_counts <- counts %>%
  group_by(colony,species) %>%
  summarise(max_count = max(count),
            .groups = 'drop')
