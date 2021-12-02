#' Functions used to reshape and clean count data from field format
#'

`%>%` <- magrittr::`%>%`

#' Functions customized to old data (-2021)
#'

#' Reshapes and cleans max count data (1994-2021)
#'
#'
#'
#' Reads count data from original excel files, reshapes from wide (dates as cols) to long format,
#' corrects data format errors, appends to long timeseries file

clean_count_data <- function(data_path, year) {
  
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

