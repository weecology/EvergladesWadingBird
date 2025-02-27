library(tidyr)
library(dplyr)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

############################# Get raw data ####################################################
year <- 2025
data_path <- "~/Desktop/flight_survey_data_2025.xlsx"
data_raw <- readxl::read_excel(data_path, 
                               col_names = FALSE,     
                               col_types = c("date",rep("text",41)))

colnames1 <- tolower(as.character(data_raw[1,]))
colnames2 <- tolower(as.character(data_raw[2,]))
colnames1 <-  gsub("[[:punct:][:blank:]]+","", colnames1)
colnames1 <-  gsub("smwhite","smwh", colnames1)
colnames2 <-  gsub("[[:punct:][:blank:]]+","", colnames2)
colnames2[1] <- "date"
colnames1[1:9] <- colnames2[1:9]
colnames1 <- zoo::na.locf(colnames1)

colnames <- paste(colnames1, colnames2, sep = "_")
colnames[1:9] <- colnames2[1:9]
colnames[38:42] <- c("photos","commentsobserver1","commentsobserver2","entered","proofed")

new_data <- data_raw %>%
            setNames(colnames) %>%
            slice(-c(1:2)) %>%
            pivot_longer(cols = dplyr::contains("_"), 
                         names_to = c("species","type"),
                         names_pattern = "(.*)_(.*)",
                         values_to = "count") %>%
            separate(col = "type", 
                     sep = "obs", 
                     into = c("behavior", "obs")) %>%
            mutate(colony = tolower(gsub(" ","_", colony)),
                   observer = ifelse(obs==1,observer1,observer2),
                   notes = ifelse(obs==1,commentsobserver1,commentsobserver2),
                   start_time = as.numeric(starttime),
                   end_time = as.numeric(endtime)) %>%
            filter(!is.na(count)) %>%
            rename(start_transect = starttran,
                   end_transect = endtran,
                   photo_sets = surveyphotosets) %>%
            select("date",	"observer",	"colony",	"start_transect",	"end_transect",	"start_time",
                   "end_time",	"photo_sets",	"photos",	"species",	"behavior",	"count",	"notes",
                   "entered",	"proofed")

write.table(new_data, "~/Desktop/flight_surveys.csv", row.names = FALSE, na = "", sep = ",", quote = 13) 
