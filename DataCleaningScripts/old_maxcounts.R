# Reshapes and cleans max count data (2022->2024)
# Reads count data from original excel files, reshapes from wide (dates as cols) to long format,
# corrects data format errors, appends to long timeseries file

`%>%` <- magrittr::`%>%`

############################# Get raw data ####################################################
year <- 2024
data_path <- "~/Desktop/Appendix 2024.xlsx"
SFWMD_report_table_2019 <- readxl::read_excel(data_path, sheet = "Appendix")

############################ Build data tables  #######################################

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))

species <- read.csv("SiteandMethods/species_list.csv")
counts <- read.csv("Counts/maxcounts.csv")
under40 <- read.csv("Counts/maxcounts_under40.csv")

data_raw <- readxl::read_excel(path = data_path, sheet = "Appendix", 
                               col_names = TRUE, col_types = "text") %>%
  dplyr::rename_with(tolower) %>%
  dplyr::mutate(colony_old = colony,
                colony = tolower(colony),
                colony = gsub(" ", "_", colony),
                colony = gsub("/", "_", colony),
                colony = replace(colony, colony %in% c("3b_ramp_80","3b_ramp"), "3b_boat_ramp"),
                colony = replace(colony, colony %in% c("rodgers_river_bay_large_island","rodgers_river_bay_small_island"), "rodgers_river_bay"),
                colony = replace(colony, colony=="grossman_ridge_willowhead", "grossman_willowhead"),
                colony = replace(colony, colony=="austere", "auster"),
                colony = replace(colony, colony=="lox_99", "lox99"),
                colony = replace(colony, colony=="lox_11", "lox11")) %>%
  dplyr::left_join(colonies[,1:2], by = dplyr::join_by(colony))

new_colonies <- data_raw[-which(data_raw$colony %in% colonies$colony),]


######################## Add new colony info to colonies table  ################################

### New colony
# colonies[dim(colonies)[1]+1,]=c(1837,"36","3","3as", 25.974284,	-80.724161,"","36")

### Update colony
# colonies[colonies$colony=="colony13",]$aka="Colony 13, 2019 GREG colony 1"

colonies <- colonies %>%     
  dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude)) %>%
  dplyr::arrange(group_id)
write.table(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = c(7,8))

############################### Shape max count new data ###################################

new_data <- data_raw %>%
  dplyr::select(-c(wca,total,"coordinate notes")) %>%
  dplyr::filter(colony %in% colonies$colony) %>%
  # check for transect waypoints misnamed as colonies
  dplyr::filter(!(colony %in% c("1309", "1380", "1980", "1824", "1351", "1888", "968", 
                                "2013", "2049", "1844", "1882"))) %>%
  tidyr::pivot_longer(cols = !c(group_id,colony,colony_old,latitude,longitude), 
                      names_to = "species",
                      values_to = "count") %>%
  dplyr::mutate(year = year,
                notes = "",
                notes = replace(notes, count=="***", "presence"),
                count = replace(count, count=="***", 1)) %>%
  dplyr::filter(!is.na(count)) %>%
  dplyr::left_join(colonies[,1:2], by = dplyr::join_by(group_id,colony)) %>%
  dplyr::mutate(year = as.numeric(year),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude),
                count = as.numeric(count)) %>%
  dplyr::select("group_id","year","colony","colony_old","latitude","longitude","species","count","notes")

if(!all(new_data$colony %in% colonies$colony)| 
   !all(new_data$species %in% species$species)) {
  print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
  print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
}

############################## Shape under 40 new data  ##############################################
### Only colonies < 40 should be left in new_colonies and no transect numbers should be left
# in new_data

under_40_new <- data_raw %>%
  dplyr::filter(!is.na(latitude),
                !(colony %in% new_data$colony)) %>%
  dplyr::rowwise() %>%
  dplyr::mutate(notes = dplyr::case_when(
    any(dplyr::c_across(greg:anhi)=="***", na.rm = T) ~ "1s indicate presence",
    TRUE ~ ""))
