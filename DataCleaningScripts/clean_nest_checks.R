#' Functions used to reshape and clean nest data from field format
#'

`%>%` <- magrittr::`%>%`

#' Functions customized to old nest data (pre-2020)
#'

#' Reshapes and cleans nest check data (2006-2009) with extra columns
#'
#'
#'
#' Reads nest check data from original excel files, reshapes from wide (dates as cols) to long format,
#' extracts colony names from tabs, corrects data format errors, appends to long timeseries file

extra_nest_data <- function(data_path, year) {
  
  colonies <- read.csv("SiteandMethods/colonies.csv")
  species <- read.csv("SiteandMethods/species_list.csv")
  
  all_data <- setNames(data.frame(matrix(ncol = 7, nrow = 0)), c("year", "colony", "nest", "species", "date",
                                                                 "eggs", "chicks", "notes"))
  
  tab_names <- readxl::excel_sheets(path = data_path)
  data_raw <- lapply(tab_names, function(x) readxl::read_excel(path = data_path, sheet = x, col_names = FALSE, 
                                                               skip = 2))
  
  for(i in 1:length(data_raw)) {
    colnames1 <- as.character(data_raw[[i]][1,])
    colnames1[1:2] <- c("nest", "species")
    colnames1 <- zoo::na.locf(colnames1)
    colnames2 <- as.character(data_raw[[i]][2,])
    colnames <- paste(colnames1, colnames2, sep = "_")
    colnames[1:2] <- c("nest", "species")
    names(data_raw[[i]]) <- colnames
    
    new_data_colony <- tolower(tab_names[i]) %>%
      gsub(" ", "_", .) %>%
      gsub("/.", "_", .) 
    
    new_data <- as.data.frame(data_raw[[i]]) %>%
      dplyr::slice(-c(1:2)) %>%
      tidyr::pivot_longer(cols = dplyr::starts_with("3"), 
                          names_to = c("date","stage"),
                          names_pattern = "(.*)_(.*)",
                          values_to = "count") %>%
      dplyr::mutate(date = as.Date(as.integer(date), origin="1899-12-30"), 
                    colony = new_data_colony,
                    species = tolower(species),
                    year = year, 
                    species = replace(species, species=="tric", "trhe"),
                    species = replace(species, species=="?", "unkn"),
                    species = replace(species, species=="ge", "greg"),
                    species = replace(species, species=="sh", "smhe"),
                    species = replace(species, species=="gbh", "gbhe"),
                    species = replace(species, species=="tche", "trhe"),
                    species = replace(species, species=="ycnh", "unkn")) %>%
      tidyr::pivot_wider(names_from = stage, values_from = count) %>%
      dplyr::rename(eggs = "E", chicks = "C", nest_gone = "NEST GONE", notes = NOTES) %>%
      dplyr::mutate(notes = ifelse(is.na(H), notes, paste(H,"H, ", notes)),
                    notes = ifelse(is.na(D), notes, paste(D,"D, ", notes)),
                    notes = ifelse(is.na(X), notes, paste(X,"X, ", notes)),
                    notes = ifelse(is.na(K), notes, paste(K,"K, ", notes)),
                    notes = ifelse(is.na(EMPTY), notes, paste(EMPTY," empty, ", notes)),
                    notes = ifelse(is.na(nest_gone), notes, paste(nest_gone," nest gone, ", notes)),
                    notes = stringr::str_remove(notes, "(NA)$")) %>%
      dplyr::select(year, colony, nest, species, everything())
    
    stopifnot(
      all(new_data$colony %in% colonies$colony), 
      all(new_data$species %in% species$species),
      all(format(as.Date(new_data$date),"%Y")==year) )
    
    all_data <- rbind(all_data, new_data) }
  
  return(all_data)
}

#' Reshapes and cleans nest check data (1994-2003)
#'
#'
#'
#' Reads nest check data from original excel files, reshapes from wide (dates as cols) to long format,
#' extracts colony names from tabs, corrects data format errors, appends to long timeseries file

clean_nest_data <- function(data_path, year) {
  
colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")

all_data <- setNames(data.frame(matrix(ncol = 7, nrow = 0)), c("year", "colony", "nest", "species", "date",
                                                               "eggs", "chicks"))

tab_names <- readxl::excel_sheets(path = data_path)
data_raw <- lapply(tab_names, function(x) readxl::read_excel(path = data_path, sheet = x, col_names = FALSE))

for(i in 1:length(data_raw)) {
  colnames1 <- as.character(data_raw[[i]][1,])
  colnames1[1:2] <- c("nest", "species")
  colnames1 <- zoo::na.locf(colnames1)
  colnames2 <- as.character(data_raw[[i]][2,])
  colnames <- paste(colnames1, colnames2, sep = "_")
  colnames[1:2] <- c("nest", "species")
  names(data_raw[[i]]) <- colnames

  new_data_colony <- tolower(tab_names[i]) %>%
    gsub(" ", "_", .) %>%
    gsub("/.", "_", .) 

  new_data <- as.data.frame(data_raw[[i]]) %>%
    dplyr::slice(-c(1:2)) %>%
    tidyr::pivot_longer(cols = dplyr::starts_with("3"), 
                        names_to = c("date","stage"),
                        names_pattern = "(.*)_(.*)",
                        values_to = "count") %>%
    dplyr::mutate(date = as.Date(as.integer(date), origin="1899-12-30"), 
                  colony = new_data_colony,
                  species = tolower(species),
                  year = year) %>%
    dplyr::mutate(species = replace(species, species=="tric", "trhe"),
                  species = replace(species, species=="?", "unkn")) %>%
    tidyr::pivot_wider(names_from = stage, values_from = count) %>%
    dplyr::select(year, colony, nest, species, everything())

  stopifnot(
    # all(new_data$colony %in% colonies$colony), 
    # all(new_data$species %in% species$species),
    all(format(as.Date(new_data$date),"%Y")==year) )

  all_data <- rbind(all_data, new_data) }

  return(all_data)
  }
  