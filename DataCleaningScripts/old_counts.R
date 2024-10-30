## Used to clean count data 1994 - 2020 into standard long format
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
