colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")
counts <- read.csv("Counts/maxcounts.csv")
under40 <- read.csv("Counts/maxcounts_under40.csv")

colonies$aka[which(colonies$colony=="hidden")] = "Hidden North, L-28, Hidden, L-28 Hidden, 58, 163"
counts$group_id[which(counts$colony=="58")] = 57
counts$colony[which(counts$colony=="58")] = "hidden"

colonies <- colonies %>% dplyr::arrange(group_id)
write.table(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = c(7,8))

counts <- counts %>% dplyr::arrange(colony,year)
write.table(counts, "Counts/maxcounts.csv", row.names = FALSE, na = "", sep = ",", quote = 9)

under40 <- under40 %>% dplyr::arrange()
write.table(under40, "Counts/maxcounts_under40.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = 28)