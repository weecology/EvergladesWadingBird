#' Functions used to reshape and clean count data from field format
#'

`%>%` <- magrittr::`%>%`
data_path <- "~/Dropbox (UFL)/Everglades/Reports/2019 Reports/SFWMD report table 2019.xlsx"
SFWMD_report_table_2019 <- read_excel("~/Dropbox (UFL)/Everglades/Reports/2019 Reports/SFWMD report table 2019.xlsx", 
                           sheet = "Appendix", skip = 1)

#' Reshapes and cleans max count data (2022->)
#'
#'
#'
#' Reads count data from original excel files, reshapes from wide (dates as cols) to long format,
#' corrects data format errors, appends to long timeseries file
#' 
#' data_path <- "../Dropbox (UFL)/Everglades/2023 Data/2023 Final Report Work/SFWMD Report_Table_2023.xlsx"
#' year <- 2023
clean_count_data <- function(data_path, year) {
  
  colonies <- read.csv("SiteandMethods/colonies.csv")
  species <- read.csv("SiteandMethods/species_list.csv")
  
  tab_names <- readxl::excel_sheets(path = data_path)
  
  data_raw <- readxl::read_excel(path = data_path, sheet = "Appendix", 
                                 col_names = TRUE, col_types = "text", skip=1) %>%
    dplyr::rename_with(tolower) %>%
    dplyr::rename(smda="unid. small dark.") %>%
    dplyr::rename(smwh="unid. small wht.") %>%
    dplyr::rename(lawh="unid. large wht.") %>%
    dplyr::rename(total="*colony total") %>%
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
                  colony = replace(colony, colony=="644", "1573")) %>%
    dplyr::left_join(colonies[,1:2], by = dplyr::join_by(colony))
  
  new_colonies <- data_raw[-which(data_raw$colony %in% colonies$colony),]
  
# only colonies < 40 should be left in new_colonies
    
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
  
  under_40 <- new_colonies %>%
    dplyr::filter(!is.na(latitude)) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(notes = dplyr::case_when(
                          any(dplyr::c_across(greg:anhi)=="***", na.rm = T) ~ "1s indicate presence",
                          TRUE ~ ""))
  under_40[under_40=="***"] <- "1"
  under_40 <- under_40 %>%
    dplyr::mutate_at(3:20,as.numeric) %>%
    dplyr::mutate(year=as.numeric(year), dcco = NA, grhe=NA, smhe=NA, lawh=NA, lada=NA) %>%
    dplyr::select("group_id","year","colony","colony_old","latitude","longitude","wca","greg","whib","wost","gbhe","rosp","sneg","anhi","trhe","bcnh","lbhe","ycnh","glib","caeg","dcco","grhe","smhe","lawh","lada","smda","smwh","notes","total")
    
  return(list(new_data=new_data, new_colonies=new_colonies, under_40=under_40))
}

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

