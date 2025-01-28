library(dplyr)
source("DataCleaningScripts/clean_counts.R")
datayear <- 2024
colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")
counts <- read.csv("Counts/maxcounts.csv")

data_path <- "~/Dropbox (UFL)/Everglades/Reports/2022 Reports/Final Report Work/Final Report Work_2022/WBPOP_2022_Lindsey takeover.xls"
tab_names <- readxl::excel_sheets(path = data_path)

# add stork initiation
stork_initiation <- read.csv("Indicators/stork_initiation.csv") %>% 
  add_row(year = datayear, initiation = "2024-02-15", date_score = 2.0, days_past_nov_1 = 107)
write.table(stork_initiation, "Indicators/stork_initiation.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",")

# add supercolony interval
ibis_total <- counts %>% filter(year==datayear, species=="whib") %>% summarise(sum(count))
ibis_total > 16977
supercolony_interval <- read.csv("Indicators/supercolony_interval.csv") %>% 
  add_row(year = datayear, ibis_interval = 2)
write.table(supercolony_interval, "Indicators/supercolony_interval.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",")

# add coastal nesting
count_total <- counts %>% filter(year==datayear) %>% summarise(sum(count))
coastal_total <- counts %>% filter(year==datayear) %>% left_join(colonies) %>%
               filter(subregion=="coastalenp") %>% summarise(sum(count))

coastal_nesting <- read.csv("Indicators/coastal_nesting.csv") %>% 
  add_row(year = datayear, total = as.integer(count_total), coastal = as.integer(coastal_total), 
          proportion = coastal/total)

write.table(coastal_nesting, "Indicators/coastal_nesting.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",")

# add max count summaries
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
