library(dplyr)

datayear <- 2026

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
  add_row(year = datayear,
          date_observed = "2026-02-20",
          initiation_month = "February",
          date_score = 2,
          region = "coastalenp",
          colony = "cuthbert_lake",

          nest_observation = "eggs",
          source = "email")
write.table(stork_initiation, "Indicators/stork_initiation.csv", row.names = FALSE, 
            col.names = TRUE, na = "", sep = ",", quote = 12)

# add other wood stork colonies
stork_dates <- read.csv("Nesting/woodstork_dates.csv") %>% 
  add_row(year = datayear,
          flight_first_nest_obs = "2026-03-06",
          date_score = 1.5,
          colony = "paurotis_pond",
          colony_old = "Paurotis Pond",
          stage = "incubating",
          source = "Mark Cook",
          notes = "Mark Cook (SFWMD) first saw WOST at...Paurotis on March 4. Peak counts a combination of Mark Cook's and Katrina Scheiner (ENP)observations. WOST 3/6/2026. All adults gone by 4/3/2026)"
  ) %>%
  add_row(year = datayear,
          flight_first_nest_obs = "2026-03-11",
          date_score = 1.5,
          colony = "tamiami_west",
          colony_old = "Tamiami_West",
          stage = "incubating",
          source = "Katrina Scheiner",
          notes = "On March 11 the WOST Katrina Scheiner identified WOST sitting tightly on the nests, but no eggs or chicks were visible. Her last flight to that colony ended up being April 8, and she didn't see the WOST nests again on that visit"
  ) %>%
  add_row(year = datayear,
          flight_first_nest_obs = "2026-02-20",
          date_score = 2,
          colony = "cuthbert_lake",
          colony_old = "Cuthbert",
          stage = "eggs",
          source = "Mark Cook",
          notes = "Mark Cook took pictures on 2/20: 5 active nests, two of which have the nest contents visible and contain a single egg each. Birds were sitting on the 3 other nests. 3/6: Storks have started to nest...he estimated about 50 pairs, half of which are incubating. 85 WOST nests were present on 3/11/2026, some of which had already been abandoned with eggs remaining. All adults gone by 4/8/2026"
  ) %>%
  add_row(year = datayear,
          flight_first_nest_obs = "2026-03-06",
          date_score = 2,
          colony = "butcher",
          colony_old = "Clyde Butcher",
          stage = "incubating",
          source = "Mark Cook",
          notes = "Mark Cook observed Nests  on March 6 but had abandoned by April 3. M. Ernest: No other info but given 100 nests were identified without noting just pairing or nest starts, incubation is assumed and  rules make this just technically  mid Feb."
  )
          
write.table(stork_dates, "Nesting/woodstork_dates.csv", row.names = FALSE, 
  col.names = TRUE, na = "", sep = ",", quote = 9)

# add supercolony interval
ibis_total <- counts %>% filter(year==datayear, species=="whib") %>% summarise(sum(count))
ibis_total > 16977

stork_total <- counts %>% filter(year==datayear, species=="wost") %>% summarise(sum(count))
stork_total > 1458

supercolony_interval <- read.csv("Indicators/supercolony_interval.csv") %>% 
  add_row(year = datayear, ibis_interval = 2, stork_interval = 2)
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
cerp <- max_count_all %>%
  filter(species %in% c("greg", "sneg", "whib", "wost")) %>%
  summarize(count = sum(count, na.rm = TRUE))
max_count_all <- max_count_all %>% ungroup() %>%
                 add_row(year=datayear, species = "total", count=total) %>%
                 add_row(year=datayear, species = "cerp", count=cerp$count) %>%
                 mutate(region="all") %>%
                 select(year,region,species,count) %>% 
                 arrange(year,species)

write.table(max_count_all, "Indicators/max_count_all.csv", 
            row.names = FALSE, col.names = FALSE, na = "", sep = ",", append=TRUE, quote = FALSE)
