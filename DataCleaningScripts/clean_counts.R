# Reshapes and cleans max count data (2022->)
# Reads count data from original excel files, reshapes from wide (dates as cols) to long format,
# corrects data format errors, appends to long timeseries file

`%>%` <- magrittr::`%>%`

############################# Get raw data ####################################################
year <- 2019
data_path <- "~/Dropbox (UFL)/Everglades/Reports/2019 Reports/SFWMD report table 2019.xlsx"
data_path <- "~/Desktop/maxcount_2019.xlsx"
SFWMD_report_table_2019 <- readxl::read_excel(data_path, sheet = "Appendix", skip = 1)

############################ Build data tables  #######################################

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
            dplyr::mutate(group_id = as.numeric(group_id),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude))
  
species <- read.csv("SiteandMethods/species_list.csv")
counts <- read.csv("Counts/maxcounts.csv")
under40 <- read.csv("Counts/maxcounts_under40.csv")
  
  tab_names <- readxl::excel_sheets(path = data_path)
  
  data_raw <- readxl::read_excel(path = data_path, sheet = "Appendix", 
                                 col_names = TRUE, col_types = "text", skip=1) %>%
    dplyr::rename_with(tolower) %>%
    dplyr::rename(smda="unid. small dark.") %>%
    dplyr::rename(smwh="unid. small wht.") %>%
    dplyr::rename(lawh="unid. large wht.") %>%
    dplyr::mutate(colony_old = colony,
                  colony = tolower(colony),
                  colony = gsub(" ", "_", colony),
                  colony = gsub("/", "_", colony),
                  colony = replace(colony, colony %in% c("63_no_name","63_006"), "63"),
                  colony = replace(colony, colony %in% c("71_canal_junction","71"), "canal_junction"),
                  colony = replace(colony, colony=="78_canal_north", "canal_north"),
                  colony = replace(colony, colony %in% c("3b_ramp_80","3b_ramp"), "3b_boat_ramp"),
                  colony = replace(colony, colony=="89_venus", "venus"),
                  colony = replace(colony, colony=="austere", "auster"),
                  colony = replace(colony, colony %in% c("cooklox11", "cooknc3"), "lox111"),
                  colony = replace(colony, colony=="cooknc4", "lox_nc4"),
                  colony = replace(colony, colony=="enlil_epona", "enlil"),
                  colony = replace(colony, colony=="jetport_new_64", "jetport_new"),
                  colony = replace(colony, colony=="loxwest", "lox_west"),
                  colony = replace(colony, colony=="cooknc1(77_78)", "lox_nc1"),
                  colony = replace(colony, colony=="cooknc2(76)", "vesta"),
                  colony = replace(colony, colony=="loxramp_011", "lox_ramp"),
                  colony = replace(colony, colony %in% c("tyr_lox73","tyr", "lox73_tyr"), "lox73"),
                  colony = replace(colony, colony=="vulture_007", "vulture"),
                  colony = replace(colony, colony=="1219_draco", "draco"),
                  colony = replace(colony, colony=="990_frodo", "frodo"),
                  colony = replace(colony, colony=="38", "38_185"),
                  colony = replace(colony, colony %in% c("51", "51_juno"), "juno"),
                  colony = replace(colony, colony=="lox11", "outer_lox111_south"),
                  colony = replace(colony, colony=="little_d_little_a", "little_a"),
                  colony = replace(colony, colony=="112", "3665"),
                  colony = replace(colony, colony %in% c("1362", "739", "487"), "col487"),
                  colony = replace(colony, colony %in% c("1470","576", "98"), "1888"),
                  colony = replace(colony, colony %in% c("1379", "766_57_nc_2018"), "1824"),
                  colony = replace(colony, colony=="14", "1351"),
                  colony = replace(colony, colony=="75", "3700"),
                  colony = replace(colony, colony=="610_67_nc_2018", "67"),
                  colony = replace(colony, colony=="644", "1573"),
                  colony = replace(colony, colony=="2019_greg_colony_1", "colony13"),
                  colony = replace(colony, colony %in% c("rodgers_river_bay_large_island","rodgers_river_bay_small_island"), "rodgers_river_bay"),
                  colony = replace(colony, colony=="grossman_ridge_willowhead", "grossman_willowhead")) %>%
    dplyr::left_join(colonies[,1:2], by = dplyr::join_by(colony))
  
  new_colonies <- data_raw[-which(data_raw$colony %in% colonies$colony),]
  

  ######################## Add new colony info to colonies table  ################################
  
  ### New colony
  # colonies[dim(colonies)[1]+1,]=c(max(colonies$group_id,na.rm=T) + 1,
  # "colony","region","subregion",latitude,longitude,"aka","Display Name")
  
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
    dplyr::select(-c(wca,total)) %>%
    dplyr::filter(colony %in% colonies$colony) %>%
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
### Only colonies < 40 should be left in new_colonies
  
  under_40_new <- new_colonies %>%
    dplyr::filter(!is.na(latitude)) %>%
    dplyr::select(-"smda") %>%
    dplyr::rowwise() %>%
    dplyr::mutate(notes = dplyr::case_when(
                          any(dplyr::c_across(greg:anhi)=="***", na.rm = T) ~ "1s indicate presence",
                          TRUE ~ ""))
  under_40_new[under_40_new=="***"] <- "1"
  under_40_new <- under_40_new %>%
    dplyr::mutate(year=as.numeric(year), dcco = NA, smhe=NA, lada=NA) %>%
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
  