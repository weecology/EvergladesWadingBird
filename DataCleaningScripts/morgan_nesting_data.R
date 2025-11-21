
# Morgan nesting data -----------------------------------------------------
library('tidyverse')
library('survival')
library("survminer")



# Ok, here's my wood stork initiation date work! It's notready for the repo quite yet. Colony 
# names are not standardized with our list, for exmaple and there should be consistency with 
# and across source columns! but I think in general dates are ready to go.
# WoodStork_dates: this is all the colony-level data I could glean. It includes flight date of 
# the observation, previous flight (when presumably no storks were nesting), the colony name, 
# the source of the info, the observation made (incubating, nest starts, paired) and any other 
# pieces of info useful for figuring out when in the month the first eggs were probably laid.
# stork_initiation_revised: I sourced what I could and fixed errors when I saw them. I changed 
# the date column to the date of observation (which is not the same as date of first lay). When 
# possible, I id'd to colony, but if a year had little information then I went with the existing 
# date score and just left source blank. Sometimes sources will say region, but not colony and 
# sometimes it's possible to rule out regions (no storks) to infer region. I stuck "other 
# similar timed colonies in a separate column. We need to figure out what to do about that. 
# My choice when there were several is arbitrary.
# Wood Stork Initiation Rules: this records the rules I eventually devised/inferred from 
# pouring over the records. What people were doing changed over time, so a lot of my 
# changes to the initiation date are small changes that just enforce standardization on 
# what is early, mid, or late month and how to translate between the observed nest state 
# and egg lay estimation.
# Someone needs to adopt these files and get them repo ready. I'd do it but I have already 
# pushed back some deadlines to finish this up! We can chat in Everglades about this if 
# people have questions (not this monday because there's a faculty meeting). Oh, and feel 
# free to change file names. I'm not wedded to these.




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




wost_initiate_df2 <- readxl::read_excel('Nesting/WoodStork_dates.xlsx')%>% 
  as_tibble() 
# check with glenda about the colony names 

col_name <- read.csv('SiteandMethods/colonies.csv')




#make colony column key to colonies.csv for EvergladesWadingBirds
wost_initiate_df2 <-  wost_initiate_df2 |> 
  mutate(colony = str_replace_all(Colony_sheet, "Tamiami West",'tamiami_west') , 
         colony = str_replace_all(colony, "Paurotis Pond",'paurotis_pond') , 
         colony = str_replace_all(colony, "Rogers River Bay",'rodgers_river_bay') , 
         colony = str_replace_all(colony, "Crossover",'crossover') , 
         colony = str_replace_all(colony, "2B stork",'melaleuca_2b') , 
         colony = str_replace_all(colony, "Jetport new",'jetport_new'), 
         colony = str_replace_all(colony, "1083",'1083') , 
         colony = str_replace_all(colony, "Corkscrew Swamp",'corkscrew') , 
         colony = str_replace_all(colony, "2004 new colony3",'lox111'), 
         colony = str_replace_all(colony, "2004 new colony8",'otter_creek'), 
         colony = str_replace_all(colony, "Cuthbert",'cuthbert_lake'), 
         colony = str_replace_all(colony, "3B Mud East",'mud_east'), 
         colony = str_replace_all(colony, "Jetport",'jetport'), 
         colony = str_replace_all(colony, "Lox New Colony 4",'lox_nc4'), #either "New Col4" (?) or more recently lox_nc4 - 2009-03-21 put down lucky13
         colony = str_replace_all(colony, "Tamiami East 2",'tamiami_east'), 
         colony = str_replace_all(colony, "Grossman Ridge West",'grossman_ridge_west'), 
         colony = str_replace_all(colony, "Jetport South",'jetport_south'), 
         colony = str_replace_all(colony, "Kinich",'kinich'), 
         colony = str_replace_all(colony, "Cabbage Bay",'cabbage_bay'), 
         colony = str_replace_all(colony, "Lostmans Creek",'lostmans_creek'), 
         colony = str_replace_all(colony, "Broad River",'broad_river'), 
         colony = str_replace_all(colony, "Cypress City",'cypress_city'), 
         colony = str_replace_all(colony, "Colony 013",'lucky13'),             #either 13 (?) or lucky13 put down lucky13
         colony = str_replace_all(colony, "Jetport New",'jetport_new'), 
         colony = str_replace_all(colony, "Lox11",'lox11'), 
         colony = str_replace_all(colony, "Hidden",'hidden'), 
         colony = str_replace_all(colony, "Clyde Butcher",'clyde_butcher'), 
         .before = source      
  ) |> 
   mutate(part_of_project = if_else(colony == 'corkscrew' | colony == 'clyde_butcher', 
                                    'n', 'y')) 
