#' Functions used to reshape and clean nest data from field format
#'

`%>%` <- magrittr::`%>%`

#' Reshapes and cleans nest check data 
#'
#'
#'
#' Reads nest check data from original excel files, reshapes from wide (dates as cols) to long format,
#' extracts colony names from tabs, corrects data format errors, appends to long timeseries file

clean_nest_data <- function(data_path, year) {
  
colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")

all_data <- setNames(data.frame(matrix(ncol = 9, nrow = 0)), c("year", "colony", "nest", "species", "date",
                                                               "eggs", "chicks", "stage", "notes"))

tab_names <- readxl::excel_sheets(path = data_path)
tab_names <- tab_names[tab_names != "key"]
tab_names <- tab_names[!(tab_names %in% 
              c("Proofing","Template","template","TO BE RESOLVED","Decisions on changes"))]
tab_names <- tab_names[!startsWith(tab_names ,"Other")]
tab_names <- tab_names[!startsWith(tab_names ,"Sheet")]
tab_names <- tab_names[!startsWith(tab_names ,"Transect")]
tab_names <- tab_names[!startsWith(tab_names ,"Dataset Headers")]
data_raw <- lapply(tab_names, function(x) readxl::read_excel(path = data_path, sheet = x, 
                                                             col_names = FALSE))

for(i in 1:length(tab_names)) {
  colnames1 <- as.numeric(data_raw[[i]][1,])
  colnames1[1:4] <- c("year","colony", "nest", "species")
  colnames1 <- zoo::na.locf(colnames1)
  colnames2 <- as.character(data_raw[[i]][2,])
  colnames2 <- colnames2[!is.na(colnames2)]
  colnames2 <- colnames2[colnames2 != "NA"]
  colnames2 <- colnames2[!is.na(colnames2)]
  colnames2 <-  tolower(gsub("# ","", colnames2))
  if(any(startsWith(colnames2,"comment"))) {colnames2 <- colnames2[1:which(startsWith(colnames2,"comment"))]}
  colnames1 <- tolower(colnames1[1:length(colnames2)])
  colnames <- paste(colnames1, colnames2, sep = "_")
  colnames[1:4] <- c("year","colony", "nest", "species")
  colnames[length(colnames)] <- "notes"

  new_data <- as.data.frame(data_raw[[i]][,1:length(colnames)]) %>%
    setNames(colnames) %>%
    dplyr::slice(-c(1:2)) %>%
    tidyr::pivot_longer(cols = dplyr::starts_with(c("3", "4")), 
                        names_to = c("date","type"),
                        names_pattern = "(.*)_(.*)",
                        values_to = "count") %>%
    dplyr::mutate(date = as.Date(as.integer(date), origin="1899-12-30"), 
                  colony = tolower(colony),
                  year = year,
                  colony = replace(colony, colony=="paurotis_pond", "paurotis"),
                  colony = replace(colony, colony=="jarrod", "jerrod"),
                  colony = replace(colony, colony=="cypresscity", "cypress_city"),
                  colony = replace(colony, colony=="rookerybranch", "rookery_branch"),
                  colony = replace(colony, colony %in% c("l67_east_side", "l67_north_end", "l_67",
                                                         "horus_(l67)"), "horus"),
                  species = tolower(species),
                  type = tolower(type),
                  species = replace(species, species %in% c("?", "-","ge/nh?","ge/nh","unknown"), "unkn"),
                  species = replace(species, is.na(species), "unkn"),
                  species = replace(species, species %in% 
                                      c("smwt", "smwt (prob greg)","smwht","greg/smwh","swhe","smwh*"), 
                                    "smwh"),
                  species = replace(species, species %in% 
                                      c("small heron/cormorant","small heron","sh","sh/an","smda",
                                        "smhe*","bcnh or smhe"), "smhe")) %>%
    dplyr::filter(!is.na(nest), !(type == "notes" & is.na(count))) %>%
    tidyr::pivot_wider(names_from = type, values_from = count) %>%
    dplyr::mutate(eggs = tolower(eggs),
                  chicks = tolower(chicks)) %>%
    dplyr::mutate(dplyr::across(everything(),~ purrr::map_chr(.x, ~ gsub("\"", "", .x)))) %>%
    dplyr::filter(!dplyr::if_all(c(eggs, chicks,stage), is.na)) %>%
    dplyr::mutate(year = as.integer(year),
                  colony = as.character(colony),
                  nest = as.character(nest),
                  species = as.character(species),
                  date = lubridate::ymd(date),
                  eggs = as.integer(eggs),
                  chicks = as.integer(chicks),
                  stage = as.character(stage),
                  notes = as.character(notes)) %>%
    dplyr::select(year, colony, nest, species, date, eggs, chicks, stage, notes)

  all_data <- rbind(all_data, new_data) }

  return(all_data)
}