under_40_new[under_40_new=="***"] <- "1"
under_40_new <- under_40_new %>%
  dplyr::mutate(year=as.numeric(year), dcco = NA, smhe=NA, lada=NA, lawh=NA,
                wca = tolower(wca)) %>%
  dplyr::select("group_id","year","colony","colony_old","latitude","longitude","wca","greg","whib","wost","gbhe","rosp","sneg","anhi","trhe","bcnh","lbhe","ycnh","glib","caeg","dcco","grhe","smhe","lawh","lada","smwh","total","notes") %>%
  dplyr::mutate_at(c("group_id","year","latitude","longitude","greg","whib","wost","gbhe","rosp","sneg","anhi","trhe","bcnh","lbhe","ycnh","glib","caeg","dcco","grhe","smhe","lawh","lada","smwh","total"),as.numeric)

################## Move under 40 data to main table for new colonies ###################################
new_colony_list <- c()

############################## Save data ############################################################
counts <- counts %>% dplyr::bind_rows(new_data) %>% dplyr::arrange(year,group_id)
write.table(counts, "Counts/maxcounts.csv", row.names = FALSE, na = "", sep = ",", quote = 9)

under40 <- under40 %>% dplyr::bind_rows(under_40_new) %>% dplyr::arrange(year)
write.table(under40, "Counts/maxcounts_under40.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = 28)  


## Used to clean count data 1994 - 2022 into standard long format
## Done one year at a time, format is different every year
## G. Yenni

source("~/EvergladesWadingBird/DataCleaningScripts/clean_counts.R")
# All original data files containing count data were pulled into a separate directory
# Original files: 
# [1] "2000 appendix.xls"                                              
# [2] "2001 appendix .xls"                                             
# [3] "2002 appendix.xls"                                              
# [4] "2004 appendix.xls"                                              
# [5] "2004 raw survey data all colonies_Found20130128 (Autosaved).xls"
# [6] "94.xlsx"                                                        
# [7] "96appendix.xls"                                                 
# [8] "97colappend.xls"                                                
# [9] "98 appendix.xls"                                                
# [10] "99 Appendix.xls"                                                
# [11] "Aerial Photo Counts 2005.xls"                                   
# [12] "Aerial Photo Counts 2006.xls"                                   
# [13] "Aerial Transect Data 2005.xls"                                  
# [14] "Aerial Transect Data 2006.xls"                                  
# [15] "Aerial Transect Data 2007.xls"                                  
# [16] "Aerial Transect Data 2008.xls"                                  
# [17] "Aerial Transect Data 2009.xls"                                  
# [18] "Alley North drone counts_2019.xlsx"                             
# [19] "Breeding Birds 20031.xls"                                       
# [20] "Flight survey data_2013.xls"                                    
# [21] "Flight survey data_2015.xlsx"                                   
# [22] "Flight survey data_2016.xlsx"                                   
# [23] "Flight survey data_2017.xlsx"                                   
# [24] "Flight Survey Data_2018.xlsx"                                   
# [25] "Ground Survey Data 2007.xls"                                    
# [26] "Ground Survey Data 2008.xls"                                    
# [27] "ground survey data 2013.xls"                                    
# [28] "ground survey data 2014.xlsx"                                   
# [29] "ground survey data 2015.xlsx"                                   
# [30] "ground survey data 2017.xlsx"                                   
# [31] "Ground Survey Data_2019.xlsx"                                   
# [32] "Ground Surveys 2005.xls"                                        
# [33] "Ground Surveys 2006.xls"                                        
# [34] "Ground Surveys 2009.xls"                                        
# [35] "Photo Count Data_2018.xlsx"                                     
# [36] "Photo Counts_2017.xlsx"                                         
# [37] "Picture_Counts_2013.xls"                                        
# [38] "Picture_Counts_2015.xlsx"                                       
# [39] "Picture_Counts_2016.xlsx"  
# [40] "2021_WB PeakCounts_Preliminary.xls"
# [41] "Preliminary Max Counts_2020.xlsx"                        
# [42] "Wading Bird_2019_Final Nest Numbers_working draft.xlsx" 

files <- list.files("~/Downloads/countdata", full.names = TRUE, recursive = TRUE)


dat20 <- clean_count_data(files[41], 2020)
dat21 <- clean_count_data(files[33], 2021)


counts <- counts %>% dplyr::arrange(counts)
write.csv(counts, "Counts/maxcounts.csv", row.names = FALSE, na = "", quote = 9)

species <- species %>% dplyr::arrange(species)
write.csv(species, "SiteandMethods/species_list.csv", row.names = FALSE, na = "", quote = 7:27)

colonies <- colonies %>% dplyr::arrange(colony)
write.csv(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, na = "", quote = c(7,8))

#' Functions customized to old data (-2021)
#'

#' Reshapes and cleans max count data (1994-2021)
#'
#'
#'
#' Reads count data from original excel files, reshapes from wide (dates as cols) to long format,
#' corrects data format errors, appends to long timeseries file

clean_count_data_old <- function(data_path, year) {
  
  colonies <- read.csv("SiteandMethods/colonies.csv")
  species <- read.csv("SiteandMethods/species_list.csv")
  
  tab_names <- readxl::excel_sheets(path = data_path)
  tab_names <- tab_names[tab_names != "key"]
  tab_names <- tab_names[!startsWith(tab_names ,"Other")]
  tab_names <- tab_names[!startsWith(tab_names ,"Overview")]
  tab_names <- tab_names[!startsWith(tab_names ,"Dataset Headers")]
  data_raw <- as.data.frame(lapply(tab_names[1], function(x) readxl::read_excel(path = data_path, sheet = x, 
                                                                                col_names = TRUE, col_types = "text")))
  
  new_data <- data_raw %>%
    dplyr::rename_with(~ tolower(gsub(".", "_", .x, fixed = TRUE))) %>%
    dplyr::rename(type = type_of_count) %>%
    tidyr::pivot_longer(cols = !1:6, 
                        names_to = "species",
                        values_to = "count") %>%
    
    dplyr::mutate(year = year,
                  date = as.Date(as.integer(date), origin="1899-12-30"),
                  notes = "",
                  colony = tolower(colony),
                  colony = gsub(" ", "_", colony),
                  colony = gsub("/.", "_", colony),
                  colony = replace(colony, colony=="6th_bridge_whib", "6th_bridge"),
                  colony = replace(colony, colony=="011_ox_ramp", "lox_ramp_011"),
                  colony = replace(colony, colony=="lox73", "lox_73_tyr"),
                  type = tolower(type),
                  type = replace(type, type == "ground count", "ground"),
                  notes = replace(notes, type=="est. uav", "estimated"),
                  type = replace(type, type=="est. uav", "uav"),
                  notes = replace(notes, count=="***", "presence"),
                  count = replace(count, count=="***", 1),
                  species = replace(species, species %in% c("ani"), "anhi"),
                  species = replace(species, species %in% c("unkn_smwh"), "smwt")) %>%
    
    dplyr::filter(!is.na(count)) %>%
    
    dplyr::mutate(date = as.Date(date),
                  year = as.numeric(year),
                  latitude = as.numeric(latitude),
                  longitude = as.numeric(longitude),
                  count = as.numeric(count)) %>%
    dplyr::select(year, date, colony, wca, latitude, longitude, type, behavior, species, count, notes)
  
  if(!all(new_data$colony %in% colonies$colony)| 
     !all(new_data$species %in% species$species)|
     !all(format(as.Date(new_data$date),"%Y")==year)) {
    print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
    print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
  }
  
  return(new_data)
}
