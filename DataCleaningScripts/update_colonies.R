library(dplyr)

colonies <- read.csv("SiteandMethods/colonies.csv")

colonies_update <- colonies %>% mutate(across(c("group_id","latitude","longitude"), as.numeric))

colonies_update[353,] <- c(3829, "ilish", "3", "3as", 26.092255, -80.793275, "52", "Ilish")
colonies_update[354,] <- c(3830, "john_dory", "3", "3as", 26.025436, -80.604282, "59", "John Dory")
colonies_update[355,] <- c(3831, "fugu", "3", "3as", 25.894729, -80.737860, "84", "Fugu")
colonies_update[356,] <- c(3832, "sculpin", "2", "2a", 26.261856, -80.374889, "94", "Sculpin")
colonies_update[357,] <- c(3833, "vaquita", "1", "1", 26.409099, -80.247667, "100", "Vaquita")
colonies_update[358,] <- c(3834, "wahoo", "1", "1", 26.441343, -80.353406, "114", "Wahoo")
colonies_update[359,] <- c(3835, "cisco", "3", "3b", 25.818837, -80.645617, "129", "Cisco")
colonies_update[360,] <- c(3836, "sunfish", "3", "3as", 25.920977, -80.836285, "130", "Sunfish")
colonies_update[361,] <- c(3837, "inanga", "3", "3as", 25.955186, -80.671794, "131", "Inanga")
colonies_update[362,] <- c(3838, "yellowtail", "1", "1", 26.536000, -80.251507, "133", "Yellowtail")
colonies_update[363,] <- c(3839, "opaleye", "2", "2b", 26.141000, -80.386622, "127", "Opaleye")
colonies_update[364,] <- c(3840, "fierasfer", "3", "3as", 25.878111, -80.757664, "135", "Fierasfer")
colonies_update[365,] <- c(3841, "sailfish", "2", "2a", 26.304002, -80.357549, "136", "Sailfish")
colonies_update[366,] <- c(3842, "spiderfish", "2", "2a", 26.306462, -80.413464, "137", "Spiderfish")
colonies_update[367,] <- c(3843, "lox_northwest", "1", "1", 26.621376, -80.419531, "138", "Lox Northwest")
colonies_update[368,] <- c(3844, "darter", "3", "3b", 25.840125, -80.487295, "144", "Darter")
colonies_update[369,] <- c(3845, "3b_ramp_west", "3", "3b", 25.784512, -80.519377, "", "3b Ramp West")
colonies_update[370,] <- c(3846, "carp", "3", "3b", 25.826825, -80.644174, "092,92", "Carp")
colonies_update <- colonies_update[-which(colonies_update$colony=="tyger_south"),]
colonies_update <- colonies_update[-which(colonies_update$colony=="lox73_out"),]
colonies_update <- colonies_update[-which(colonies_update$colony=="2568"),]
colonies_update[368,] <- c(3847, "tyr_south", "1", "1", 26.368446, -80.262532, "", "Tyr South")
colonies_update[369,] <- c(3848, "flatfish", "3", "3b", 25.903412, -80.543232, "", "Flatfish")
colonies_update[370,] <- c(3849, "fangtooth", "3", "3b", 25.924610, -80.478789, "", "Fangtooth")
colonies_update[371,] <- c(3850, "noodlefish", "3", "3as", 26.112358, -80.629340, "141", "Noodlefish")
colonies_update[372,] <- c(3851, "icefish", "3", "3as", 26.127201, -80.745256, "61", "Icefish")
colonies_update[373,] <- c(3852, "vanjaram", "1", "1", 26.477190, -80.238510, "river_east/142", "Vanjaram")
colonies_update[374,] <- c(3853, "walleye", "1", "1", 26.504383, -80.312849, "Volts,95,095", "Walleye")

colonies_update <- colonies_update[-which(colonies_update$colony=="3311"),]

colonies_update$colony[colonies_update$group_id==3667] = "yellow_bass"
colonies_update$aka[colonies_update$group_id==3667] = c("104,56,056,104/56,104_56,193,3667")
colonies_update$display_name[colonies_update$group_id==3667] = "Yellow Bass"
colonies_update$aka[colonies_update$group_id==3788] = "button,6"
colonies_update$aka[colonies_update$group_id==2574] = "tyger_south,tyger_west"
colonies_update$aka[colonies_update$group_id==2571] = "Lox 73,Lox 73/Tyr,Tyr,lox73_out"
colonies_update$colony[colonies_update$group_id==2567] = "trout"
colonies_update$latitude[colonies_update$group_id==2567] = 26.367646
colonies_update$longitude[colonies_update$group_id==2567] = -80.257345
colonies_update$aka[colonies_update$group_id==2567] = "2567,2568"
colonies_update$display_name[colonies_update$group_id==2567] = "Trout"
colonies_update$aka[colonies_update$group_id==1513] = "79"
colonies_update$colony[colonies_update$group_id==3310] = "velvetfish"
colonies_update$aka[colonies_update$group_id==3310] = "3310,3311,96075,94002"
colonies_update$display_name[colonies_update$group_id==3310] = "Velvetfish"

