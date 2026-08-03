## Clean flight survey data and append to dataset

library(tidyr)
library(dplyr)
library(janitor)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

############################# Get raw data #########################################
new_year <- 2026

filepath <- "~/UFL Dropbox/Glenda Yenni/Everglades/WadingBird_Primary Data/Counts/aerial/Clean data/"
filename <- "Flight_survey data_2026.xlsx"

data_path <- paste(filepath,filename,sep="")

new_data <- readxl::read_excel(data_path, 
                               col_names = TRUE,     
                               col_types = c("date",rep("text",14))) %>%
            clean_names() %>%
            filter(!is.na(count), count!=0) %>%
  mutate(year = new_year,
         colony_old = colony) %>%
  mutate(colony = tolower(colony)) %>%
  mutate(across(c("photo_sets","photos"), ~gsub(",","",.))) %>%
  mutate(across(c("photo_sets","photos"), ~gsub("\"", "",.))) %>%
  mutate(across(c("year","count"), as.numeric)) %>%
  left_join(colonies, by = "colony") %>%
  select("year","date", "colony", "colony_old", "latitude", "longitude", "start_transect", 
         "end_transect", "start_time", "end_time", "observer", "photo_sets", "photos", 
         "species", "behavior", "count", "notes")

######################## Check for errors and write #######################################

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(11,17))

## Remove year to rewrite
flights <- read.csv("Counts/flight_surveys.csv") %>%
           filter(year<new_year)
write.table(flights, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = TRUE,
            na = "", sep = ",", quote = c(11,17))
