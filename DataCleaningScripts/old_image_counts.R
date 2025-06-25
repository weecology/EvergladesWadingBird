## Used to clean image count data 1994 - 2024 into standard long format
## G. Yenni

library(tidyr)
library(dplyr)
library(janitor)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

imagecounts_all <- read.csv("Counts/image_counts.csv") %>% 
                   distinct() %>%
                   mutate(across(c("year","latitude","longitude","count"), as.numeric),
                          date = as.Date(date)) %>% 
                   arrange(year,date,colony,species)
write.table(imagecounts_all, "Counts/image_counts.csv", row.names = FALSE,
            na = "", sep = ",", quote = c(9,14))

############################################################################################
# All original data files containing image count data were pulled into a separate directory

years <- c(2004:2009,2011,2013,2015:2020,2022:2024)
file_names <- c(
  "2004 raw survey data all colonies_Found20130128 (Autosaved).xls",
  "Aerial Photo Counts 2005.xls",
  "Aerial Photo Counts 2006.xls",
  "Aerial Transect Data 2007.xls",
  "Aerial Transect Data 2008.xls",
  "Aerial Transect Data 2009.xls",
  "Picture Counts_2011.xlsx",
  "Picture_Counts_2013.xls",
  "Picture_Counts_2015.xlsx",
  "Picture_Counts_2016.xlsx",
  "Photo Counts_2017_New.xlsx",
  "Photo Count Data_2018.xlsx",
  "Photo Count Data_2019.xlsx",
  "Photo Count Data_2020.xlsx",
  "Image_Counts_2022 (Current).xlsx",
  "Image_count_data_2023.xlsx",
  "Image_count_data_2024.xlsx"
)

#################################################################################
# Years 2011-2024: nesting and roosting
year <- 2024
data_path <- paste("~/Desktop/photos/",file_names[years==year],sep="")

