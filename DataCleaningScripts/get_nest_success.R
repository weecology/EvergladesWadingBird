library(dplyr)
library(tidyr)
library(stringr)
library(openxlsx)

colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")
this_year <- 2025
source("DataCleaningScripts/mayfield.R")

# Create nest success data from raw nest check data and format for review

nest_checks <- read.csv("Nesting/nest_checks.csv") %>% filter(year==this_year) %>%
  group_by(year,colony,nest,species)

mayfield <- mayfield(this_year)

unique_dates <- nest_checks %>% distinct(date) %>% pull(date) %>% sort()
date_order <- outer(unique_dates, c("eggs", "chicks", "stage"), paste, sep = "_") %>% 
  t() %>% 
  as.vector()

nest_table <- nest_checks %>% 
  pivot_wider( 
    names_from = date, 
    values_from = c(eggs, chicks, stage), 
    names_glue = "{date}_{.value}" ) %>% 
  full_join(mayfield, by = c("year","colony","nest" = "nest_number", "species")) %>%
  dplyr::rename(incubation_days = n_days_incubation, nestling_days = n_days_nestling) %>%
  select(year, colony, nest, species, nobs, clutch, brood, fledged, lay_date, hatch_date,
         incubation_days, incubation_success, nestling_days, nestling_success, young_lost,
         all_of(date_order), notes)

success_table <- success(this_year, mayfield)

# Write workbook for review
split_names <- strsplit(colnames(nest_table), "_")
dates <- sapply(split_names, `[`, 1)  
subheaders <- sapply(split_names, `[`, 2) 

wb <- createWorkbook()
addWorksheet(wb, "Mayfield")

# Define formatting styles
date_style <- createStyle(
  halign = "center", valign = "center", 
  textDecoration = "bold", fgFill = "#DCE6F1", border = "TopBottomLeftRight"
)
sub_style <- createStyle(
  halign = "center", textDecoration = "bold", 
  border = "bottom", fgFill = "#F2F2F2"
)

# 5. Dynamically write and merge Date Headers (Row 1)
# Find unique dates and their structural column spans
unique_dates <- unique(dates)

for (d in unique_dates) {
  # Find all column indexes belonging to this specific date
  col_indices <- which(dates == d)
  start_col <- min(col_indices)
  end_col <- max(col_indices)
  
  # Write the date to the first cell of the block
  writeData(wb, "Mayfield", x = d, startCol = start_col, startRow = 1)
  
  # Only merge if there are multiple columns for this date
  if (start_col < end_col) {
    mergeCells(wb, "Mayfield", cols = start_col:end_col, rows = 1)
  }
}
addStyle(wb, "Mayfield", style = date_style, rows = 1, cols = 1:ncol(nest_table), gridExpand = TRUE)
subheaders_nest_table <- as.data.frame(t(subheaders))
writeData(wb, "Mayfield", x = subheaders_nest_table, startCol = 1, startRow = 2, colNames = FALSE)
addStyle(wb, "Mayfield", style = sub_style, rows = 2, cols = 1:ncol(nest_table), gridExpand = TRUE)
writeData(wb, "Mayfield", x = nest_table, startCol = 1, startRow = 3, colNames = FALSE)

addWorksheet(wb, "Success")
writeData(wb, "Success", x = success_table, startCol = 1, startRow = 1, colNames = TRUE)

saveWorkbook(wb, "~/Desktop/mayfield_2025.xlsx", overwrite = TRUE)

###
# Reshape and clean nest success data from handmade excel files
# Clean and append new nest success data
nest_success <- read.csv("Nesting/nest_success.csv")

filepath <- "~/Desktop/Mayfield_Calender_2025.xlsx"

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
success_summary_new <- readxl::read_excel(path = "~/Desktop/Mayfield_Calculations_2025.xlsx", 
                                          sheet = 1, col_names = TRUE) %>%
  dplyr::rename_with(tolower) %>%
  dplyr::mutate(colony = tolower(colony), 
                metric = tolower(metric)) %>%
  dplyr::mutate(dplyr::across(.cols = c(metric),
           .fns = ~ stringr::str_replace_all(., pattern = "[\\(\\)\\s]+", replacement = ""))) %>%
  tidyr::pivot_longer(cols = !c(year,colony,stage,metric), 
                      names_to = "species",
                      values_to = "value") %>%
  dplyr::mutate(metric = paste(stage,"_",metric,sep="")) %>%
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