## Write new table
colonies_update <- colonies_update %>% 
  dplyr::mutate(dplyr::across(c("group_id","latitude","longitude"), as.numeric)) %>%
  dplyr::arrange(group_id)

write.csv(colonies_update, "SiteandMethods/colonies.csv", row.names = FALSE, na = "", quote = c(7,8))

#################################################################################################
## If there are any colony name changes, update counts as well

imagecounts <- read.csv("Counts/image_counts.csv")
flightsurveys <- read.csv("Counts/flight_surveys.csv")
maxcounts <- read.csv("Counts/maxcounts.csv")

maxcounts <- maxcounts %>%
              mutate(colony = replace(colony, colony=="3667","yellow_bass"),
                     colony = replace(colony, colony=="tyger_south","tyger"),
                     colony = replace(colony, colony=="lox73_out","lox73"),
                     colony = replace(colony, colony %in% c("2567","2568"),"trout"),
                     colony = replace(colony, colony %in% c("3310","3311"),"velvetfish"))
flightsurveys <- flightsurveys %>%
  mutate(colony = replace(colony, colony=="3667","yellow_bass"),
         colony = replace(colony, colony=="tyger_south","tyger"),
         colony = replace(colony, colony=="lox73_out","lox73"),
         colony = replace(colony, colony %in% c("2567","2568"),"trout"),
         colony = replace(colony, colony %in% c("3310","3311"),"velvetfish"),
         colony = replace(colony, colony_old %in% c("52","52 (?)","052"),"ilish"),
         colony = replace(colony, colony_old=="59","john_dory"),
         colony = replace(colony, colony_old=="84","fugu"),
         colony = replace(colony, colony_old=="94","sculpin"),
         colony = replace(colony, colony_old=="100","vaquita"),
         colony = replace(colony, colony_old %in% c("114","114*"),"wahoo"),
         colony = replace(colony, colony_old=="129","cisco"),
         colony = replace(colony, colony_old=="130","sunfish"),
         colony = replace(colony, colony_old=="131","inanga"),
         colony = replace(colony, colony_old=="133","yellowtail"),
         colony = replace(colony, colony_old=="127","opaleye"),
         colony = replace(colony, colony_old=="135","fierasfer"),
         colony = replace(colony, colony_old=="136","sailfish"),
         colony = replace(colony, colony_old=="137","spiderfish"),
         colony = replace(colony, colony_old=="138","lox_northwest"),
         colony = replace(colony, colony_old=="144","darter"),
         colony = replace(colony, colony_old %in% c("092","92"),"carp"),
         colony = replace(colony, colony_old=="141","noodlefish"),
         colony = replace(colony, colony_old=="61","icefish"),
         colony = replace(colony, colony_old %in% c("142","river_east/142"),"vanjaram"),
         colony = replace(colony, colony_old %in% c("Volts","95","095"),"walleye"))

imagecounts <- imagecounts %>%
  mutate(colony = replace(colony, colony=="3667","yellow_bass"),
         colony = replace(colony, colony=="tyger_south","tyger"),
         colony = replace(colony, colony=="lox73_out","lox73"),
         colony = replace(colony, colony %in% c("2567","2568"),"trout"),
         colony = replace(colony, colony %in% c("3310","3311"),"velvetfish"),
         colony = replace(colony, colony_old %in% c("52","52 (?)","052"),"ilish"),
         colony = replace(colony, colony_old=="59","john_dory"),
         colony = replace(colony, colony_old=="84","fugu"),
         colony = replace(colony, colony_old=="94","sculpin"),
         colony = replace(colony, colony_old=="100","vaquita"),
         colony = replace(colony, colony_old %in% c("114","114*"),"wahoo"),
         colony = replace(colony, colony_old=="129","cisco"),
         colony = replace(colony, colony_old=="130","sunfish"),
         colony = replace(colony, colony_old=="131","inanga"),
         colony = replace(colony, colony_old=="133","yellowtail"),
         colony = replace(colony, colony_old=="127","opaleye"),
         colony = replace(colony, colony_old=="135","fierasfer"),
         colony = replace(colony, colony_old=="136","sailfish"),
         colony = replace(colony, colony_old=="137","spiderfish"),
         colony = replace(colony, colony_old=="138","lox_northwest"),
         colony = replace(colony, colony_old=="144","darter"),
         colony = replace(colony, colony_old %in% c("092","92"),"carp"),
         colony = replace(colony, colony_old=="141","noodlefish"),
         colony = replace(colony, colony_old=="61","icefish"),
         colony = replace(colony, colony_old %in% c("142","river_east/142"),"vanjaram"),
         colony = replace(colony, colony_old %in% c("Volts","95","095"),"walleye"))

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
