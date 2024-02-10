colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")
counts <- read.csv("Counts/maxcounts.csv")
under40 <- read.csv("Counts/maxcounts_under40.csv")





colonies <- colonies %>% dplyr::arrange(colony)
write.table(colonies, "SiteandMethods/colonies.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = c(7,8))

counts <- counts %>% dplyr::arrange()
write.table(counts, "Counts/maxcounts.csv", row.names = FALSE, na = "", sep = ",", quote = 9)

under40 <- under40 %>% dplyr::arrange()
write.table(under40, "Counts/maxcounts_under40.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = 28)