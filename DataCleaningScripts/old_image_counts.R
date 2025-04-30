library(tidyr)
library(dplyr)
library(janitor)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

############################# Get raw data ####################################################
year <- 2025
data_path <- "~/Desktop/image_count_data_2025.xlsx"
data_raw <- readxl::read_excel(data_path,     
                               col_types = c(rep("text",2),"date",rep("text",22)))


new_data <- data_raw %>%
  clean_names() %>%
  rename("date"="date_of_images", "type"="image_type", "filenames"="image_file_number_s_used",
         "smwh_n"="sm_wht_n","smwh_r"="sm_wht_r") %>%
  pivot_longer(cols = dplyr::contains("_"), 
               names_to = c("species","behavior"),
               names_pattern = "(.*)_(.*)",
               values_to = "count") %>%
  mutate(colony = tolower(gsub(" ","_", colony)),
         type = tolower(type),
         camera = tolower(gsub(" ","_", camera)),
         filenames = gsub(" ","", filenames),
         behavior = ifelse(behavior=="r","roosting","nesting"),
         count = as.numeric(count)) %>%
  filter(!is.na(count)) %>%
  select("date", "colony", "type", "camera", "filenames", "counter", "species", 
         "behavior", "count", "notes")

write.table(new_data, "~/Desktop/image_counts.csv", 
            row.names = FALSE, na = "", sep = ",", quote = c(5,10))
