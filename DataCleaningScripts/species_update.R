species <- species %>% dplyr::arrange(species)

write.csv(species, "SiteandMethods/species_list.csv", row.names = FALSE, na = "", quote = 7:27)