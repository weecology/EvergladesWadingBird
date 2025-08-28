## Clean flight image count data and append to dataset

library(tidyr)
library(dplyr)
library(janitor)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

############################# Get raw data #########################################
year <- 2025

filepath <- "~/Desktop/photos/"
filename <- "Image_count_2025.xlsx"

data_path <- paste(filepath,filename,sep="")

new_data <- readxl::read_excel(data_path, 
                               col_names = TRUE,     
                               col_types = c(rep("text",2),"date",rep("text",7))) %>%
  clean_names() %>%
  filter(!is.na(count), count!=0) %>%
  mutate(year = year,
         colony_old = colony,
         latitude = NA,
         longitude = NA) %>%
  mutate(colony = tolower(colony)) %>%
  mutate(across(c("type","camera","filenames","counter"), ~gsub(" ", "",.))) %>%
  mutate(across(c("type","camera","filenames","counter"), ~gsub("\"", "",.))) %>%
  mutate(across(c("type","camera","counter"), ~gsub(",", "",.))) %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  mutate(colony = replace(colony, colony=="77", "canal_north"),
         colony = replace(colony, colony=="99", "ivy"),
         colony = replace(colony, colony=="tyr", "lox73"),
         colony = replace(colony, colony=="008", "8")) %>%
  select("year", "date", "colony", "colony_old", "latitude", "longitude", "type", "camera", 
         "filenames", "counter", "species", "behavior", "count", "notes")

######################## Check for errors and write #######################################

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/image_counts.csv", 
            row.names = FALSE, col.names = FALSE, 
            append = TRUE, na = "", sep = ",", quote = c(9,14))
