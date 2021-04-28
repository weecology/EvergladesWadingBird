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

all_data <- setNames(data.frame(matrix(ncol = 9, nrow = 0)), c("year", "colony", "nest", "species", "date",
                                                               "eggs", "chicks", "stage", "notes"))

tab_names <- readxl::excel_sheets(path = data_path)
tab_names <- tab_names[tab_names != "key"]
tab_names <- tab_names[!startsWith(tab_names ,"Other")]
tab_names <- tab_names[!startsWith(tab_names ,"Overview")]
tab_names <- tab_names[!startsWith(tab_names ,"Dataset Headers")]
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
  colnames2 <-  tolower(gsub("# ","", colnames2))
  colnames1 <- tolower(colnames1[1:length(colnames2)])
  colnames <- paste(colnames1, colnames2, sep = "_")
  colnames[1:2] <- c("nest", "species")
  colnames[length(colnames)] <- "notes"
  #names(data_raw[[i]]) <- colnames

  new_data_colony <- tolower(tab_names[i]) %>%
    gsub(" ", "_", .) %>%
    gsub("/.", "_", .) %>%
    gsub("\\.", "_", .) %>%
    gsub("-", "_", .) %>%
    gsub("_colony$","",.) %>%
    gsub("_$","",.)

  new_data <- as.data.frame(data_raw[[i]][,1:length(colnames)]) %>%
    setNames(colnames) %>%
    dplyr::slice(-c(1:2)) %>%
    tidyr::pivot_longer(cols = dplyr::starts_with(c("3", "4")), 
                        names_to = c("date","type"),
                        names_pattern = "(.*)_(.*)",
                        values_to = "count") %>%
    dplyr::mutate(date = as.Date(as.integer(date), origin="1899-12-30"), 
                  colony = new_data_colony,
                  colony = replace(colony, colony %in% 
                                     c("tam_west", "tamw2015","tamw","tamiami_west_(whib)",
                                       "tamiami_west_(new_trail)","tam_west_ibis_trail",
                                       "tamiami_west_east_side", "tamiami_west_west_side"), "tamiami_west"),
                  colony = replace(colony, colony=="6th_bridge_whib", "6th_bridge"),
                  colony = replace(colony, colony %in% c("alley_north_(trail_1)","alley_north_(trail_2)",
                                           "alley_north_west_side","alley_north_south", "an2015"), 
                                   "alley_north"),
                  colony = replace(colony, colony %in% c("big_pond_north_east"), "big_pond"),
                  colony = replace(colony, colony=="mud_canal_colony", "mud_canal"),
                  colony = replace(colony, colony=="paurotis_pond", "paurotis"),
                  colony = replace(colony, colony=="jarrod", "jerrod"),
                  colony = replace(colony, colony=="cypresscity", "cypress_city"),
                  colony = replace(colony, colony=="rookerybranch", "rookery_branch"),
                  colony = replace(colony, colony %in% c("l67_east_side", "l67_north_end", "l_67",
                                                         "horus_(l67)"), "horus"),
                  species = tolower(species),
                  type = tolower(type),
                  type = replace(type, type=="comments", "notes"),
                  year = year,
                  species = replace(species, species %in% c("tric","tche","trhe?"), "trhe"),
                  species = replace(species, species %in% c("?", "-","ge/nh?","ge/nh","unknown"), "unkn"),
                  species = replace(species, is.na(species), "unkn"),
                  species = replace(species, species %in% 
                                      c("smwh", "smwt (prob greg)","smwht","greg/smwh","swhe","smwh*"), 
                                    "smwt"),
                  species = replace(species, species %in% 
                                      c("small heron/cormorant","small heron","sh","sh/an","smda",
                                        "smhe*","bcnh or smhe"), "smhe"),
                  species = replace(species, species %in% c("an","anhg","anhi?",""), "anhi"),
                  species = replace(species, species %in% c("gi","gi?","smhe/glib"), "glib"),
                  species = replace(species, species %in% c("gb","gb (poss. ge)","gbhe?"), "gbhe"),
                  species = replace(species, species %in% c("whib?","wi", "whip","whib*"), "whib"),
                  species = replace(species, species %in% c("ge","greg?","greg/smhe?","greg/gbhe"), "greg"),
                  species = replace(species, species=="green heron", "grhe"),
                  species = replace(species, species %in% c("sneg?"), "sneg"),
                  species = replace(species, species %in% 
                                      c("smhe/greg/bcnh","smhe/bcnh","trhe/bcnh","trhe/bcnh?"), "bcnh"),
                  species = replace(species, species %in% c("whib/rospb","rops/greg"), "rosp")) %>%
    dplyr::filter(!is.na(nest), !(type == "notes" & is.na(count))) %>%
    tidyr::pivot_wider(names_from = type, values_from = count) %>%
    dplyr::mutate(eggs = tolower(eggs),
                  chicks = tolower(chicks),
                  stage = dplyr::case_when(chicks %in% 
                          c("nest gone","gone","flag pulled","empty,pulled","empty/ pulled","pulled","x",
                            "pulled flag","empty","fp","0/fp","0/ fp","empty/fp","-",
                             "c(\"x\", \"x\")","c(\"x\", \"0\")","c(\"x\", na)","c(\"0\", \"0\")","?",
                              "fledged","nnest gone","1dc","*") ~ "empty",
                           chicks %in% c("fail","failed") ~ "failed",
                           eggs %in% c("1 broken egg", "fail", "failed", "1 dead") ~ "failed",
                           eggs %in% c("nest gone","gone","flag pulled","empty, pulled","empty/ pulled",
                                       "pulled","x","pulled flag","empty","emty/pulled","empty/pulled","fp",
                                       "0/fp","destroyed","0/ fp","fallen down","empty/fp","-",
                                       "had been pulled","c(\"x\", na)","c(\"x\", \"x\")","c(\"x\", \"2\")",
                                       "c(\"0\", \"0\")","ir","80", "yes","?","nnest gone", "na","fallen") 
                                      ~ "empty",
                           eggs %in% c("fledged pulled", "fledged","fledge") ~ "fledged"),
                  chicks = replace(chicks, chicks %in% c("5(+1 dead chick on ground)"), 5),
                  chicks = replace(chicks, chicks %in% c("4(certain)","4*","8 total w/145",
                    "8 total w/143","4(+1 dead chick on ground)","c(\"4\", \"0\")","4 (1 wet)"), 4),
                  chicks = replace(chicks, chicks %in% c("3/fp","2-3","33","c(\"3\", na)",
                    "c(\"3\", \"3\")","3+","3 (1 wet)","c(\"3 (1 wet)\", \"2 (1 wet)\")","3(+1dead)",
                    "3(certain)","3 (in area)","3(2wet)","3(confirmed)","3 (double checked it is 3)",
                    "3 (1  wet)","4+","10 total w/ 128,130","10 total w 128, 126","10 total w/ 126, 130",
                    "3 (totally sure it is 3 and they cannot be from any other nest around)",
                    "3 (9 total 126/128/130)","(3 in area)","**","***","****","c(\"3\", \"0\")",
                    "3*","3 (1 week old)","3c/pulled","3(few days old)","3 (1 dead?)","3(1 wet)",
                    "3(sneg)","3(in canopy)","3 (very large","3 fledged","3 (1 hatch)","3(1 flew 10ft)",
                    "3(2 flying)","c(\"3\", \"-\")","c(\"3\", \"missed\")","3(4th on ground dead)",
                    "3(4th dead chick)","3(2 flew away)","3 ( 1 wet)"), 3),
                  chicks = replace(chicks, chicks %in% c("2?","2+","2 (sneg on ground)","2 (+1dead)",
                    "2 fledged","2 (both wet)","2 (1 wet)","2 (+1 dead)","2 (+1 long dead)","2 (2 wet)",
                    "2 greg +1 bcnh","c(\"2\", na)","2 (1wet)","2(+1 dead)","2(2wet)","2 (certain)",
                    "2 (big above nest)","2 (flew)","2 (around nest)","2 (2-3 days old)","2 or 3",
                    "c(\"2\", \"0\")","c(\"2\", \"1\")","2, pulled","2 ( 1 wet)","2 (wet?)","2(1 wet)",
                    "2*","2 (1 dead)","2+ in canopy","2+ (fledged)","2(in canopy)","2(fledged)",
                    "2 large","2(certain)","c(\"2\", \"missed\")","4total with 870","4total with 872",
                    "2(+3rd dead chick)","4 chicks shared","641 & 864","2(fledged in tree)","2 (pulled)"), 2),
                  chicks = replace(chicks, chicks %in% c("1alive,1dead","1?","1+","1 (wet)","1*","1(2)",
                    "1 fledged","note","1 (+1dead)","(1 long dead)","1(wet)","1 (1 wet)","1(+1 dead)",
                    "1 (+1 dead)","1(+1dead)","1(live) 1(dead)","1(ran)","1(dead) 1(alive)","1+ (+ 1 dead)",
                    "1+(flew out)","c(\"1\", \"1\")","c(\"1\", \"0\")","1(tiny)","1 (branchling)",
                    "1(hatching)","1c (dead)","(1 live) (1 dead)","1 (in tree)","1(in canopy)",
                    "1 (fledged)","1(ran away)","1+(in canopy)","1 (looks abandoned)","2 between 3 nests",
                    "1(certain)","c(\"1\", na)","c(\"1 (+1 dead)\", \"missed\")","1(dying, +1 dead chick)",
                    "1(flew away)","1 (+1 dead chick)","1(2nd dead chick)","1(+1 dead chick)","1(+2 dead)",
                    "1+ (pulled)"), 1),
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
                    "on ground","fledge?","c(na, \"empty\")","likely fledged","empty; pulled","fledge/pulled",
                    "fledged; pulled","0, flag gone","fledged, pulled","nest fell","gone, pulled",
                    "empty, pulled","empty, flag pulled","no birds, flag pulled, 1 bird in area",
                    "gone; pulled","gone/pulled","mt/pulled","mt?","235 & 237","mt/gone","mt(2 dead)",
                    "nest on ground","flag on ground","gone, flag pulled","2 dead chicks","1 (dead)",
                    "2 dead","mt(1 dead)","c(\"mt\", \"missed\")","1 dead","mt(nest fallen)",
                    "mt(1 dead chick)"), 0),
                  chicks = replace(chicks, chicks %in% 
                    c("no data","comment","lost flag","not checked","flag gone","c(na, na)", "not found",
                    "missed","c(\"not checked\", \"not checked\")","missd","missed or couldn't get to?",
                    "missing","missed in the notebook says wost  not greg","miss","missed, likely mt",
                    "missed?","na","n/a","c(\"n/a\", \"n/a\")","couldn't find",
                    "flag pulled, gone","flag not found","missed, no record","missed*"), NA),
                  eggs = replace(eggs, eggs %in% c("5 (2 pipping)"), 5),
                  eggs = replace(eggs, eggs %in% c("4 (1pipping)","4 (1p)","4(dead)","4 (1 pipping)",
                    "(4 anhi) pulled","c(\"4\", \"4\")","4 (greg)","4 (1 pip)","4 ( 1 pip)","4 (1 hatch)"
                    ), 4),
                  eggs = replace(eggs, eggs %in% c("c(\"3\", na)","3(1 pipping)","3 (1 pipping)",
                    "3 (2 pipping)","3 (1p)","c(\"3\", \"3\")","3(whib)","3(broken)","3(2 pipping)",
                    "3(1p)","3(pipping)","3 (1pip)","3 (1 pip)","3(pip)","3(glib)","3 (2 pip)",
                    "3 ( 1pip)","c(\"3\", \"-\")","3(1 pip)" ), 3),
                  eggs = replace(eggs, eggs %in% c("smhe(2 eggs)","2 (1p)","2(1 pipping)","2(renest)",
                    "2 (1 pipping)","2(broken)","2*","2 (1pipping)","2(pipping)","2(predated)",
                    "2 (pipping)","2 (anhi)","2 (wost)","c(\"2\", \"2\")","c(\"1\", \"2\")",
                    "3-4 branchlings b/t 8 and 10","2 (1 pip)","2 (1 hatching)","2(dead)","2 (glib)",
                    "2(glib)","2(trhe)","2 (1pip)","2 (dead)","c(\"2\", \"-\")","4 chicks between 844 & 846",
                    "7 chicks between 840, 830, 832","4 chicks between 641 & 864",
                    "5 chicks between 718 & 720"), 2),
                  eggs = replace(eggs, eggs %in% c("1 broken egg","1?","1 (old)","1 (1pipping)","1(1p)",
                    "1 (pippng)","(1 broken or pipping)","1( pipping)","1 old egg","(dead) 1","(dead)1",
                    "1(pipping)","1+","1(dead)","1 (dead)","1 (+1cracked)","(1 broken)","1(broken)",
                    "1 (pulled)","1 (pipping)","1 (dead, old)","1 (1p)","1 (cold)","c(\"1\", \"1\")",
                    "c(\"0\", \"1\")","1 (pip)","1 chick, either 18 or 77","1 + 1","1 (1 pip)",
                    "1(pip)","1(glib)","1 dead egg","1 (glib)","4 chicks between 366, 368, 370",
                    "3 chicks between 810, 812, 814","3 chicks between 824 & 826",
                    "2 chicks between 824 & 826","1*","2 chicks between 142 & 140"), 1),
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
                    "pull","126/128/130","0+","collpased","abandoned","on ground",
                    "*1 nest w/ 3 dead chicks, 1 nest w/ 2 dead chicks","feathers taken","fledge?",
                    "fledge","no birds, flag pulled, 1 bird in area","gone, pulled","empty, flag pulled",
                    "gone; pulled","fledged, pulled","nest fell","0, flag gone","fledged; pulled",
                    "fledge/pulled","empty; pulled","likely fledged","gone, flag pulled",
                    "flag pulled, gone","mt / pulled","gone/*1","pretty sure nest was empty on 3/10",
                    "mt (1 egg dead)","mt (1 dead egg)"), 0),
                  eggs = replace(eggs, eggs %in% c("no data","comment","lost flag","not checked",
                    "flag gone","c(na, na)","not found","not checkd","flag gone",
                    "not checked - whib in colony","missed","missed. pulled?",
                    "n/a see 376a","missed?","no longer on trail","nest missing","no nest","can't find",
                    "missed pulled","couldn’t check","too high","can't see","miss","n/a",
                    "c(\"n/a\", \"n/a\")","flagging gone","missed, no record","flag not found","missing",
                    "c(na, \"empty\")","couldn't find","flag on ground"), NA)) %>%
    dplyr::mutate(date = as.Date(date),
                  eggs = as.character(eggs),
                  chicks = as.character(chicks)) %>%
    dplyr::select(year, colony, nest, species, date, eggs, chicks, stage, notes)

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
  