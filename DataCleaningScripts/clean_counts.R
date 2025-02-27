# Reshapes and cleans max count data (2022->)
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

############################## Add ENP data ############################################################
  ############################# Get raw data ####################################################
  datayear <- 2024
  data_path <- "~/Desktop/ENP wading bird peak nest numbers_2024.xlsx"
  
  ############################ Build data tables  #######################################
  
  colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
    dplyr::mutate(group_id = as.numeric(group_id),
                  latitude = as.numeric(latitude),
                  longitude = as.numeric(longitude))
  
  species <- read.csv("SiteandMethods/species_list.csv")
  counts <- read.csv("Counts/maxcounts.csv")
  
  enp_data <- readxl::read_excel(data_path, sheet = 1, skip = 1, col_types = "text") %>%
    dplyr::rename_with(tolower) %>%
    dplyr::select(-total) %>%
    dplyr::mutate(colony_old = colony,
                  colony = tolower(colony),
                  colony = gsub(" ", "_", colony),
                  colony = gsub("/", "_", colony),
                  colony = replace(colony, colony=="colony_13", "colony13"),
                  colony = replace(colony, colony=="colony_14", "colony14"),
                  colony = replace(colony, colony=="colony_15", "colony15"),
                  colony = replace(colony, colony=="shark_valley_observation_tower", "shark_valley"),
                  colony = replace(colony, colony=="shark_valley_tram_road_nw", "shark_valley_tram"),
                  colony = replace(colony, colony=="shark_river_slough_se", "shark_river_slough"),
                  colony = replace(colony, colony %in% c("rodgers_river_bay_large_island","rodgers_river_bay_small_island"), "rodgers_river_bay"),
                  colony = replace(colony, colony=="grossman_ridge_willowhead", "grossman_willowhead")) %>%
    dplyr::left_join(colonies[,1:2], by = dplyr::join_by(colony)) %>%
    tidyr::pivot_longer(cols = !c(group_id,colony,colony_old,latitude,longitude), 
                        names_to = "species",
                        values_to = "count") %>%
    dplyr::mutate(year = datayear,
                  notes = "",
                  notes = replace(notes, count=="+", "present and nesting but numbers unknown"),
                  count = replace(count, count=="+", 1)) %>%
    dplyr::filter(!is.na(count)) %>%
    dplyr::mutate(year = as.numeric(year),
                  latitude = as.numeric(latitude),
                  longitude = as.numeric(longitude),
                  count = as.numeric(count)) %>%
    dplyr::select("group_id","year","colony","colony_old","latitude","longitude","species","count","notes")
  
  if(!all(enp_data$colony %in% colonies$colony)| 
     !all(enp_data$species %in% species$species)) {
    print(unique(enp_data$colony[which(!(enp_data$colony %in% colonies$colony))]))
    print(unique(enp_data$species[which(!(enp_data$species %in% species$species))]))
  }
  
  ### Write
  counts <- counts %>% dplyr::bind_rows(enp_data) %>% dplyr::arrange(year,group_id)
  write.table(counts, "Counts/maxcounts.csv", row.names = FALSE, na = "", sep = ",", quote = 9)  
   