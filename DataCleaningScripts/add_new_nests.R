# Clean and append new nest check data 

source('DataCleaningScripts/clean_nest_checks.R')
colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")
nest_checks <- read.csv("Nesting/nest_checks.csv")

filepath <- "~/UFL Dropbox/Glenda Yenni/Everglades/2025 Data/Field Data/Clean data/"
filename <- "FINAL_nest_checks_2025_UPDATED.xlsx"

year <- 2025

newdata <- clean_nest_data(paste(filepath,filename,sep=""), year)

all(lubridate::year(newdata$date)==year)
print(unique(newdata$colony[which(!(newdata$colony %in% colonies$colony))]))
print(unique(newdata$species[which(!(newdata$species %in% species$species))]))
all(colnames(newdata)==colnames(nest_checks))

write.table(newdata, "Nesting/nest_checks.csv", row.names = FALSE, col.names = FALSE,
            append = TRUE, na = "", sep = ",", quote = 9)


## Used to clean nest check data 1994 - 2020 into standard long format
## Done one year at a time chronologically, errors get more complicated over time...
## G. Yenni 2020-08

source("~/EvergladesWadingBird/DataCleaningScripts/clean_nest_checks.R")
# All original data files containing nest check data were pulled into a separate directory
# Original files: 
# [1] "2004 raw survey data all colonies_Found20130128 (Autosaved).xls"
# [2] "2018NestChecks.xlsx"                                            
# [3] "nest check 2008.xlsx"                                           
# [4] "nest check 2010 raw only.xlsx"                                  
# [5] "nest check 2011.xlsx"                                           
# [6] "nest check 2012.xlsx"                                           
# [7] "Nest Check Data_2019.xlsx"                                      
# [8] "Nest Check Data_2020.xlsx"                                      
# [9] "nest check original data 2013.xls"                              
# [10] "nest check original data 2014.xlsm"                             
# [11] "nest check original data 2015.xlsx"                             
# [12] "nest check original data 2016_QAQC.xlsx"                        
# [13] "nest check original data 2017_QAQC_JZ.xlsx"                     
# [14] "Nest Checks 2005 11-22 KAW UPDATE.xls"                          
# [15] "Nest Checks 2005.xls"                                           
# [16] "Nest Checks 2006.xls"                                           
# [17] "Nest Checks 2009.xls"                                           
# [18] "nest data 1994.xlsx"                                            
# [19] "Nest data 2002.xlsx"                                            
# [20] "nest data 2003.xlsx"   
files <- list.files("~/Downloads/nestdata", full.names = TRUE)
years <- c(2004, 2018, 2008, 2010, 2011, 2012, 2019, 2020, 2013, 2014, 2015, 2016, 2017, 2005, 2005, 2006, 
           2009, 1994, 2002, 2003)

new94 <- clean_nest_data(files[18], years[18])

new02 <- clean_nest_data(files[19], years[19])

new03 <- clean_nest_data(files[20], years[20])

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
                species = replace(species, species=="?", "unkn"),
                stage = NA) %>%
  dplyr::group_by(nest, colony, species) %>%
  tidyr::pivot_longer(cols = dplyr::starts_with("3"),
                      names_to = "date",
                      values_to = "notes") %>%
  dplyr::mutate(date = as.Date(as.integer(date), origin="1899-12-30"),
                eggs = as.character(gsub("E", "", stringr::str_extract(notes, "(\\d+)E"))),
                chicks = as.character(gsub("C", "", stringr::str_extract(notes, "(\\d+)[C]")))) %>%
  dplyr::select(year, colony, nest, species, date, eggs, chicks, stage, notes)

### 2005 data
tab_names05 <- readxl::excel_sheets(path = files[14])
new05 <- readxl::read_excel(path = files[14], sheet = tab_names05[1], col_names = TRUE, skip = 1) %>%
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
                eggs = as.character(eggs),
                chicks = as.character(chicks), 
                date = as.Date(date, origin="1899-12-30"),
                stage = NA) %>%
  dplyr::select(year, colony, nest, species, date, eggs, chicks, stage, notes)

old_data <- dplyr::bind_rows(new94, new02, new03, new04, new05)

## Add weird 2006, 2008, 2009 data
new06 <- extra_nest_data(files[16], years[16])

new08 <- extra_nest_data(files[3], years[3])

new09 <- extra_nest_data(files[17], years[17])

old_data <- old_data %>%
  dplyr::mutate(date = as.Date(date),
                eggs = as.numeric(eggs),
                chicks = as.numeric(chicks)) %>%
  dplyr::bind_rows(new06, new08, new09)

### 2010 - 2019
new10 <- clean_nest_data(files[4], years[4])

new11 <- clean_nest_data(files[5], years[5])

new12 <- clean_nest_data(files[6], years[6])

new13 <- clean_nest_data(files[9], years[9])

new14 <- clean_nest_data(files[10], years[10])

new15 <- clean_nest_data(files[11], years[11])