data_raw <- readxl::read_excel(data_path, 
                               col_names = FALSE,     
                               col_types = c("date",rep("text",35)))

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
               names_to = c("species","behavior"),
               names_pattern = "(.*)_(.*)",
               values_to = "count") %>%
  mutate(year = year,
         type = tolower(type),
         filenames = gsub(" ","", filenames),
         colony = gsub("\\.","", colony),
         colony = gsub("/"," ", colony)) %>%
  rename(colony_old = colonyold) %>%
  mutate(across(c("colony","camera"), ~tolower(gsub(" ","_",.)))) %>%
  mutate(across(c("colony","count"), ~gsub("[?]", "",.))) %>%
  mutate(across(c("colony_old","counter"), ~gsub(",","",.))) %>%
  mutate(across(c("colony_old","filenames","counter","notes"), ~gsub("\"", "",.))) %>%
  mutate(across(c("colony","colony_old","filenames","counter","notes"), 
                                                   ~trimws(gsub("\\s+", " ", .)))) %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  filter(!is.na(count), count!=0) %>%
  mutate(colony = replace(colony, colony %in% 
                            c("3b_mud_east","3b_mud_e","3bme","3b_mude","3bmude"), "mud_east"),
         colony = replace(colony, colony %in% 
                            c("3b_ramp","3b_ramp_080","3b_ramp_80"), "3b_boat_ramp"),
         colony = replace(colony, colony=="false_l-67", "false_l67"),
         colony = replace(colony, colony=="big_melaleuca", "big_mel"),
         colony = replace(colony, colony=="lox_99", "lox99"),
         colony = replace(colony, colony %in% c("cooklox11","cook_lox11","lox_11"), "lox11"),
         colony = replace(colony, colony=="l67", "horus"),
         colony = replace(colony, colony %in% c("7th_bridge","6th_br"), "6th_bridge"),
         colony = replace(colony, colony %in% c("alley_n","ally_north"), "alley_north"),
         colony = replace(colony, colony %in% c("paurotis","paroutis"), "paurotis_pond"),
         colony = replace(colony, colony=="2b_melaleuca", "melaleuca_2b"),
         colony = replace(colony, colony=="starter_mel", "hera"),
         colony = replace(colony, colony=="lox_70", "lox70"),
         colony = replace(colony, colony == "vtu", "volta"),
         colony = replace(colony, colony=="lox_111", "lox111"),
         colony = replace(colony, colony=="mud_canal", "heron_alley"),
         colony = replace(colony, colony == "yon_teau", "yonteau"),
         colony = replace(colony, colony %in% c("loxramp","loxramp_11","loxramp_011"), "lox_ramp"),
         colony = replace(colony, colony == "madeira", "race_track"),
         colony = replace(colony, colony == "mel", "melaleuca"),
         colony = replace(colony, colony == "cuthbert", "cuthbert_lake"),
         colony = replace(colony, colony == "colony_18", "18"),
         colony = replace(colony, colony %in% c("38","185"), "38_185"),
         colony = replace(colony, colony %in% c("6","006"), "63"),
         colony = replace(colony, colony=="104_56", "3667"),
         colony = replace(colony, colony %in% c("13","013"), "colony13"),
         colony = replace(colony, colony == "138", "1092"),
         colony = replace(colony, colony %in% c("bramha","brahmha"), "brahma"),
         colony = replace(colony, colony %in% c("andy_town","andytown"), "nanse"),
         colony = replace(colony, colony %in% c("loxwest","lox_w"), "lox_west"),
         colony = replace(colony, colony %in% 
                  c("new_colony_2","new_col_2","cooknc2","nc2","newcol2","new_col2"),"vesta"),
         colony = replace(colony, colony %in% 
                            c("south_jetport","jet_port_south","jetport_s"), "jetport_south"),
         colony = replace(colony, colony %in% c("epona","enil","enul","enlil_epona"), "enlil"),
         colony = replace(colony, colony == "oden", "odin"),
         colony = replace(colony, colony == "frigg", "robs"),
         colony = replace(colony, colony == "janus", "jerrod"),
         colony = replace(colony, colony == "ganga", "pocket"),
         colony = replace(colony, colony %in% 
                            c("rodgers_river","roger_river"), "rodgers_river_bay"),
         colony = replace(colony, colony %in% 
                            c("tyr","tyr_lox73","lox_73","lox73_tyr",
                              "tyr_lox_73","lox_73_tyr","cook_lox73"), "lox73"),
         colony = replace(colony, colony == "echo", "big_pond"),
         colony = replace(colony, colony == "potter", "oil_can"),
         colony = replace(colony, colony == "ymir", "yamir"),
         colony = replace(colony, colony == "grossman", "grossman_ridge_west"),
         colony = replace(colony, colony == "austere", "auster"),
         colony = replace(colony, colony == "hermes", "lumpy"),
         colony = replace(colony, colony == "davlin", "dalvin"),
         colony = replace(colony, colony == "nammu", "holiday_park"),
         colony = replace(colony, colony == "welden", "weldon"),
         colony = replace(colony, colony %in% c("forsetti","forceti"), "forseti"),
         colony = replace(colony, colony %in% c("cook_nc4","loxnc4","cooknc4"), "lox_nc4"),
         colony = replace(colony, colony %in% c("cook_nc1","cooknc1"), "lox_nc1"),
         colony = replace(colony, colony %in% c("cooknc3","cook_nc3"), "lox111"),
         colony = replace(colony, colony %in% 
               c("rodgers_river","roger_river","rodg_riv_by","rogers_river"), "rodgers_river_bay"),
         colony = replace(colony, colony %in% 
                            c("tam_e","tam_e,_e","tam_e,e","tami_ee","tami_ew"), "tamiami_east"),
         colony = replace(colony, colony %in% 
                  c("tamiami_w","tam_w","tam_west","tami_w","tw","tamwest"), "tamiami_west"),
         colony = replace(colony, colony %in% 
                  c("donut","donut_vulture","vulture_donut","vulture_007","007"), "vulture")) %>%
  select("year", "date", "colony", "colony_old", "latitude", "longitude", "type", "camera", 
         "filenames", "counter", "species", "behavior", "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/image_counts.csv", row.names = FALSE, col.names = FALSE, 
            append = TRUE, na = "", sep = ",", quote = c(9,14))

#################################################################################
# Years 2004-2009: only nesting
year <- 2009
data_path <- paste("~/Desktop/photos/",file_names[years==year],sep="")

