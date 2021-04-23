## Used to clean nest check data 1994 - 2020 into standard long format
## G. Yenni 2020-08

source("~/EvergladesWadingBird/DataCleaningScripts/clean_nest_checks.R")
# All original data files containing nest check data were pulled into a separate directory
# Original files: 
# [1] "2004 raw survey data all colonies_Found20130128 (Autosaved).xls"
# [2] "2018NestChecks.xlsx"                                            
# [3] "nest check 2010 raw only.xlsx"                                  
# [4] "nest check 2011.xlsx"                                           
# [5] "nest check 2012.xlsx"                                           
# [6] "Nest Check Data_2019.xlsx"                                      
# [7] "Nest Check Data_2020.xlsx"                                      
# [8] "nest check original data 2013.xls"                              
# [9] "nest check original data 2014.xlsm"                             
# [10] "nest check original data 2015.xlsx"                             
# [11] "nest check original data 2016_QAQC.xlsx"                        
# [12] "nest check original data 2017_QAQC_JZ.xlsx"                     
# [13] "Nest Checks 2005 11-22 KAW UPDATE.xls"                          
# [14] "Nest Checks 2005.xls"                                           
# [15] "Nest Checks 2006.xls"                                           
# [16] "Nest Checks 2009.xls"                                           
# [17] "nest data 1994.xlsx"                                            
# [18] "Nest data 2002.xlsx"                                            
# [19] "nest data 2003.xlsx"  
files <- list.files("~/Downloads/nestdata", full.names = TRUE)
years <- c(2004, 2018, 2010, 2011, 2012, 2019, 2020, 2013, 2014, 2015, 2016, 2017, 2005, 2005, 2006, 
           2009, 1994, 2002, 2003)

new94 <- clean_nest_data(files[13], years[13])

new02 <- clean_nest_data(files[14], years[14])

new03 <- clean_nest_data(files[15], years[15])

### 2004 and 2005 are single sheets
### 2004 data
tab_names04 <- readxl::excel_sheets(path = files[1])
new04 <- readxl::read_excel(path = files[1], sheet = tab_names04[2], col_names = TRUE)[,1:103] %>%
  tidyr::drop_na("Nest #") %>%
  dplyr::rename(nest = "Nest #", colony = Colony, species = Species) %>%
  dplyr::mutate_all(as.character) %>%
  dplyr::mutate(colony = tolower(colony),
                colony = gsub(" ", "_", colony),
                colony = gsub("/.", "_", colony),
                colony = gsub("-", "_", colony),
                species = tolower(species),
                year = 2004,
                species = replace(species, species=="tric", "trhe"),
                species = replace(species, species=="?", "unkn")) %>%
  dplyr::group_by(nest, colony, species) %>%
  tidyr::pivot_longer(cols = dplyr::starts_with("3"),
                      names_to = "date",
                      values_to = "notes") %>%
  dplyr::mutate(date = as.Date(as.integer(date), origin="1899-12-30"),
                eggs = as.numeric(gsub("E", "", stringr::str_extract(notes, "(\\d+)E"))),
                chicks = as.numeric(gsub("C", "", stringr::str_extract(notes, "(\\d+)[C]")))) %>%
  dplyr::select(year, colony, nest, species, date, eggs, chicks, notes)

### 2005 data
tab_names05 <- readxl::excel_sheets(path = files[9])
new05 <- readxl::read_excel(path = files[9], sheet = tab_names05[1], col_names = TRUE, skip = 1) %>%
  dplyr::select(-c("Nest Fate", "Cause of Failure", "# Fledged", "Transect", "...12")) %>%
  dplyr::rename(nest = "Nest #", colony = Colony, species = Species, date = Date,
                eggs = "# Eggs", chicks = "# Chicks", notes = Comments) %>%
  dplyr::mutate_all(as.character) %>%
  dplyr::mutate(colony = tolower(colony),
                colony = gsub(" ", "_", colony),
                colony = gsub("/.", "_", colony),
                colony = gsub("-", "_", colony),
                species = tolower(species),
                year = 2005,
                species = replace(species, species=="tric", "trhe"),
                species = replace(species, species=="?", "unkn"),
                eggs = replace(eggs, eggs=="?", 0),
                eggs = as.numeric(eggs),
                chicks = as.numeric(chicks), 
                date = as.Date(date, origin="1899-12-30")) %>%
  dplyr::select(year, colony, nest, species, date, eggs, chicks, notes)

## Add weird 2006 and 2009 data
new06 <- extra_nest_data(files[11], years[11])

new09 <- extra_nest_data(files[12], years[12])

old_data <- old_data %>%
  dplyr::mutate(date = as.Date(date),
                eggs = as.numeric(eggs),
                chicks = as.numeric(chicks)) %>%
  dplyr::bind_rows(new06, new09)

### 2013 - 2019

new13 <- clean_nest_data(files[4], years[4])

new14 <- clean_nest_data(files[5], years[5])

new15 <- clean_nest_data(files[6], years[6])

new16 <- clean_nest_data(files[7], years[7])

new17 <- clean_nest_data(files[8], years[8])
# several multispecies renests need to be correctly identified
new17$species[(new17$species=="whib then smhe") & (new17$date<="2017-03-17")] = "whib"
new17$species[(new17$species=="whib then smhe") & (new17$date>"2017-03-17")] = "smhe"
new17$species[(new17$species=="bcnh then smhe") & (new17$date<="2017-03-17")] = "bcnh"
new17$species[(new17$species=="bcnh then smhe") & (new17$date>"2017-03-17")] = "smhe"
new17$species[(new17$species=="bcnh then greg?")] = "bcnh"
# it's complicated
new17$chicks[which(new17$date=="2017-04-21" & new17$nest=="744")] = 2

new18 <- clean_nest_data(files[2], years[2])

new19 <- clean_nest_data(files[3], years[3])


write.csv(nests, "Nesting/nest_checks.csv", row.names = FALSE, na = "", quote = 8)

species <- species %>% dplyr::arrange(species)
write.csv(species, "SiteandMethods/species_list.csv", row.names = FALSE, na = "", quote = 5:25)

colonies <- colonies %>% dplyr::arrange(wca,colony)
write.csv(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, na = "", quote = FALSE)