new16 <- clean_nest_data(files[12], years[12])

new17 <- clean_nest_data(files[13], years[13])
# several multispecies renests need to be correctly identified
new17$species[(new17$species=="whib then smhe") & (new17$date<="2017-03-17")] = "whib"
new17$species[(new17$species=="whib then smhe") & (new17$date>"2017-03-17")] = "smhe"
new17$species[(new17$species=="bcnh then smhe") & (new17$date<="2017-03-17")] = "bcnh"
new17$species[(new17$species=="bcnh then smhe") & (new17$date>"2017-03-17")] = "smhe"
new17$species[(new17$species=="bcnh then greg?")] = "bcnh"
# it's complicated
new17$chicks[which(new17$date=="2017-04-21" & new17$nest=="744")] = 2

new18 <- clean_nest_data(files[2], years[2])

new19 <- clean_nest_data(files[7], years[7])

new20 <- clean_nest_data(files[8], years[8])
# several multispecies renests need to be correctly identified
new20$species[(new20$species=="greg/smhe") & (new20$date<="2020-04-06")] = "greg"
new20$species[(new20$species=="greg/smhe") & (new20$date>"2020-04-06")] = "smhe"
new20$species[(new20$species=="bcnh/smwh relay") & (new20$date<="2020-04-07")] = "bcnh"
new20$species[(new20$species=="bcnh/smwh relay") & (new20$date>"2020-04-07")] = "smwt"
new20$species[(new20$species=="bcnh/glib relay") & (new20$date<="2020-04-21")] = "bcnh"
new20$species[(new20$species=="bcnh/glib relay") & (new20$date>"2020-04-21")] = "glib"
new20$species[(new20$species=="bcnh/whib relay") & (new20$date<"2020-04-01")] = "bcnh"
new20$species[(new20$species=="bcnh/whib relay") & (new20$date>="2020-04-01")] = "whib"
new20$species[(new20$species=="rosp/smhe relay") & (new20$date<"2020-04-22")] = "rosp"
new20$species[(new20$species=="rosp/smhe relay") & (new20$date>="2020-04-22")] = "smhe"
new20$species[(new20$species=="smwh/glib relay") & (new20$date<"2020-05-06")] = "sneg"
new20$species[(new20$species=="smwh/glib relay") & (new20$date>="2020-05-06")] = "glib"
new20$species[(new20$species=="smhe/glib relay") & (new20$date<"2020-04-08")] = "smhe"
new20$species[(new20$species=="smhe/glib relay") & (new20$date>="2020-04-08")] = "glib"
new20$species[(new20$species=="bcnh/trhe") & (new20$date<"2020-04-22")] = "bcnh"
new20$species[(new20$species=="bcnh/trhe") & (new20$date>="2020-04-22")] = "trhe"
new20$species[(new20$species=="bcnh*/smwh relay") & (new20$date<"2020-04-09")] = "bcnh"
new20$species[(new20$species=="bcnh*/smwh relay") & (new20$date>="2020-04-09")] = "smwt"
new20$species[(new20$species=="rosp/glib relay") & (new20$date<"2020-05-06")] = "rosp"
new20$species[(new20$species=="rosp/glib relay") & (new20$date>="2020-05-06")] = "glib"
new20$species[(new20$species=="whib/glib relay") & (new20$date<"2020-05-06")] = "whib"
new20$species[(new20$species=="whib/glib relay") & (new20$date>="2020-05-06")] = "glib"
# Remove duplicate rows
new20=new20[-which(new20$eggs=="same nest as 486"),]
new20=new20[-which(new20$eggs=="nest 154"),]

new20[new20$species=="whib/glib relay",]
unique(new20$species[which(!(new20$species %in% species$species))])
unique(new20$eggs)
unique(new20$chicks)

nests <- dplyr::bind_rows(new10,new11,new12,new13,new14,new15,new16,new17,new18,new19) %>%
  dplyr::mutate(date = as.Date(date),
                eggs = as.numeric(eggs),
                chicks = as.numeric(chicks))
nests <- dplyr::bind_rows(old_data,nests) %>%
  tidyr::drop_na(species) %>%
  dplyr::filter_at(.vars = dplyr::vars(eggs, chicks, stage, notes), 
                   .vars_predicate = dplyr::any_vars(!is.na(.)))

nests <- nests %>%
         dplyr::mutate(dplyr::across(c(colony,nest,species,stage,notes),as.character),
                       dplyr::across(c(year,eggs,chicks),as.integer),
                       date = lubridate::ymd(date))
write.table(nests, "Nesting/nest_checks.csv", row.names = FALSE, na = "", sep = ",", quote = 9)

species <- species %>% dplyr::arrange(species)
write.table(species, "SiteandMethods/species_list.csv", row.names = FALSE, na = "", sep = ",", quote = 7:27)

colonies <- colonies %>% dplyr::arrange(colony)
write.table(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = c(7,8))
