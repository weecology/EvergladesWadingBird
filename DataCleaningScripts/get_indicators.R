library(dplyr)
source("DataCleaningScripts/clean_counts.R")
datayear <- 2024
colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")

data_path <- "~/Dropbox (UFL)/Everglades/Reports/2022 Reports/Final Report Work/Final Report Work_2022/WBPOP_2022_Lindsey takeover.xls"
tab_names <- readxl::excel_sheets(path = data_path)

# add stork initiation
stork_initiation <- read.csv("Indicators/stork_initiation.csv") %>% 
  add_row(year = datayear, initiation = "2024-02-15", date_score = 2.0, days_past_nov_1 = 107)
write.table(stork_initiation, "Indicators/stork_initiation.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",")

# add supercolony interval


# add coastal nesting



max_count_raw <- readxl::read_excel(path = data_path, sheet = "WBPOP", 
                                col_names = TRUE, col_types = "text", skip=2) %>%
             select(-c(1,16:26),-27,-total) %>%
             rename(year=1)

max_count_all <- max_count_raw[16:52,] %>% mutate_if(is.character, as.numeric) %>%
                 filter(year==datayear) %>%
                 tidyr::gather(key="species",value="count",-year) %>%
                 mutate(region="all", species=tolower(species)) %>%
                 mutate(species = replace(species, species=="unident", "unkn")) %>%
                 select(year,region,species,count)

write.table(max_count_all, "Indicators/max_count_all.csv", 
            row.names = FALSE, col.names = FALSE, na = "", sep = ",", append=TRUE)

counts_data_path <- "~/Desktop/SFWMD Report_Table_2022_cleaned.xlsx"
colony_counts <- clean_count_data(counts_data_path,datayear)

counts <- colony_counts$new_data %>% dplyr::arrange()
write.table(counts, "Counts/maxcounts.csv", row.names = FALSE, col.names = FALSE, 
                                          na = "", sep = ",", append=TRUE, quote = 9)

enp <- readxl::read_excel(path = data_path, sheet = "enp", 
                          col_names = TRUE, col_types = "text") %>%
  dplyr::left_join(colonies[,1:2], by = dplyr::join_by(colony)) %>%
  
  dplyr::mutate(year = as.numeric(year),
                latitude = as.numeric(latitude),
                longitude = as.numeric(longitude),
                count = as.numeric(count)) %>%
       dplyr::select("group_id","year","colony","colony_old","latitude","longitude","species","count","notes")
print(unique(enp$colony[which(!(enp$colony %in% colonies$colony))]))
print(unique(enp$species[which(!(enp$species %in% species$species))]))
write.table(enp, "Counts/maxcounts.csv", row.names = FALSE, col.names = FALSE, 
            na = "", sep = ",", append=TRUE, quote = 9)

under_40 <- colony_counts$under_40 %>% dplyr::arrange()
write.table(under_40, "Counts/maxcounts_under40.csv", row.names = FALSE, col.names = FALSE, 
            na = "", sep = ",", append=TRUE, quote = 28)

colonies <- colony_counts$new_colonies %>% dplyr::arrange(colony)
write.table(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, col.names = FALSE, 
            na = "", sep = ",", append=TRUE, quote = c(7,8))

