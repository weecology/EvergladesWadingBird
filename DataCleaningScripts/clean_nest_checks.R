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
  
  all_data <- setNames(data.frame(matrix(ncol = 8, nrow = 0)), c("year", "colony", "nest", "species", 
                                                                 "date",  "eggs", "chicks", "notes"))
  
  tab_names <- readxl::excel_sheets(path = data_path)
  data_raw <- lapply(tab_names, function(x) readxl::read_excel(path = data_path, sheet = x, 
                                                               col_names = FALSE, skip = 2))
  
  for(i in 1:length(data_raw)) {
    colnames1 <- as.character(data_raw[[i]][1,])
    colnames1[1:2] <- c("nest", "species")
    colnames1 <- zoo::na.locf(colnames1)
    colnames2 <- as.character(data_raw[[i]][2,])
    colnames2 <- colnames2[!is.na(colnames2)]
    colnames2 <- colnames2[colnames2 != "NA"]
    colnames2 <- colnames2[!is.na(colnames2)] %>%
      replace(colnames2=="Eggs", "E") %>%
      replace(colnames2=="Hatching", "H") %>%
      replace(colnames2=="Chicks", "C") %>%
      replace(colnames2=="Dead", "D")
    
    colnames1 <- colnames1[1:length(colnames2)]
    colnames <- paste(colnames1, colnames2, sep = "_")
    colnames[1:2] <- c("nest", "species")
    #names(data_raw[[i]][,1:length(colnames)]) <- colnames
    
    new_data_colony <- tolower(tab_names[i]) %>%
      gsub(" ", "_", .) %>%
      gsub("/.", "_", .) 
    
    new_data <- as.data.frame(data_raw[[i]][,1:length(colnames)]) %>%
      setNames(colnames) %>%
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
                    species = replace(species, species=="unknown", "unkn"),
                    species = replace(species, species=="ge", "greg"),
                    species = replace(species, species=="sh", "smhe"),
                    species = replace(species, species=="gbh", "gbhe"),
                    species = replace(species, species=="tche", "trhe"),
                    species = replace(species, species=="anhi?", "anhi"),
                    species = replace(species, is.na(species), "unkn"),
                    colony = replace(colony, colony=="alley_n_whib", "alley_north")) %>%
      tidyr::pivot_wider(names_from = stage, values_from = count) %>%
      dplyr::rename(eggs = "E", chicks = "C", nest_gone = "NEST GONE", notes = NOTES) %>%
      dplyr::mutate(X = ifelse("X" %in% names(.), X, NA),
                    K = ifelse("K" %in% names(.), K, NA)) %>%
      dplyr::mutate(notes = ifelse(is.na(H), notes, paste(H,"H, ", notes)),
                    notes = ifelse(is.na(D), notes, paste(D,"D, ", notes)),
                    notes = ifelse(is.na(X), notes, paste(X,"X, ", notes)),
                    notes = ifelse(is.na(K), notes, paste(K,"K, ", notes)),
                    notes = ifelse(is.na(EMPTY), notes, paste(EMPTY," empty, ", notes)),
                    notes = ifelse(is.na(nest_gone), notes, paste(nest_gone," nest gone, ", notes)),
                    notes = stringr::str_remove(notes, "(NA)$"),
                    chicks = replace(chicks, chicks=="1<", 1),
                    chicks = replace(chicks, chicks=="~2", 2),
                    eggs = replace(eggs, eggs=="?", NA)) %>%
      dplyr::filter(!is.na(nest)) %>%
      dplyr::mutate(date = as.Date(date),
                    eggs = as.numeric(eggs),
                    chicks = as.numeric(chicks)) %>%
      dplyr::select(year, colony, nest, species, date, eggs, chicks, notes)
    
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

all_data <- setNames(data.frame(matrix(ncol = 8, nrow = 0)), c("year", "colony", "nest", "species", "date",
                                                               "eggs", "chicks","notes"))

tab_names <- readxl::excel_sheets(path = data_path)
tab_names <- tab_names[-which(tab_names=="key")]
data_raw <- lapply(tab_names, function(x) readxl::read_excel(path = data_path, sheet = x, 
                                                             col_names = FALSE))

