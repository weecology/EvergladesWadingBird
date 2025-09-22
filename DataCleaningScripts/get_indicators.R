library(dplyr)

datayear <- 2025

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  mutate(group_id = as.numeric(group_id),
         latitude = as.numeric(latitude),
         longitude = as.numeric(longitude))

counts <- read.csv("Counts/maxcounts.csv")

groundcounts <- read.csv("Counts/ground_counts.csv")

# data_path <- "~/Dropbox (UFL)/Everglades/Reports/2022 Reports/Final Report Work/Final Report Work_2022/WBPOP_2022_Lindsey takeover.xls"
# tab_names <- readxl::excel_sheets(path = data_path)

# add stork initiation
stork_initiation <- read.csv("Indicators/stork_initiation.csv") %>% 
  add_row(year = datayear, initiation = "2025-02-03", 
          date_score = 2.5, 
          days_past_nov_1 = 94,
          region = "inlandenp",
          colony = "cabbage_bay")
write.table(stork_initiation, "Indicators/stork_initiation.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",")

# add supercolony interval
ibis_total <- counts %>% filter(year==datayear, species=="whib") %>% summarise(sum(count))
ibis_total > 16977

stork_total <- counts %>% filter(year==datayear, species=="whib") %>% summarise(sum(count))
stork_total > 1458

supercolony_interval <- read.csv("Indicators/supercolony_interval.csv") %>% 
  add_row(year = datayear, ibis_interval = 1, stork_interval = 1)
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
new_groundcounts <- groundcounts %>% 
                    filter(year==datayear,
                           species %in% 
                             c("greg","whib","anhi","gbhe","trhe","bcnh","sneg","lbhe")) %>%
                    group_by(year,species) %>%
                    summarise(count = sum(count, na.rm=TRUE)) %>%
                    pivot_wider(names_from = species, values_from = count)

groundcounts_table <- read.csv("Counts/groundcounts_table.csv") %>%
  bind_rows(new_groundcounts) %>%
  arrange(-year)

write.table(groundcounts_table, "Counts/groundcounts_table.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",")

# add max count summary
counts_total <- counts %>%
                filter(year==datayear) %>%
                group_by(year,species) %>%
                summarise(count = sum(count))
under40 <- read.csv("Counts/maxcounts_under40.csv") %>%
           filter(year==datayear) %>%
           group_by(year,species) %>%
           summarise(count = sum(count, na.rm=TRUE)) 
max_count_all <- bind_rows(counts_total,under40) %>%
                 group_by(year,species) %>%
                 summarise_all(., sum, na.rm = TRUE)
total <- sum(max_count_all$count)
max_count_all <- max_count_all %>% ungroup() %>%
                 add_row(year=datayear, species = "total", count=total) %>%
                 mutate(region="all") %>%
                 select(year,region,species,count)

write.table(max_count_all, "Indicators/max_count_all.csv", 
            row.names = FALSE, col.names = FALSE, na = "", sep = ",", append=TRUE, quote = FALSE)