# Michael:    
# 2b stork -> melaleuca_2b
# 2004 new colony8 -> otter creek
# Lox new colony4 -> either New Col4 or more recently Lox_nc4
# Colony 013 -> either 13 or lucky13
# *note: I couldn't find the source of 'Colony 013' so went through the data of 2017 and 2018 and found a colony '13' with WOST so I'm assuming they are all one and the same

wost_initiate_df2[str_detect(wost_initiate_df2$colony, "9999"),] |> pull(Colony_sheet)
  # write.csv('output/WoodStork_dates_colony_names_missing.csv')



#   wost_initiate_df2$Flight_first_nest_obs
# 
# 
# write.csv(wost_initiate_df2, 'output/WoodStork_dates_colony_names.csv')
# 
# 
# depth_inland <- read.csv('data/inlandenp_depth_data.csv',
#                          header = TRUE) %>% 
#   as_tibble() %>% 
#   mutate(time = as.Date(time),
#          month = month(time))



#grab max colony to know few / some nesting numbers 

# 
# 
# function(Flight_first_nest_obs, previous_flight, stage){
#   
#   if (stage == 'unkown'){
#     if (is.na(previous_flight)) {
#       Nest_I <- Flight_first_nest_obs
#     }
#     else {
#       Nest_I <-  mean(Flight_first_nest_obs, previous_flight, na.rm = TRUE)
#     }
#   }
#   
#   if(str_detect(stage, 'paired') | 
#      str_detect(stage, 'starts') ){
#     Nest_I <- Flight_first_nest_obs
#   }
#   
#   if (stage == 'incubating'){
#     if (is.na(notes)){
#       Nest_I <- Flight_first_nest_obs
#     }
#     else (str_detect(notes,'few')){
#       Nest_I <- Flight_first_nest_obs
#     }
#     else () { #something here on high amount of nests seen 
#       
#     } 
#   }
# }
# 



# days past Nov1 ----------------------------------------------------------

nest <- wost_initiate_df2 %>% 
  select(-notes) %>% 
  #days from Nov 1
  mutate(Flight_first_nest_obs = as.Date(Flight_first_nest_obs), #fligth_first... will be renamed to initaition_date
         test = if_else(month(Flight_first_nest_obs)<6, 
                        year(Flight_first_nest_obs)-1, 
                        year(Flight_first_nest_obs)),
         Nov1 = as.Date(paste(test, "11-1", sep = '-')), 
         days_past_NOV1 = as.numeric(Flight_first_nest_obs - Nov1), 
         status = 1, 
         month = factor(month(Flight_first_nest_obs)),
         time = Flight_first_nest_obs) %>% 
  select(-c(test, Nov1))

as.Date('2025-11-01') + max(nest$days_past_NOV1)

ggplot(data = nest,aes(days_past_NOV1))+
  geom_histogram(aes(y=..density..))+
  geom_density()






wost<- depth_inland %>% 
  left_join(nest, 
            join_by(time)) %>% 
  mutate(months = month(time), 
         weeks = week(time),
         day = day(time),
         event = as.Date(paste(year-1,'11','1', sep ='-'))) %>% 
  group_by(year, Colony_sheet) %>% 
  mutate(days_pastNOV1 = time - event,
         days_pastNOV1 = if_else(days_pastNOV1 < 0, NA, days_pastNOV1),       #0days before nov1
         days_pastNOV1 = if_else(days_pastNOV1 > 200, NA, days_pastNOV1),     #183 days (6month) after nov1
         days_pastNOV1 = as.numeric(days_pastNOV1)+1) %>% 
  replace_na(list(status = 0))



wost_df <- wost %>% 
  group_by(year(time), Colony_sheet) %>% 
  mutate(week = week(time),
         mean_depth = mean(avg_depth),
         max_depth = max(avg_depth), 
         min_depth = min(avg_depth)) %>% 
  ungroup() %>% 
  mutate( drawd_1 = lag(avg_depth, 1) - avg_depth,
          drawd_2 = lag(avg_depth, 2) - avg_depth,
          drawd_3 = lag(avg_depth, 3) - avg_depth,
          drawd_4 = lag(avg_depth, 4) - avg_depth,
          drawd_7 = lag(avg_depth, 7) - avg_depth,
          drawd_14 = lag(avg_depth, 14) - avg_depth,
          wet_season = lag(avg_depth, 180),
          two_month = lag(avg_depth, 60))  












