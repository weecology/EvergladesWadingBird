## Clean ground survey data and append to datasets

library(tidyr)
library(dplyr)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")

ground_counts_all <- read.csv("Counts/ground_counts.csv")
transects_all <- read.csv("Counts/ground_transects.csv")

# Define transect boundaries
lat_max = 26.146679
lat_min = 25.761435
long_max = -80.670633
long_min = -80.827668

# Add flag for locations outside transects

ground_counts <- ground_counts_all %>%
                 mutate(standard_survey = 1,
                        longitude = ifelse(longitude>0,-longitude,longitude)) %>%
                 mutate(standard_survey = ifelse(latitude>lat_max,0,standard_survey),
                        standard_survey = ifelse(latitude<lat_min,0,standard_survey),
                        standard_survey = ifelse(longitude>long_max,0,standard_survey),
                        standard_survey = ifelse(longitude<long_min,0,standard_survey),
                        standard_survey = ifelse(date %in% 
                      c("2006-03-21","2006-03-30","2006-03-22","2006-03-23"),0,standard_survey)) %>%
  select("year","date","transect","colony_waypoint","colony","latitude","longitude",
         "species","count","nests","chicks","standard_survey","notes") 

probs = ground_counts %>% filter(standard_survey==0)

transects <- transects_all %>%
  mutate(standard_survey = 1,
         longitude = ifelse(longitude>0,-longitude,longitude)) %>%
  mutate(standard_survey = ifelse(latitude>lat_max,0,standard_survey),
         standard_survey = ifelse(latitude<lat_min,0,standard_survey),
         standard_survey = ifelse(longitude>long_max,0,standard_survey),
         standard_survey = ifelse(longitude<long_min,0,standard_survey),
         standard_survey = ifelse(date %in% 
                  c("2006-03-21","2006-03-30","2006-03-22","2006-03-23"),0,standard_survey)) %>%
  select("year","date","transect","direction","start_time",
         "end_time","complete","field_gps","observer_1",
         "observer_2","start_waypoint","start_latitude","start_longitude",
         "stop_waypoint","stop_latitude","stop_longitude","colony_waypoint",
         "colony","latitude","longitude","standard_survey","notes")

tprobs = transects %>% filter(standard_survey==0)
t2006 = transects %>% filter(year==2006) %>%
        mutate(month=lubridate::month(date))

plot(t2006$longitude,t2006$latitude,col=t2006$month)
counts_2006 = ground_counts %>% filter(year==2006) %>%
  mutate(month=lubridate::month(date))
plot(as.Date(counts_2006$date),counts_2006$count)
sum(counts_2006$count[which(counts_2006$month==3)],na.rm=TRUE)
sum(counts_2006$count[which(counts_2006$month==5)],na.rm=TRUE)

# Corrections
# long -855.83333 should be 11 N
ground_counts[3479:3480,"longitude"] = -80.77167
ground_counts[3479:3480,"standard_survey"] = 1
transects[2355,"longitude"] = -80.77167
transects[2355,"standard_survey"] = 1

# long -855.18333 should be 11 N
ground_counts[3481,"longitude"] = -80.77167
ground_counts[3481,"standard_survey"] = 1
transects[2356,"longitude"] = -80.77167
transects[2356,"standard_survey"] = 1

# I think these high foraging counts were removed
ground_counts[c(2639,2632),"standard_survey"] = 0

write.table(ground_counts, "Counts/ground_counts.csv", 
            row.names = FALSE, col.names = TRUE, na = "", sep = ",", quote = 13)
write.table(transects, "Counts/ground_transects.csv", 
            row.names = FALSE, col.names = TRUE, na = "", sep = ",", quote = 22)
############################# Get raw data #########################################
new_year <- 2025

filepath <- "~/UFL Dropbox/Glenda Yenni/Everglades/2025 Data/Field Data/Clean data/"

transects <- data_raw %>%
  select("year","date","transect","direction","start_time",
         "end_time","complete","field_gps","observer_1",
         "observer_2","start_waypoint","start_latitude","start_longitude",
         "stop_waypoint","stop_latitude","stop_longitude","colony_waypoint",
         "colony","latitude","longitude","standard_survey","notes") %>%
  mutate(across(c("year","start_time","end_time","start_latitude","start_longitude",
                  "stop_latitude","stop_longitude","latitude","longitude"), as.numeric))

ground_counts <- data_raw %>%
  select(-c("direction","start_time",
            "end_time","complete","field_gps","observer_1",
            "observer_2","start_waypoint","start_latitude","start_longitude",
            "stop_waypoint","stop_latitude","stop_longitude")) %>%
  mutate(across(c("year","latitude","longitude","count","nests","chicks"), as.numeric)) %>%
  mutate(species = tolower(species)) %>%
  mutate(species = replace(species, species=="tche","trhe")) %>%
  select("year","date","transect","colony_waypoint","colony","latitude","longitude",
         "species","count","nests","chicks","standard_survey","notes") 

## Check and write data ##
if(!all(ground_counts$colony %in% colonies$colony)| 
   !all(ground_counts$species %in% species$species)|
   !all(lubridate::year(ground_counts$date)==ground_counts$year)) {
  print(unique(ground_counts$colony[which(!(ground_counts$colony %in% colonies$colony))]))
  print(unique(ground_counts$species[which(!(ground_counts$species %in% species$species))]))
  print(unique(ground_counts$year[which(!(lubridate::year(ground_counts$date) == ground_counts$year))]))
}

write.table(ground_counts, "Counts/ground_counts.csv", 
            row.names = FALSE, col.names = FALSE, append=TRUE, na = "", sep = ",", quote = 13)
write.table(transects, "Counts/ground_transects.csv", 
            row.names = FALSE, col.names = FALSE, append=TRUE, na = "", sep = ",", quote = 22)
