library(dplyr)

datayear <- 2024

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

# add ground count table
groundcounts <- read.csv("Counts/groundcounts.csv") %>%
  add_row(year=datayear, greg= 58, whib = 0, anhi = 275, gbhe = 421, 
                         trhe = 8, bcnh = 117, sneg = 5, lbhe = 116) %>%
  arrange(-year)

write.table(groundcounts, "Counts/groundcounts.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",")

# add max count summary
counts <- read.csv("Counts/maxcounts.csv") %>%
          filter(year==datayear) %>%
          group_by(year,species) %>%
          summarise(count = sum(count))
under40 <- read.csv("Counts/maxcounts_under40.csv") %>%
           filter(year==datayear) %>%
           select(-c(group_id,colony,colony_old,wca,latitude,longitude,total,notes)) %>%
           group_by(year) %>%
           summarise(across(where(is.numeric), \(x) sum(x, na.rm = TRUE))) %>%
           tidyr::pivot_longer(cols = !year, names_to = "species", values_to = "count")
max_count_all <- bind_rows(counts,under40) %>%
                 group_by(year,species) %>%
                 summarise_all(., sum, na.rm = TRUE)
total <- sum(max_count_all$count)
max_count_all <- max_count_all %>% ungroup() %>%
                 add_row(year=datayear, species = "total", count=total) %>%
                 mutate(region="all") %>%
                 select(year,region,species,count)

write.table(max_count_all, "Indicators/max_count_all.csv", 
            row.names = FALSE, col.names = FALSE, na = "", sep = ",", append=TRUE)