data_raw <- readxl::read_excel(data_path, 
                               col_names = TRUE,     
                               col_types = c("date",rep("text",25))) %>%
  rename_with(~ tolower(gsub(" ", "_", .x, fixed = TRUE)))

new_data <- data_raw %>%
  clean_names() %>%
  pivot_longer(cols = dplyr::contains(species$species), 
               names_to = c("species"),
               values_to = "count") %>%
  mutate(year = year,
         type = tolower(type),
         filenames = gsub(" ","", filenames),
         behavior = "nesting") %>%
  mutate(across(c("colony","camera"), ~tolower(gsub(" ","_",.)))) %>%
  mutate(across(c("colony","count"), ~gsub("[?]", "",.))) %>%
  mutate(across(c("colony_old","counter"), ~gsub(",","",.))) %>%
  mutate(across(c("colony_old","filenames","counter","notes"), ~gsub("\"", "",.))) %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric)) %>%
  filter(!is.na(count), count!=0) %>%
  mutate(colony = replace(colony, colony %in% c("3b_mud_east","3b_mud_e","3bme"), "mud_east"),
         colony = replace(colony, colony=="false_l-67", "false_l67"),
         colony = replace(colony, colony=="big_melaleuca", "big_mel"),
         colony = replace(colony, colony=="lox_99", "lox99"),
         colony = replace(colony, colony=="l67", "horus"),
         colony = replace(colony, colony %in% c("7th_bridge","6th_br"), "6th_bridge"),
         colony = replace(colony, colony %in% c("alley_n","ally_north"), "alley_north"),
         colony = replace(colony, colony %in% c("paurotis","paroutis"), "paurotis_pond"),
         colony = replace(colony, colony=="2b_melaleuca", "melaleuca_2b"),
         colony = replace(colony, colony=="starter_mel", "hera"),
         colony = replace(colony, colony=="lox_70", "lox70"),
         colony = replace(colony, colony=="lox_111", "lox111"),
         colony = replace(colony, colony=="mud_canal", "heron_alley"),
         colony = replace(colony, colony %in% c("south_jetport","jet_port_south"), "jetport_south"),
         colony = replace(colony, colony == "epona", "enlil"),
         colony = replace(colony, colony == "frigg", "robs"),
         colony = replace(colony, colony == "janus", "jerrod"),
         colony = replace(colony, colony == "ganga", "pocket"),
         colony = replace(colony, colony == "tyr", "lox73"),
         colony = replace(colony, colony == "echo", "big_pond"),
         colony = replace(colony, colony == "potter", "oil_can"),
         colony = replace(colony, colony == "hermes", "lumpy"),
         colony = replace(colony, colony == "davlin", "dalvin"),
         colony = replace(colony, colony == "nammu", "holiday_park"),
         colony = replace(colony, colony == "welden", "weldon"),
         colony = replace(colony, colony %in% c("forsetti","forceti"), "forseti"),
         colony = replace(colony, colony %in% c("cook_nc4","loxnc4","cooknc4"), "lox_nc4"),
         colony = replace(colony, colony %in% 
                            c("rodgers_river","roger_river","rodg_riv_by"), "rodgers_river_bay"),
         colony = replace(colony, colony %in% 
                            c("tam_e","tam_e,_e","tam_e,e","tami_ee","tami_ew"), "tamiami_east"),
         colony = replace(colony, colony %in% 
                            c("tamiami_w","tam_w","tam_west","tami_w"), "tamiami_west"),
         colony = replace(colony, colony %in% c("donut","donut/vulture"), "vulture"),
         behavior = replace(behavior, notes %in% 
                              c("not nesting","Includes ~75% young"), "roosting")) %>%
  select("year", "date", "colony", "colony_old", "latitude", "longitude", "type", "camera", 
         "filenames", "counter", "species", "behavior", "count", "notes")

print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
print(unique(new_data$year[which(!(lubridate::year(new_data$date) == new_data$year))]))

write.table(new_data, "Counts/image_counts.csv", row.names = FALSE, col.names = FALSE, 
            append = TRUE, na = "", sep = ",", quote = c(9,14))
