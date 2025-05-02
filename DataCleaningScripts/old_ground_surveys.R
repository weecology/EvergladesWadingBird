## Used to clean ground count data 1994 - 2024 into standard long format
## Done one year at a time, format is different every year
## G. Yenni

library(tidyr)
library(dplyr)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

# All original data files containing ground count data were pulled into a separate directory

##############################
# Original files: Wide Format:
       
# "Ground Surveys 2009.xls" 
# "Ground Survey Data 2011.xlsx"       
# "ground survey data 2013.xls"       
# "ground survey data 2014.xlsx"       
# "ground survey data 2015.xlsx"      
# "ground survey data 2017.xlsx"       
# "Ground Survey Data_2019.xlsx"      
# "ground_surveys_2021.xlsx"           
# "ground_surveys_2022.xlsx" 
# "Ground_survey_data_2023.xlsx"       
# "Ground_survey_data_2024.xlsx" 

year <- 2024
data_path <- "~/Desktop/ground/Ground_survey_data_2024.xlsx"

data_raw <- readxl::read_excel("~/Desktop/ground/Ground_survey_data_2024.xlsx", 
                               col_types = c("date", rep("text", 67)))

new_data <- data_raw %>%
            rename_with(~ tolower(gsub(" ", "_", .x, fixed = TRUE))) %>%
            rename("date"="date_of_survey",
                   "transect" = "transect_id", 
                   "direction" = "direction_of_travel",
                   "complete" = "complete?",
                   "field_gps" = "field_gps_#") %>%
            mutate(year = year,
                   colony = tolower(gsub(" ","_", colony)),
                   start_time = as.numeric(start_time)*24,
                   end_time = as.numeric(end_time)*24)



transects <- new_data %>%
             select("date","transect","direction","start_time",
                    "end_time","complete","field_gps","observer_1",
                    "observer_2","start_waypoint","start_latitude","start_longitude",
                    "stop_waypoint","stop_latitude","stop_longitude","colony_waypoint",
                    "colony","latitude","longitude")

%>%
            pivot_longer(cols = dplyr::contains(species$species), 
                         names_to = c("species","type"),
                         names_pattern = "(.*)_(.*)",
                         values_to = "count") 

%>%
            separate(col = "type", 
                     sep = "obs", 
                     into = c("behavior", "obs")) 

%>%
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


##############################
# Original files: Long format: 
# "Ground Surveys 2005.xls"            
# "Ground Surveys 2006.xls" 
# "Ground Survey Data 2007.xls"        
# "Ground Survey Data 2008.xls"

##############################
## Check and write data ##
if(!all(new_data$colony %in% colonies$colony)| 
   !all(new_data$species %in% species$species)) {
  print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
  print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
  
write.table(new_data, "~/Counts/ground_surveys.csv", row.names = FALSE, na = "", sep = ",", quote = 13)   