#' Reshapes and cleans nest check data (2006-2009) with extra columns
#'
#'
#'
#' Reads nest check data from original excel files, reshapes from wide (dates as cols) to long format,
#' extracts colony names from tabs, corrects data format errors, appends to long timeseries file

extra_nest_data <- function(data_path, year) {
  
  colonies <- read.csv("SiteandMethods/colonies.csv")
  species <- read.csv("SiteandMethods/species_list.csv")
  
  all_data <- setNames(data.frame(matrix(ncol = 9, nrow = 0)), c("year", "colony", "nest", "species", 
                                                                 "date",  "eggs", "chicks", "stage", "notes"))
  
  tab_names <- readxl::excel_sheets(path = data_path)
  tab_names <- tab_names[tab_names != "key"]
  tab_names <- tab_names[!startsWith(tab_names ,"Other")]
  tab_names <- tab_names[!startsWith(tab_names ,"Overview")]
  tab_names <- tab_names[!startsWith(tab_names ,"Dataset Headers")]
  data_raw <- lapply(tab_names, function(x) readxl::read_excel(path = data_path, sheet = x, 
                                                               col_names = FALSE, skip = 2))
  
  for(i in 1:length(data_raw)) {
    colnames1 <- as.character(data_raw[[i]][1,])
    colnames1[1:2] <- c("nest", "species")
    colnames1 <- zoo::na.locf(colnames1)
    colnames2 <- as.character(data_raw[[i]][2,])
    colnames2 <- colnames2[!is.na(colnames2)]
    colnames2 <- tolower(colnames2[colnames2 != "NA"])
    colnames2 <- colnames2[!is.na(colnames2)] %>%
      replace(colnames2=="eggs", "e") %>%
      replace(colnames2 %in% c("hatching","hatch"), "h") %>%
      replace(colnames2=="chicks", "c") %>%
      replace(colnames2=="dead", "d")
    
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
                          names_to = c("date","type"),
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
      tidyr::pivot_wider(names_from = type, values_from = count) %>%
      dplyr::rename(eggs = "e", chicks = "c", nest_gone = "nest gone", notes = notes) %>%
      dplyr::mutate(x = ifelse("x" %in% names(.), x, NA),
                    k = ifelse("k" %in% names(.), k, NA)) %>%
      dplyr::mutate(notes = ifelse(is.na(h), notes, paste(h,"h, ", notes)),
                    notes = ifelse(is.na(d), notes, paste(d,"d, ", notes)),
                    notes = ifelse(is.na(x), notes, paste(x,"x, ", notes)),
                    notes = ifelse(is.na(k), notes, paste(k,"k, ", notes)),
                    notes = ifelse(is.na(empty), notes, paste(empty," empty, ", notes)),
                    notes = ifelse(is.na(nest_gone), notes, paste(nest_gone," nest gone, ", notes)),
                    notes = stringr::str_remove(notes, "(NA)$"),
                    chicks = replace(chicks, chicks %in% c("1<",'c("1", NA)'), 1),
                    chicks = replace(chicks, chicks=="~2", 2),
                    chicks = replace(chicks, chicks %in% c("?","c(NA, NA)"), NA),
                    eggs = replace(eggs, eggs %in% c("?","c(NA, NA)"), NA),
                    eggs = replace(eggs, eggs=='c("1", "3")', 3),
                    eggs = replace(eggs, eggs=='c(NA, "2")', 2),
                    stage = dplyr::case_when(notes %in% c("empty","nest gone")~"empty")) %>%
      dplyr::filter(!is.na(nest)) %>%
      dplyr::mutate(date = as.Date(date),
                    eggs = as.numeric(eggs),
                    chicks = as.numeric(chicks)) %>%
      dplyr::select(year, colony, nest, species, date, eggs, chicks, stage, notes)
    
    stopifnot(
      all(new_data$colony %in% colonies$colony), 
      all(new_data$species %in% species$species),
      all(format(as.Date(new_data$date),"%Y")==year) )
    
    all_data <- rbind(all_data, new_data) }
  
  return(all_data)
}
  