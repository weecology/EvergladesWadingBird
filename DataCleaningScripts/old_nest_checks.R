## Used to clean nest check data 1994 - 2019 into standard long format
## G. Yenni 2020-08

source("~/EvergladesWadingBird/DataCleaningScripts/clean_nest_checks.R")
files <- list.files("~/Desktop/nestdata", full.names = TRUE)
years <- c(2004, 2018, 2019, 2013, 2014, 2015, 2016, 2017, 2005, 2005, 2006, 2009, 1994, 2002, 2003)

new94 <- clean_nest_data(files[13], years[13])

new02 <- clean_nest_data(files[14], years[14])

new03 <- clean_nest_data(files[15], years[15])

old_data <- dplyr::bind_rows(new94, new02, new03)
old_data$chicks[which(old_data$chicks==33)] = 3 
old_data$chicks[which(old_data$chicks=="*")] = 0 

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

old_data <- old_data %>%
  dplyr::mutate(eggs = as.numeric(eggs),
                chicks = as.numeric(chicks)) %>%
  dplyr::bind_rows(new04, new05)

unique(old_data$species[!(old_data$species %in% species$species)])

old_data <- old_data %>%
  dplyr::mutate(species = replace(species, is.na(species), "unkn"),
                species = replace(species, species=="ge", "greg"),
                species = replace(species, species=="wi", "whib"),
                species = replace(species, species=="grbl", "gbhe"),
                species = replace(species, species=="sh", "smhe"),
                species = replace(species, species=="gb", "gbhe"),
                species = replace(species, species=="gb (poss. ge)", "gbhe"),
                species = replace(species, species=="tche", "trhe"),
                species = replace(species, species=="sh?", "smhe"),
                species = replace(species, species=="an", "anhi"),
                species = replace(species, species=="sh/an", "smhe"),
                species = replace(species, species=="anhg", "anhi"),
                species = replace(species, species=="anhg", "anhi"),
                species = replace(species, species=="gi", "glib"),
                species = replace(species, species=="gi?", "glib"),
                species = replace(species, species=="ge/nh", "unkn"),
                species = replace(species, species=="ge/nh?", "unkn"))

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

new18 <- clean_nest_data(files[2], years[2])

new19 <- clean_nest_data(files[3], years[3])


write.csv(old_data, "Nesting/nest_checks.csv", row.names = FALSE, na = "", quote = FALSE)

species[17, 1:4]=c("smwt", "small white unidentified bird", "unknown", "no")

species <- species %>% dplyr::arrange(species)
write.csv(species, "SiteandMethods/species_list.csv", row.names = FALSE, na = "")

colonies[62, 1]="an2015"

colonies <- colonies %>% dplyr::arrange(wca,colony)
write.csv(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, na = "", quote = FALSE)
