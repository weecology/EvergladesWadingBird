library(dplyr)
colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")

data_path <- "~/Dropbox (UFL)/Everglades/Reports/2022 Reports/Final Report Work/Final Report Work_2022/WBPOP_2022_Lindsey takeover.xls"
tab_names <- readxl::excel_sheets(path = data_path)

max_count <- readxl::read_excel(path = data_path, sheet = "WBPOP", 
                                col_names = TRUE, col_types = "text", skip=2) %>%
             select(-1)
