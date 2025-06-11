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

# All original data files containing ground count data were pulled into a separate directory
##############################
# Original files: 2 observers, nesting and roosting:

years <- c(2011,2013,2015,2016,2017,2018,2019,2022,2023,2024)
file_names <- c(
  "Data_Flight_Counts_2011.xls",
  "Flight survey data_2013.xls",
  "Flight survey data_2015.xlsx",
  "Flight survey data_2016.xlsx",
  "Flight survey data_2017.xlsx",
  "Flight Survey Data_2018.xlsx",
  "Flight Survey Data_2019.xlsx",
  "Flight survey data_2022.xlsx",
  "Flight survey data_2023.xlsx",
  "Flight_survey data_2024.xlsx")


############################# Get raw data ####################################################
year <- 2011
data_path <- paste("~/Desktop/aerial/",file_names[years==year],sep="")
data_raw <- readxl::read_excel(data_path, 
                               col_names = FALSE,     
                               col_types = c("date",rep("text",27)))

colnames1 <- tolower(as.character(data_raw[1,]))
colnames2 <- tolower(as.character(data_raw[2,]))
colnames1 <-  gsub("[[:punct:][:blank:]]+","", colnames1)
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
  mutate(year = year,
         colony = tolower(gsub(" ","_", colony)),
         colony = gsub("[?]", "", colony),
         observer = ifelse(obs==1,observer1,observer2),
         notes = ifelse(obs==1,commentsobserver1,commentsobserver2),
         start_time = as.numeric(starttime),
         end_time = as.numeric(endtime)) %>%
  filter(!is.na(count), count!=0) %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  rename(start_transect = starttran,
         end_transect = endtran,
         photo_sets = surveyphotosets) %>%
  select("year","date", "colony", "latitude", "longitude", "start_transect", "end_transect",	
         "start_time", "end_time", "observer", "photo_sets", "photos", "species", "behavior", 
         "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))

write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(10,11,12,16))

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
                               col_types = c("date",rep("text",36)))

colnames1 <- tolower(as.character(data_raw[1,]))
colnames2 <- tolower(as.character(data_raw[2,]))
colnames1 <-  gsub("[[:punct:][:blank:]]+","", colnames1)
colnames2 <-  gsub("[[:punct:][:blank:]]+","", colnames2)
colnames2[1] <- "date"
colnames1[1:12] <- colnames2[1:12]
colnames1 <- zoo::na.locf(colnames1)

colnames <- paste(colnames1, colnames2, sep = "_")
colnames[1:12] <- colnames2[1:12]
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
            mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
            rename(start_time= starttime,
                   end_time = endtime,
                   start_transect = starttransect,
                   end_transect = endtransect,
                   photo_sets = photoset,
                   photos = slides) %>%
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
  select("year","date", "colony", "latitude", "longitude", "start_transect", "end_transect",	
         "start_time", "end_time", "observer", "photo_sets", "photos", "species", "behavior", 
         "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))


write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(10,11,12,16))

flightsurveys_all <- read.csv("Counts/flight_surveys.csv")
flightsurveys_all <- flightsurveys_all %>% arrange(year) %>% distinct()
write.table(flightsurveys_all, "Counts/flight_surveys.csv", 
            row.names = FALSE,
            na = "", sep = ",", quote = c(10,11,12,16))

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
                               col_types = c("date",rep("text",24))) %>%
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
  select("year","date", "colony", "latitude", "longitude", "start_transect", "end_transect",	
         "start_time", "end_time", "observer", "photo_sets", "photos", "species", "behavior", 
         "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))

write.table(new_data, "Counts/flight_surveys.csv", 
            row.names = FALSE, col.names = FALSE, append = TRUE,
            na = "", sep = ",", quote = c(10,11,12,16))
