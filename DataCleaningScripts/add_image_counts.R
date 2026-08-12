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
new_year <- 2026

filepath <- "~/UF Dropbox/Glenda Yenni/Everglades/WadingBird_Primary Data/Counts/photos/Clean Data/"
filename <- "image_count_data_2026.xlsx"

data_path <- paste(filepath,filename,sep="")

new_data <- readxl::read_excel(data_path, 
                               col_names = TRUE,     
                               col_types = c(rep("text",2),"date",rep("text",8)))

new_data <- new_data[,1:11]
colnames(new_data)[11] <- "notes"

new_data <- new_data %>%
  clean_names() %>%
  filter(!is.na(count), count!=0) %>%
  mutate(year = new_year,
         colony_old = colony) %>%
  mutate(colony = tolower(colony)) %>%
  mutate(colony = replace(colony, colony=="142","indri"),
         colony = replace(colony, colony=="143","emperor_tamarin"),
         colony = replace(colony, colony=="145","gibbon"),
         colony = replace(colony, colony=="146","mandrill"),
         colony = replace(colony, colony=="147","vervet"),
         colony = replace(colony, colony=="48","napo_saki"),
         colony = replace(colony, colony=="106","tarsier"),
         colony = replace(colony, colony=="75","yaku"),
         colony = replace(colony, colony=="tyger_west","tyger")) %>%
  mutate(across(c("type","camera","filenames","counter"), ~gsub(" ", "",.))) %>%
  mutate(across(c("type","camera","filenames","counter"), ~gsub("\"", "",.))) %>%
  mutate(across(c("type","camera","counter"), ~gsub(",", "",.))) %>%
  left_join(colonies, by = "colony") %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  select("year", "date", "colony", "colony_old", "latitude", "longitude", "type", "camera", 
         "filenames", "counter", "species", "behavior", "count", "notes") %>% 
  arrange(year,date,colony,species)

######################## Check for errors and write #######################################

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/image_counts.csv", 
            row.names = FALSE, col.names = FALSE, 
            append = TRUE, na = "", sep = ",", quote = c(9,14))

## Remove year to rewrite
images <- read.csv("Counts/image_counts.csv") %>%
  filter(year<new_year)
write.table(images, "Counts/image_counts.csv", 
            row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = c(9,14))
