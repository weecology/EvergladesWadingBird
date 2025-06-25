## Used to clean flight survey data 1994 - 2024 into standard long format
## Done one year at a time, format is different every year
## G. Yenni

library(tidyr)
library(dplyr)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

# All original data files containing flight survey data were pulled into a separate directory
##############################
# Original files: 2 observers, nesting and roosting, 2 sets of comments:

years <- c(2017,2019,2020,2022,2023,2024)
file_names <- c(
  "Flight survey data_2017.xlsx",
  "Flight Survey Data_2019.xlsx",
  "Flight Survey Data_2020.xlsx",
  "Flight survey data_2022.xlsx",
  "Flight survey data_2023.xlsx",
  "Flight_survey data_2024.xlsx")

############################# Get raw data ####################################################
year <- 2024
data_path <- paste("~/Desktop/aerial/",file_names[years==year],sep="")
data_raw <- readxl::read_excel(data_path, 
                               col_names = FALSE,     
                               col_types = c("date",rep("text",42)))

colnames1 <- tolower(as.character(data_raw[1,]))
colnames2 <- tolower(as.character(data_raw[2,]))
colnames1 <-  gsub("[[:punct:][:blank:]]+","", colnames1)
colnames2 <-  gsub("[[:punct:][:blank:]]+","", colnames2)
colnames2[1] <- "date"
colnames1 <- zoo::na.locf(colnames1)
colnames2 <- zoo::na.locf(colnames2)
colnames1[colnames1=="na"] <- colnames2[colnames1=="na"]

colnames <- paste(colnames1, colnames2, sep = "_")
colnames[colnames1==colnames2] <- colnames2[colnames1==colnames2]
colnames[(length(colnames)-1):length(colnames)] <- c("commentsobserver1", "commentsobserver2")

