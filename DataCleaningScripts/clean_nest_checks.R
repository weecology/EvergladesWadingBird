#' Functions used to reshape and clean nest data from field format
#'

`%>%` <- magrittr::`%>%`

#' Functions customized to old nest data (pre-2020)
#'

#' Reshapes and cleans nest check data (1994-2005, 2013-2019)
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
tab_names <- tab_names[tab_names != "key"]
tab_names <- tab_names[!startsWith(tab_names ,"Other")]
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
                  colony = replace(colony, colony %in% 
                                     c("tam_west", "tamw2015","tamw","tamiami_west_(whib)",
                                       "tamiami_west_(new_trail)"), "tamiami_west"),
                  colony = replace(colony, colony=="tam_west_ibis_trail", "tamiami_west_ibis_trail"),
                  colony = replace(colony, colony=="6th_bridge_whib", "6th_bridge"),
                  colony = replace(colony, colony %in% c("alley_north_(trail_1)","alley_north_(trail_2)"), 
                                   "alley_north"),
                  species = tolower(species),
                  stage = tolower(stage),
                  stage = replace(stage, stage=="comments", "notes"),
                  year = year,
                  species = replace(species, species %in% c("tric","tche","trhe?"), "trhe"),
                  species = replace(species, species %in% c("?", "-","ge/nh?","ge/nh","unknown"), "unkn"),
                  species = replace(species, is.na(species), "unkn"),
                  species = replace(species, species %in% 
                                      c("smwh", "smwt (prob greg)","smwht","greg/smwh"), "smwt"),
                  species = replace(species, species %in% 
                                      c("small heron/cormorant","small heron","sh","sh/an"), "smhe"),
                  species = replace(species, species %in% c("an","anhg","anhi?",""), "anhi"),
                  species = replace(species, species %in% c("gi","gi?"), "glib"),
                  species = replace(species, species %in% c("gb","gb (poss. ge)","gbhe?"), "gbhe"),
                  species = replace(species, species %in% c("whib?","wi"), "whib"),
                  species = replace(species, species %in% c("ge","greg?","greg/smhe?"), "greg"),
                  species = replace(species, species=="green heron", "grhe"),
                  species = replace(species, species %in% c("sneg?"), "sneg"),
                  species = replace(species, species %in% 
                                      c("smhe/greg/bcnh","smhe/bcnh","trhe/bcnh","trhe/bcnh?"), "bcnh"),
                  species = replace(species, species %in% c("whib/rospb"), "rosp")) %>%
    dplyr::filter(!is.na(nest), !(stage == "notes" & is.na(count))) %>%
    tidyr::pivot_wider(names_from = stage, values_from = count) %>%
    dplyr::mutate(eggs = tolower(eggs),
                  chicks = tolower(chicks),
                  chicks = replace(chicks, chicks %in% c("5(+1 dead chick on ground)"), 5),
                  chicks = replace(chicks, chicks %in% c("4(certain)","4*","8 total w/145",
                    "8 total w/143","4(+1 dead chick on ground)"), 4),
                  chicks = replace(chicks, chicks %in% c("3/fp","2-3","33","c(\"3\", na)",
                    "c(\"3\", \"3\")","3+","3 (1 wet)","c(\"3 (1 wet)\", \"2 (1 wet)\")","3(+1dead)",
                    "3(certain)","3 (in area)","3(2wet)","3(confirmed)","3 (double checked it is 3)",
                    "3 (1  wet)","4+","10 total w/ 128,130","10 total w 128, 126","10 total w/ 126, 130",
                    "3 (totally sure it is 3 and they cannot be from any other nest around)",
                    "3 (9 total 126/128/130)","(3 in area)"), 3),
                  chicks = replace(chicks, chicks %in% c("2?","2+","2 (sneg on ground)","2 (+1dead)",
                    "2 fledged","2 (both wet)","2 (1 wet)","2 (+1 dead)","2 (+1 long dead)","2 (2 wet)",
                    "2 greg +1 bcnh","c(\"2\", na)","2 (1wet)","2(+1 dead)","2(2wet)","2 (certain)",
                    "2 (big above nest)","2 (flew)","2 (around nest)","2 (2-3 days old)"), 2),
                  chicks = replace(chicks, chicks %in% c("1alive,1dead","1?","1+","1 (wet)","1*","1(2)",
                    "1 fledged","note","1 (+1dead)","(1 long dead)","1(wet)","1 (1 wet)","1(+1 dead)",
                    "1 (+1 dead)","1(+1dead)","1(live) 1(dead)","1(ran)","1(dead) 1(alive)","1+ (+ 1 dead)",
                    "1+(flew out)"), 1),
                  chicks = replace(chicks, chicks %in% c("nest gone","gone","flag pulled","empty,pulled",
                    "empty/ pulled","pulled","x","pulled flag","empty","fp","0/fp","0/ fp","empty/fp","-",
                    "fail","failed","c(\"x\", \"x\")","c(\"x\", \"0\")","c(\"x\", na)","c(\"0\", \"0\")",
                    "?","fledged","nnest gone","1dc","*","1 dead chick","0pulled","chick dead","1dead",
                    "c(\"0\", na)","c","cormorants here","collpapsed", "collpased","collapsed",
                    "collapsed pulled","e","empty pulled","collpased pulled","fledged?",
                    "empty collapsed pulled","empty/pulled","empty collpased","collapsed/pulled","mt",
                    "mt*","c(\"mt\", na)","mt (1 dead big)","mt pull","mt pulled","mt (2 chick in area)",
                    "(1dead)","dead(1)","(1 dead)","(2 dead)","1(dead)","predated","dead chick on ground",
                    "mt (1 big chick in area)","0 (pulled)","pull","mt (1 dead)","mt(1+ in area)",
                    "mt collapsed","mt (predated)","mt (1 dead c)","(1dead chick)","mt (pulled)",
                    "on ground"), 0),
                  chicks = replace(chicks, chicks %in% 
                    c("no data","comment","lost flag","not checked","flag gone","c(na, na)", "not found",
                    "missed","c(\"not checked\", \"not checked\")","missd","missed or couldn't get to?",
                    "missing","missed in the notebook says wost  not greg","miss","missed, likely mt",
                    "missed?"), NA),
                  eggs = replace(eggs, eggs %in% c("5 (2 pipping)"), 5),
                  eggs = replace(eggs, eggs %in% c("4 (1pipping)","4 (1p)","4(dead)","4 (1 pipping)",
                    "(4 anhi) pulled"), 4),
                  eggs = replace(eggs, eggs %in% c("c(\"3\", na)","3(1 pipping)","3 (1 pipping)",
                    "3 (2 pipping)","3 (1p)","c(\"3\", \"3\")","3(whib)","3(broken)","3(2 pipping)",
                    "3(1p)","3(pipping)"), 3),
                  eggs = replace(eggs, eggs %in% c("smhe(2 eggs)","2 (1p)","2(1 pipping)","2(renest)",
                    "2 (1 pipping)","2(broken)","2*","2 (1pipping)","2(pipping)","2(predated)",
                    "2 (pipping)","2 (anhi)","2 (wost)"), 2),
                  eggs = replace(eggs, eggs %in% c("1 broken egg","1?","1 (old)","1 (1pipping)","1(1p)",
                    "1 (pippng)","(1 broken or pipping)","1( pipping)","1 old egg","(dead) 1","(dead)1",
                    "1(pipping)","1+","1(dead)","1 (dead)","1 (+1cracked)","(1 broken)","1(broken)",
                    "1 (pulled)","1 (pipping)","1 (dead, old)","1 (1p)","1 (cold)"), 1),
                  eggs = replace(eggs, eggs %in% 
                  c("nest gone","gone","flag pulled","empty, pulled","empty/ pulled","pulled","x",
                    "pulled flag","empty","emty/pulled","empty/pulled","fp","0/fp","destroyed","0/ fp",
                    "fallen down","empty/fp","-","fail","had been pulled","failed","c(\"x\", na)",
                    "c(\"x\", \"x\")","c(\"x\", \"2\")","c(\"0\", \"0\")","ir","80","yes","?","fledged",
                    "nnest gone", "na","fledged pulled","13 chicks for this group","fallen","1 dead",
                    "predated-grackle","c(\"0\", na)","chicks running","1e-fail","falling","1d",
                    "gone/pulled","collapsed","collapsed/pulled","gone pulled","drop","gone? or pulled",
                    "?/pulled","egg shells/pulled","nest gone/pulled","nest collapsed","destroyed-pulled",
                    "empty*","destroyed/pulled","predated","note","see note","collapsed pulled","mt","m",
                    "mt pull","mt pulled","collapsed and pulled","predated (1 broken)","*","mt (pulled)",
                    "pull","126/128/130","0+","collpased","abandoned","on ground"), 0),
                  eggs = replace(eggs, eggs %in% c("no data","comment","lost flag","not checked",
                    "flag gone","c(na, na)","not found","not checkd","flag gone",
                    "not checked - whib in colony","missed","missed. pulled?",
                    "n/a see 376a","missed?","no longer on trail","nest missing","no nest","can't find",
                    "missed pulled","couldn’t check","too high","can't see","miss"), NA)) %>%
    dplyr::mutate(date = as.Date(date),
                  eggs = as.numeric(eggs),
                  chicks = as.numeric(chicks)) %>%
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
  