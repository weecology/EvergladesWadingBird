# Complete Wood Stork nest initiation data
# Compiled by SKM Ernest

library('tidyverse')
library('survival')
library("survminer")

# Colony-level data gleaned from SFWB reports and data sheets. It includes flight date of 
# the observation, previous flight (when presumably no storks were nesting), the colony name, 
# the source of the info, the observation made (incubating, nest starts, paired) and any other 
# pieces of info useful for figuring out when in the month the first eggs were probably laid.

# Wood Stork Initiation Rules: this records the rules I eventually devised/inferred from 
# pouring over the records. What people were doing changed over time, so a lot of my 
# changes to the initiation date are small changes that just enforce standardization on 
# what is early, mid, or late month and how to translate between the observed nest state 
# and egg lay estimation.

# Wood Stork Nest Initiation "Rules"
# Time Period Definitions
# early: 1-9
# mid: 10th-20nd (15th +/- 5 days)
# late: 21st-end
# If flight observation is:
#   paired or nest starts, assume incubation occurred shortly thereafter. Therefore use date 
# to set early, mid, late. If date on edge time periods, then push to next time period.
# incubating, but only a few seen, then assume these are your first egg lays and was recent. 
# Choose flight date to set time period
# incubating but many are incubating, then assume observation is occurring after first egg lay. 
# remove two weeks from date and set time period
# incubating but no info, then flight date sets time period
# young/small chicks, then remove 1 month from observation date and set time period
# young storks moving on/off nests, then remove 90 days
# unknown state - if only know nests seen and not other info, then choose midpoint between 
# flights. If no earlier flight conducted, then date sets time period unless on border between 
# time periods, then push to earlier time period.
# If the person who saw the nest disagrees with the assessment, then we can change time period. 
# We just need to document in notes why they thought it was mid/early/late instead of what our 
# rule set would suggest.


colonies <- read.csv('SiteandMethods/colonies.csv')

wost_initiate_df <-  readxl::read_excel('Nesting/WoodStork_dates.xlsx') |>
  rename_with(tolower) |>
  mutate(colony = colony_sheet, 
         colony = tolower(colony),
         colony = gsub(" ", "_", colony),
         colony = str_replace_all(colony, "rogers_river_bay",'rodgers_river_bay'),
         colony = str_replace_all(colony, "1083",'1083'), 
         colony = str_replace_all(colony, "colony_013",'colony13'),   
         colony = str_replace_all(colony, "corkscrew_swamp",'corkscrew'), 
         colony = str_replace_all(colony, "2004_new_colony3",'lox111'), 
         colony = str_replace_all(colony, "2004_new_colony8",'otter_creek'), #Michael
         colony = str_replace_all(colony, "cuthbert",'cuthbert_lake'), 
         colony = str_replace_all(colony, "3b_mud_east",'mud_east'), 
         colony = str_replace_all(colony, "lox_new_colony_4",'lox_nc4'),
         colony = str_replace_all(colony, "tamiami_east_2",'tamiami_east'),
         colony = str_replace_all(colony, "clyde_butcher",'butcher'),
         colony = str_replace_all(colony, "2b_stork",'melaleuca_2b') #Michael
         ) |>
  rename(colony_old=colony_sheet) |>
  select("year","flight_first_nest_obs","previous_flight","date_score","colony",
         "colony_old","stage","source","notes")

print(unique(wost_initiate_df$colony[which(!(wost_initiate_df$colony %in% colonies$colony))]))
print(unique(wost_initiate_df$year[which(!(lubridate::year(wost_initiate_df$flight_first_nest_obs) == wost_initiate_df$year))]))
print(unique(wost_initiate_df$year[which(!(lubridate::year(wost_initiate_df$previous_flight) == wost_initiate_df$year))]))

write.table(wost_initiate_df, 'Nesting/woodstork_dates.csv', 
            row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = c(9))