new_data <- data_raw %>%
  setNames(colnames) %>%
  slice(-c(1:2)) %>%
  pivot_longer(cols = dplyr::contains("_"), 
               names_to = c("species","type"),
               names_pattern = "(.*)_(.*)",
               values_to = "count") %>%
  filter(!is.na(count), count!=0) %>%
  separate(col = "type", 
           sep = "obs", 
           into = c("behavior", "obs")) %>%
  mutate(year = year,
         observer = ifelse(obs==1,observer1,observer2),
         notes = ifelse(obs==1,commentsobserver1,commentsobserver2),
         colony = tolower(gsub(" ","_", colony)),
         colony = gsub("[?]", "", colony),
         count = gsub("[?]", "", count),
         count = gsub("+", "", count)) %>%
  rename(colony_old= colonyold,
         start_transect = starttran,
         end_transect = endtran,
         start_time = starttime,
         end_time = endtime,
         photo_sets = surveyphotosets,
         latitude = lat,
         longitude = long) %>%
  mutate(across(c("colony_old","photo_sets","photos"), ~gsub(",","",.))) %>%
  mutate(across(c("colony_old","photo_sets","photos","notes"), ~gsub("\"", "",.))) %>%  
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  mutate(colony = replace(colony, colony == "ganga", "pocket"),
         colony = replace(colony, colony == "nammu", "holiday_park"),
         colony = replace(colony, colony == "vtu", "volta"),
         colony = replace(colony, colony == "potter", "oil_can"),
         colony = replace(colony, colony == "epona", "enlil"),
         colony = replace(colony, colony == "madeira", "race_track"),
         colony = replace(colony, colony == "cuthbert", "cuthbert_lake"),
         colony = replace(colony, colony %in% 
                            c("rodgers_river","roger_river"), "rodgers_river_bay"),
         colony = replace(colony, colony == "lottaman_creek", "lostmans_creek"),
         colony = replace(colony, colony == "grossman", "grossman_ridge_west"),
         colony = replace(colony, colony %in% c("tyr","tyr/lox73","lox_73"), "lox73"),
         colony = replace(colony, colony == "frigg", "robs"),
         colony = replace(colony, colony %in% c("andy_town","andytown"), "nanse"),
         colony = replace(colony, colony == "janus", "jerrod"),
         colony = replace(colony, colony == "echo", "big_pond"),
         colony = replace(colony, colony == "hermes", "lumpy"),
         colony = replace(colony, colony == "forsetti", "forseti"),
         colony = replace(colony, colony == "welden", "weldon"),
         colony = replace(colony, colony %in% c("enil","eponia"), "enlil"),
         colony = replace(colony, colony == "jerod", "jerrod"),
         colony = replace(colony, colony %in% c("starter_mel","mel"), "start_mel"),
         colony = replace(colony, colony %in% c("tam_west","tamiami"), "tamiami_west"),
         colony = replace(colony, colony == "paurotis", "paurotis_pond"),
         colony = replace(colony, colony == "lox_99", "lox99"),
         colony = replace(colony, colony %in% 
                            c("loxramp","lox_ramp/011","loxramp/011",
                              "cook_lox_11","cooklox11","loxramp/11","lox_11"), "lox_ramp"),
         colony = replace(colony, colony %in% c("cook_nc4","loxnc4","cooknc4"), "lox_nc4"),
         colony = replace(colony, colony == "loxwest", "lox_west"),
         colony = replace(colony, colony == "cook_nc3", "lox111"),
         colony = replace(colony, colony == "cooknc2", "vesta"),
         colony = replace(colony, colony %in% c("cook_nc1","cooknc1"), "lox_nc1"),
         colony = replace(colony, colony == "dragon", "dagon"),
         colony = replace(colony, colony == "austere", "auster"),
         colony = replace(colony, colony == "charum", "charun"),
         colony = replace(colony, colony == "yon_teau", "yonteau"),
         colony = replace(colony, colony == "3b_ramp", "3b_boat_ramp"),
         colony = replace(colony, colony == "6", "grant"),
         colony = replace(colony, colony %in% c("bramha","brahmha"), "brahma"),
         colony = replace(colony, colony == "davlin", "dalvin"))  %>%
  select("year","date", "colony", "colony_old", "latitude", "longitude", "start_transect", 
         "end_transect", "start_time", "end_time", "observer", "photo_sets", "photos", "species", 
         "behavior", "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(11,17))

##############################
# Original files: 2 observers, nesting and roosting:

years <- c(2011,2013,2015,2016)
file_names <- c(
  "Data_Flight_Counts_2011.xls",
  "Flight survey data_2013.xls",
  "Flight survey data_2015.xlsx",
  "Flight survey data_2016.xlsx")


############################# Get raw data ####################################################
year <- 2016
data_path <- paste("~/Desktop/aerial/",file_names[years==year],sep="")
data_raw <- readxl::read_excel(data_path, 
                               col_names = FALSE,     
                               col_types = c("date",rep("text",27)))

colnames1 <- tolower(as.character(data_raw[1,]))
colnames2 <- tolower(as.character(data_raw[2,]))
colnames1 <-  gsub("[[:punct:][:blank:]]+","", colnames1)
colnames2 <-  gsub("[[:punct:][:blank:]]+","", colnames2)
colnames2[1] <- "date"
colnames1 <- zoo::na.locf(colnames1)
colnames2 <- zoo::na.locf(colnames2)
colnames1[colnames1=="na"] <- colnames2[colnames1=="na"]

colnames <- paste(colnames1, colnames2, sep = "_")
colnames[colnames1==colnames2] <- colnames2[colnames1==colnames2]
colnames[length(colnames)] <- "notes"

new_data <- data_raw %>%
  setNames(colnames) %>%
  slice(-c(1:2)) %>%
  pivot_longer(cols = dplyr::contains("_"), 
               names_to = c("species","type"),
               names_pattern = "(.*)_(.*)",
               values_to = "count") %>%
  filter(!is.na(count), count!=0) %>%
  separate(col = "type", 
           sep = "obs", 
           into = c("behavior", "obs")) %>%
  mutate(year = year,
         colony = tolower(gsub(" ","_", colony)),
         colony = gsub("[?]", "", colony),
         observer = ifelse(obs==1,observer1,observer2),
         start_time = as.numeric(starttime),
         end_time = as.numeric(endtime)) %>%
  rename(colony_old= colonyold,
         start_transect = starttransect,
         end_transect = endtransect,
         photo_sets = photosets) %>%  
  mutate(across(c("colony_old","photo_sets","photos"), ~gsub(",","",.))) %>%
  mutate(across(c("colony_old","photo_sets","photos"), ~gsub("\"", "",.))) %>%  
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  mutate(colony = replace(colony, colony == "ganga", "pocket"),
         colony = replace(colony, colony == "nammu", "holiday_park"),
         colony = replace(colony, colony == "vtu", "volta"),
         colony = replace(colony, colony == "potter", "oil_can"),
         colony = replace(colony, colony == "epona", "enlil"),
         colony = replace(colony, colony == "madeira", "race_track"),
         colony = replace(colony, colony == "cuthbert", "cuthbert_lake"),
         colony = replace(colony, colony == "rodgers_river", "rodgers_river_bay"),
         colony = replace(colony, colony == "lottaman_creek", "lostmans_creek"),
         colony = replace(colony, colony == "tyr", "lox73"),
         colony = replace(colony, colony == "frigg", "robs"),
         colony = replace(colony, colony %in% c("andy_town","andytown"), "nanse"),
         colony = replace(colony, colony == "janus", "jerrod"),
         colony = replace(colony, colony == "echo", "big_pond"),
         colony = replace(colony, colony == "hermes", "lumpy"),
         colony = replace(colony, colony == "forsetti", "forseti"),
         colony = replace(colony, colony == "welden", "weldon"),
         colony = replace(colony, colony == "enil", "enlil"),
         colony = replace(colony, colony == "jerod", "jerrod"),
         colony = replace(colony, colony == "starter_mel", "start_mel"),
         colony = replace(colony, colony == "paurotis", "paurotis_pond"),
         colony = replace(colony, colony == "lox_99", "lox99"),
         colony = replace(colony, colony == "loxramp", "lox_ramp"),
         colony = replace(colony, colony == "dragon", "dagon"),
         colony = replace(colony, colony == "yon_teau", "yonteau"),
         colony = replace(colony, colony %in% c("bramha","brahmha"), "brahma"),
         colony = replace(colony, colony == "davlin", "dalvin"))  %>%
  select("year","date", "colony", "colony_old", "latitude", "longitude", "start_transect", 
         "end_transect", "start_time", "end_time", "observer", "photo_sets", "photos", "species", 
         "behavior", "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(11,17))

##############################
# Original files: 2 observers:

years <- c(2006,2007,2008,2009)
file_names <- c(
  "Aerial Transect Data 2006.xls",
  "Aerial Transect Data 2007.xls",
  "Aerial Transect Data 2008.xls",
  "Aerial Transect Data 2009.xls")


############################# Get raw data ####################################################
year <- 2009
data_path <- paste("~/Desktop/aerial/",file_names[years==year],sep="")
data_raw <- readxl::read_excel(data_path, 
                               col_names = FALSE,     
                               col_types = c("date",rep("text",37)))

colnames1 <- tolower(as.character(data_raw[1,]))
colnames2 <- tolower(as.character(data_raw[2,]))
colnames1 <-  gsub("[[:punct:][:blank:]]+","", colnames1)
colnames2 <-  gsub("[[:punct:][:blank:]]+","", colnames2)
colnames2[1] <- "date"
colnames1[1:13] <- colnames2[1:13]
colnames1 <- zoo::na.locf(colnames1)

colnames <- paste(colnames1, colnames2, sep = "_")
colnames[1:13] <- colnames2[1:13]
colnames[length(colnames)] <- "notes"

new_data <- data_raw %>%
            setNames(colnames) %>%
            slice(-c(1:2)) %>%
            pivot_longer(cols = dplyr::contains("_"), 
                         names_to = c("species","obs"),
                         names_pattern = "(.*)_(.*)",
                         values_to = "count") %>%
            mutate(year = year,
                   colony = tolower(gsub(" ","_", colony)),
                   colony = gsub("[?]", "", colony),
                   observer = ifelse(obs=="obs1",obs1,obs2),
                   behavior = "nesting") %>%
            filter(!is.na(count), count!=0) %>%
            rename(colony_old= colonyold,
                   start_time= starttime,
                   end_time = endtime,
                   start_transect = starttransect,
                   end_transect = endtransect,
                   photo_sets = photoset,
                   photos = slides) %>%  
            mutate(across(c("colony_old","photo_sets","photos"), ~gsub(",","",.))) %>%
            mutate(across(c("colony_old","photo_sets","photos"), ~gsub("\"", "",.))) %>%
            mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  mutate(colony = replace(colony, colony == "ganga", "pocket"),
         colony = replace(colony, colony == "nammu", "holiday_park"),
         colony = replace(colony, colony == "potter", "oil_can"),
         colony = replace(colony, colony == "epona", "enlil"),
         colony = replace(colony, colony == "tyr", "lox73"),
         colony = replace(colony, colony == "frigg", "robs"),
         colony = replace(colony, colony == "janus", "jerrod"),
         colony = replace(colony, colony == "echo", "big_pond"),
         colony = replace(colony, colony == "hermes", "lumpy"),
         colony = replace(colony, colony == "forsetti", "forseti"),
         colony = replace(colony, colony == "davlin", "dalvin"))  %>%
  select("year","date", "colony","colony_old", "latitude", "longitude", "start_transect", 
         "end_transect", "start_time", "end_time", "observer", "photo_sets", "photos", 
         "species", "behavior", "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(11,17))

flightsurveys_all <- read.csv("Counts/flight_surveys.csv") %>% 
                     distinct() %>%
                     mutate(across(c("year","latitude","longitude","count"), as.numeric),
                            date = as.Date(date)) %>% 
                     arrange(year,date,colony,species)
write.table(flightsurveys_all, "Counts/flight_surveys.csv", 
            row.names = FALSE, na = "", sep = ",", quote = c(11,17))

##############################
# Original files: 1 observer:

years <- c(2004,2005)
file_names <- c(
  "2004 raw survey data all colonies_Found20130128 (Autosaved).xls",
  "Aerial Transect Data 2005.xls")


############################# Get raw data ####################################################
year <- 2005
data_path <- paste("~/Desktop/aerial/",file_names[years==year],sep="")
data_raw <- readxl::read_excel(data_path, 
                               col_names = TRUE,     
                               col_types = c("date",rep("text",25))) %>%
  rename_with(~ tolower(gsub(" ", "_", .x, fixed = TRUE)))

new_data <- data_raw %>%
  pivot_longer(cols = dplyr::contains(species$species), 
               names_to = c("species"),
               values_to = "count") %>%
  filter(!is.na(count), count!=0) %>%
  rename(photos = slides,
         start_transect = start_tran) %>%
  mutate(year = year,
         colony = tolower(gsub(" ","_", colony)),
         colony = gsub("[?]", "", colony),
         start_time = NA,
         end_time = NA,
         behavior = "nesting",
         end_transect = NA,
         photo_sets = NA) %>%
  mutate(across(c("colony_old","photo_sets","photos"), ~gsub(",","",.))) %>%
  mutate(across(c("colony_old","photo_sets","photos"), ~gsub("\"", "",.))) %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  mutate(colony = replace(colony, colony %in% c("3b_mud_east","3b_mud_e"), "mud_east"),
         colony = replace(colony, colony=="false_l-67", "false_l67"),
         colony = replace(colony, colony=="lox_99", "lox99"),
         colony = replace(colony, colony=="l67", "horus"),
         colony = replace(colony, colony=="starter_mel", "hera"),
         colony = replace(colony, colony=="lox_70", "lox70"),
         colony = replace(colony, colony=="lox_111", "lox111"),
         colony = replace(colony, colony=="mud_canal", "heron_alley"),
         colony = replace(colony, colony=="south_jetport", "jetport_south"),
         colony = replace(colony, colony=="tam_e" , "tamiami_east"),
         colony = replace(colony, colony %in% c("tamiami_w","tam_w","tam_west" ), "tamiami_west"),
         colony = replace(colony, colony=="donut", "vulture")) %>%
  select("year","date", "colony", "colony_old", "latitude", "longitude", "start_transect", 
         "end_transect", "start_time", "end_time", "observer", "photo_sets", "photos", 
         "species", "behavior", "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(11,17))
