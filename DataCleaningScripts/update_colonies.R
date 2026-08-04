library(dplyr)

colonies <- read.csv("SiteandMethods/colonies.csv")

colonies_update <- colonies %>% mutate(across(c("group_id","latitude","longitude"), as.numeric))

colonies_update[521,] <- c(4002, "indri", "3", "3as", 25.839514,	-80.710322, "142", "Indri")
colonies_update[522,] <- c(4003, "emperor_tamarin", "3", "3as", 26.025436, -80.604282, "143", "Emperor Tamarin")
colonies_update[523,] <- c(4004, "gibbon", "3", "3as", 25.891929,	-80.668708, "145", "Gibbon")
colonies_update[524,] <- c(4005, "mandrill", "3", "3as", 26.261856, -80.374889, "146", "Mandrill")
colonies_update[525,] <- c(4006, "napo_saki", "3", "3ase", 26.082798,	-80.537597, "48", "Napo Saki")
colonies_update[526,] <- c(4007, "tarsier", "1", "1", 26.547925,	-80.429626, "106", "Tarsier")
colonies_update[527,] <- c(4008, "vervet", "1", "1", 26.456897,	-80.253913, "147", "Vervet")

colonies_update$colony[colonies_update$group_id==3700] = "yaku"
colonies_update$aka[colonies_update$group_id==3700] = c("3700,075,75")
colonies_update$display_name[colonies_update$group_id==3700] = "Yaku"

## Write new table
colonies_update <- colonies_update %>% 
  dplyr::mutate(dplyr::across(c("group_id","latitude","longitude"), as.numeric)) %>%
  dplyr::arrange(group_id)

write.table(colonies_update, "SiteandMethods/colonies.csv", 
  sep = ",", row.names = FALSE, na = "", quote = c(7,8))

#################################################################################################
## If there are any colony name changes, update counts as well

imagecounts <- read.csv("Counts/image_counts.csv")
flightsurveys <- read.csv("Counts/flight_surveys.csv")
maxcounts <- read.csv("Counts/maxcounts.csv")

maxcounts <- maxcounts %>%
  mutate(colony = replace(colony, colony=="3700","yaku"),
         colony = replace(colony, colony_old=="48","napo_saki"))
flightsurveys <- flightsurveys %>%
  mutate(colony = replace(colony, colony=="3700","yaku"),
         colony = replace(colony, colony_old=="48","napo_saki"))

imagecounts <- imagecounts %>%
  mutate(colony = replace(colony, colony=="3700","yaku"),
         colony = replace(colony, colony_old=="48","napo_saki"))

print(unique(flightsurveys$colony[which(!(flightsurveys$colony %in% colonies_update$colony))]))
print(unique(imagecounts$colony[which(!(imagecounts$colony %in% colonies_update$colony))]))
print(unique(maxcounts$colony[which(!(maxcounts$colony %in% colonies_update$colony))]))

## Write tables
maxcounts <- maxcounts %>% dplyr::arrange(year,group_id)
write.table(maxcounts, "Counts/maxcounts.csv", row.names = FALSE, na = "", sep = ",", quote = 9)

imagecounts <- imagecounts %>% 
  distinct() %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric),
         date = as.Date(date)) %>% 
  arrange(year,date,colony,species)

write.table(imagecounts, "Counts/image_counts.csv", row.names = FALSE,
            na = "", sep = ",", quote = c(9,14))

flightsurveys <- flightsurveys %>% 
  distinct() %>%
  mutate(across(c("year","latitude","longitude","count"), as.numeric),
         date = as.Date(date)) %>% 
  arrange(year,date,colony,species)

write.table(flightsurveys, "Counts/flight_surveys.csv", 
            row.names = FALSE, na = "", sep = ",", quote = c(11,17))
