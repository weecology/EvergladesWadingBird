#' Use to reshape and clean nest success data from field format
#'

`%>%` <- magrittr::`%>%`

#' Clean and append new nest success data
#'

colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")
nest_success <- read.csv("Nesting/nest_success.csv")

filepath <- "~/Desktop/Mayfield Calculations_2024.xlsx"

this_year <- 2024

all_data <- setNames(data.frame(matrix(ncol = 26, nrow = 0)), 
                     c("year","colony","nest_number","species", "n_days_incubation", 
                       "incubation_success", "n_days_nestling", "nestling_success",
                       "clutch", "brood", "fledged", "clutch_type", "young_lost", "real_success", 
                       "real_failure", "start_date", "end_date", "notes"))

tab_names <- readxl::excel_sheets(path = filepath)
tab_names <- tab_names[tab_names != "Calendar"]
tab_names <- tab_names[tab_names != "Codes"]
tab_names <- tab_names[tab_names != "Clutch and Fledged"]
tab_names <- tab_names[tab_names != "template"]
tab_names <- tab_names[!startsWith(tab_names ,"Other")]
tab_names <- tab_names[!startsWith(tab_names ,"Sheet")]
tab_names <- tab_names[!startsWith(tab_names ,"Overview")]
tab_names <- tab_names[!startsWith(tab_names ,"Dataset Headers")]

data_raw <- lapply(tab_names, function(x) readxl::read_excel(path = filepath, sheet = x, 
                                                             col_names = FALSE))
for(i in 1:length(tab_names)) {
  colnames <- tolower(as.character(data_raw[[i]][1,]))
  new_data <- as.data.frame(data_raw[[i]]) %>%
    setNames(colnames) %>%
    dplyr::slice(-c(1)) %>%
    dplyr::rename(year = year,
                  colony = colony,
                  nest_number = nest,
                  species = species,
                  n_days_incubation = "n(i)",
                  incubation_success = "s(i)", 
                  n_days_nestling = "n(n)",
                  nestling_success = "s(n)",
                  clutch = clutch,
                  brood = brood,
                  fledged = fledged, 
                  notes = "comments") %>%
    dplyr::mutate(clutch_type = NA,
                  young_lost = NA,
                  real_success = NA, 
                  real_failure = NA, 
                  start_date = NA, 
                  end_date = NA) %>%
    dplyr::select("year","colony","nest_number","species", "n_days_incubation", 
                  "incubation_success", "n_days_nestling", "nestling_success",
                  "clutch", "brood", "fledged", "clutch_type", "young_lost", "real_success", 
                  "real_failure", "start_date", "end_date", "notes")
  
  all_data <- rbind(all_data, new_data) }

  new_success <- all_data %>%
    dplyr::filter_all(dplyr::any_vars(!is.na(.))) %>%
    dplyr::mutate(year=as.integer(this_year),
                  colony = tolower(colony),
                  colony = gsub(" ", "_", colony),
                  colony = gsub("/", "_", colony),
                  colony = gsub("-", "_", colony),
                  colony = gsub("'", "", colony),
                  species = tolower(species),
                  species = gsub(" ", "", species),
                  species = gsub("*", "", species),
                  species = gsub("?", "", species),
                  colony = replace(colony, colony %in% c("mud_canal","mud"), "mud_canal_south"),
                  species = replace(species, species %in% c("ge","greg/smhe?"), "greg")) %>%
    dplyr::mutate_at(c("n_days_incubation","incubation_success","n_days_nestling",
                       "nestling_success","clutch","brood","fledged","clutch_type","young_lost",
                       "real_success","real_failure"), as.numeric) %>%
    dplyr::arrange(year,colony,species) 

unique(new_success$colony[which(!(new_success$colony %in% colonies$colony))])
unique(new_success$species[which(!(new_success$species %in% species$species))])
all(colnames(new_success)==colnames(nest_success))

write.table(new_success, "Nesting/nest_success.csv", row.names = FALSE, col.names = FALSE,
            append = TRUE, na = "", sep = ",", quote = 18)

#' Clean and append new nest success summary data
#' Pivots from a report table with species as columns and metrics as rows,
#' to data with species as rows and metrics as columns
#'
success_summary <- read.csv("Nesting/nest_success_summary.csv")
success_summary_new <- readxl::read_excel(path = "~/Desktop/Mayfield Table_2024.xlsx", 
                                          sheet = 1, col_names = TRUE) %>%
  dplyr::rename_with(tolower) %>%
  tidyr::pivot_longer(cols = !c(year,colony,metric), 
                      names_to = "species",
                      values_to = "value") %>%
  tidyr::pivot_wider(id_cols = c(year,colony,species), names_from = metric, values_from = value, 
                     values_fill = NA) %>%
  dplyr::mutate(year=as.integer(year)) %>% 
  dplyr::mutate_at(c("incubation_k","incubation_sumy","incubation_e","incubation_p","incubation_j",
                     "incubation_pj","incubation_varp","incubation_varpj","incubation_sdp",
                     "incubation_sdpj","nestling_k","nestling_sumy","nestling_e","nestling_p",
                     "nestling_j","nestling_pj","nestling_varp","nestling_varpj","nestling_sdp",
                     "nestling_sdpj","overall_p","overall_varp","overall_sd"), as.numeric) %>%
  tidyr::drop_na(incubation_k, incubation_sumy) %>% 
  dplyr::arrange(year,colony,species)

unique(success_summary_new$colony[which(!(success_summary_new$colony %in% colonies$colony))])
unique(success_summary_new$species[which(!(success_summary_new$species %in% species$species))])
all(colnames(success_summary_new)==colnames(success_summary))

write.table(success_summary_new, "Nesting/nest_success_summary.csv", row.names = FALSE, 
            col.names = FALSE, append = TRUE, na = "", sep = ",")

