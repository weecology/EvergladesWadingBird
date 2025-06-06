library(dplyr)
counts <- read.csv("Counts/maxcounts.csv")
colonies <- read.csv("SiteandMethods/colonies.csv") %>%
            select(-c(latitude,longitude))

colonies_new <- read_csv("~/Desktop/colonies.csv") %>%
                select(-c(colony, latitude, longitude, wca, aka)) %>%
                rename(colony=Name, latitude=Y, longitude=X) %>%
                select(group_id, colony, latitude, longitude)

colonies_update <- colonies %>%
            full_join(colonies_new, by=c("group_id","colony")) %>%
            arrange(latitude) 

colonies_update[colonies_update$colony=="3b_boat_ramp",]$wca="3b"
colonies_update[colonies_update$colony=="little_a",]$wca="3as"
colonies_update[colonies_update$colony=="2662",]$wca="urban"
colonies_update[colonies_update$colony=="3400",]$wca="urban"
colonies_update[colonies_update$colony=="hera",]$wca="3as"
colonies_update[colonies_update$colony=="vesta",]$wca="1"
colonies_update[colonies_update$colony=="nc4",]$wca="1"
colonies_update[colonies_update$colony=="63",]$wca="1"

colonies_update$aka[colonies_update$colony=="38_185"]="38/185, 38, 185"
colonies_update$aka[colonies_update$colony=="lox_nc4"] = 
                          paste(colonies_update$aka[colonies_update$colony=="lox_nc4"],colonies_update$aka[colonies_update$colony=="cook_nc4"],"cook_nc4",sep=",")
colonies_update$aka[colonies_update$colony=="lox111"] = 
  paste(colonies_update$aka[colonies_update$colony=="lox111"],colonies_update$aka[colonies_update$colony=="lox3"],"lox3",sep=",")
colonies_update$aka[colonies_update$colony=="rhea"] = 
  paste(colonies_update$aka[colonies_update$colony=="rhea"],colonies_update$aka[colonies_update$colony=="new_may"],"new_may",sep=",")
colonies_update$aka[colonies_update$colony=="oil_can"] = 
  paste(colonies_update$aka[colonies_update$colony=="oil_can"],colonies_update$aka[colonies_update$colony=="3704"],"3704",sep=",")
colonies_update$aka[colonies_update$colony=="lox_nc1"] = paste(colonies_update$aka[colonies_update$colony=="lox_nc1"],
        colonies_update$aka[colonies_update$colony=="yew_south"],colonies_update$aka[colonies_update$colony=="cook_nc1"],
        "yew_south,cook_nc1",sep=",")
colonies_update$aka[colonies_update$colony=="yamir"] = 
  paste(colonies_update$aka[colonies_update$colony=="yamir"],
        colonies_update$aka[colonies_update$colony=="3699"],"2772,3699",sep=",")
colonies_update$aka[colonies_update$colony=="63"] = "6"
colonies_update$aka[colonies_update$colony=="nc4"] = paste(colonies_update$aka[colonies_update$colony=="lox4"],"lox4",sep=",")
colonies_update$aka[colonies_update$colony=="vesta"] = paste(colonies_update$aka[colonies_update$colony=="newcol2"],"newcol2",sep=",")
colonies_update$aka[colonies_update$colony=="start_mel"] = paste(colonies_update$aka[colonies_update$colony=="start_mel"],
                                                           colonies_update$aka[colonies_update$colony=="3696"],"3696",sep=",")
colonies_update$aka[colonies_update$colony=="hera"] = paste(colonies_update$aka[colonies_update$colony=="starter_melaleuca"],"starter_melaleuca",sep=",")

colonies_update <- colonies_update[-which(colonies_update$colony %in% 
    c("38","cook_nc4","lox3","new_may","3936","3704","yew_south", "3696", "starter_melaleuca", 
      "cook_nc1","2772","3699","6","lox4","newcol2")),]

colonies_update <- colonies_update %>%
                   rename(subregion=wca) %>%
                   mutate(region = ifelse(subregion=="1","1",NA),
                          region = replace(region, subregion %in% c("2a","2b"), "2"),
                          region = replace(region, subregion %in% c("3as","3an","3ase","3b"), "3"),
                          region = replace(region, subregion %in% c("sawgrassenp","coastal"), "enp"),
                          region = replace(region, subregion %in% c("bigcypress","keys","urban"), "other")) %>%
                   select(group_id,colony,region,subregion,latitude,longitude,aka) %>%
                   arrange(colonies_update)

colonies_update <- colonies_update %>%
                   mutate(display_name = stringr::str_to_title(stringr::str_replace_all(colony,"_", " ")))



if(!all(counts$colony %in% colonies_update$colony)) {
  print(unique(counts$colony[which(!(counts$colony %in% colonies_update$colony))]))
}

counts <- counts %>%
          select(-region) %>%
          mutate(colony = replace(colony, colony=="starter_melaleuca","hera"),
                 colony = replace(colony, colony=="new_may","rhea"),
                 colony = replace(colony, colony=="2772","yamir"),
                 colony = replace(colony, colony=="3699","yamir"),
                 colony = replace(colony, colony=="yew_south","lox_nc1"),
                 colony = replace(colony, colony=="lox4","nc4"),
                 colony = replace(colony, colony=="lox3","lox111"),
                 colony = replace(colony, colony=="newcol2","vesta"),
                 colony = replace(colony, colony=="6","63"),
                 colony = replace(colony, colony=="38","38_185"),
                 colony = replace(colony, colony=="3696","start_mel"),
                 colony = replace(colony, colony=="3704","oil_can"),
                 colony = replace(colony, colony=="cook_nc1","lox_nc1"),
                 colony = replace(colony, colony=="cook_nc4","lox_nc4"))

counts <- counts %>% dplyr::arrange(year,group_id)
write.table(counts, "Counts/maxcounts.csv", row.names = FALSE, na = "", sep = ",", quote = 9)  

colonies_update <- colonies_update %>% 
  dplyr::mutate(dplyr::across(c("group_id","latitude","longitude"), as.numeric)) %>%
  dplyr::arrange(group_id)
write.csv(colonies_update, "SiteandMethods/colonies.csv", row.names = FALSE, na = "", quote = c(7,8))

species <- species %>% dplyr::arrange(species)
write.csv(species, "SiteandMethods/species_list.csv", row.names = FALSE, na = "", quote = 7:27)