for(i in 1:length(tab_names)) {
  colnames1 <- as.character(data_raw[[i]][1,])
  colnames1[1:2] <- c("nest", "species")
  colnames1 <- zoo::na.locf(colnames1)
  colnames2 <- as.character(data_raw[[i]][2,])
  colnames2 <- colnames2[!is.na(colnames2)]
  colnames2 <- colnames2[colnames2 != "NA"]
  colnames2 <- colnames2[!is.na(colnames2)]
  colnames1 <- colnames1[1:length(colnames2)]
  colnames <- paste(colnames1, colnames2, sep = "_")
  colnames[1:2] <- c("nest", "species")
  colnames[length(colnames)] <- "notes"
  #names(data_raw[[i]]) <- colnames

  new_data_colony <- tolower(tab_names[i]) %>%
    gsub(" ", "_", .) %>%
    gsub("/.", "_", .) 

  new_data <- as.data.frame(data_raw[[i]][,1:length(colnames)]) %>%
    setNames(colnames) %>%
    dplyr::slice(-c(1:2)) %>%
    tidyr::pivot_longer(cols = dplyr::starts_with(c("3", "4")), 
                        names_to = c("date","stage"),
                        names_pattern = "(.*)_(.*)",
                        values_to = "count") %>%
    dplyr::mutate(date = as.Date(as.integer(date), origin="1899-12-30"), 
                  colony = new_data_colony,
                  colony = replace(colony, colony %in% c("tam_west", "tamw2015","tamw"), "tamiami_west"),
                  colony = replace(colony, colony=="tam_west_ibis_trail", "tamiami_west_ibis_trail"),
                  colony = replace(colony, colony=="alley_north_(trail_1)", "alley_north"),
                  species = tolower(species),
                  stage = tolower(stage),
                  stage = replace(stage, stage=="comments", "notes"),
                  year = year,
                  species = replace(species, species %in% c("tric","tche"), "trhe"),
                  species = replace(species, species %in% c("?", "-"), "unkn"),
                  species = replace(species, is.na(species), "unkn"),
                  species = replace(species, species %in% 
                                      c("smwh", "smwt (prob greg)", "smwht"), "smwt")) %>%
    dplyr::filter(!is.na(nest), !(stage == "notes" & is.na(count))) %>%
    tidyr::pivot_wider(names_from = stage, values_from = count) %>%
    dplyr::mutate(eggs = tolower(eggs),
                  chicks = tolower(chicks),
                  chicks = replace(chicks, chicks %in% 
                  c("nest gone","gone","flag pulled","empty,pulled","empty/ pulled","pulled","x",
                    "pulled flag","empty","fp","0/fp","0/ fp","empty/fp","-","fail","failed",
                    "c(\"x\", \"x\")","c(\"x\", \"0\")","c(\"x\", na)","c(\"0\", \"0\")","?",
                    "fledged","nnest gone","1dc"), 0),
                  chicks = replace(chicks, chicks %in% c("3/fp","2-3"),3),
                  eggs = replace(eggs, eggs %in% c("1 broken egg"),1),
                  eggs = replace(eggs, eggs %in% 
                  c("nest gone","gone","flag pulled","empty, pulled","empty/ pulled","pulled","x",
                    "pulled flag","empty","emty/pulled","empty/pulled","fp","0/fp","destroyed","0/ fp",
                    "fallen down","empty/fp","-","fail","had been pulled","failed","c(\"x\", na)",   
                    "c(\"x\", \"x\")","c(\"x\", \"2\")","c(\"0\", \"0\")","ir","80","yes","?","fledged",
                    "nnest gone", "na","fledged pulled","13 chicks for this group","fallen","1 dead"), 0),
                  chicks = replace(chicks, chicks %in% 
                                     c("no data","comment","lost flag","not checked","flag gone",
                                       "c(na, na)", "not found","missed"), NA),
                  eggs = replace(eggs, eggs %in% 
                                   c("no data","comment","lost flag","not checked","flag gone",
                                     "c(na, na)","not found","not checkd","flag gone",                      
                                     "not checked - whib in colony","missed","missed. pulled?",
                                     "n/a see 376a","missed?","no longer on trail"), NA)) %>%
    # dplyr::mutate(date = as.Date(date),
    #               eggs = as.numeric(eggs),
    #               chicks = as.numeric(chicks)) %>%
    dplyr::select(year, colony, nest, species, date, eggs, chicks, notes)

    if(!all(new_data$colony %in% colonies$colony)| 
    !all(new_data$species %in% species$species)|
    !all(format(as.Date(new_data$date),"%Y")==year)) {
      print(unique(new_data$colony[which(!(new_data$colony %in% colonies$colony))]))
      print(unique(new_data$species[which(!(new_data$species %in% species$species))]))
    }

  all_data <- rbind(all_data, new_data) }

  return(all_data)
  }
  