library(dplyr)
species <- read.csv("SiteandMethods/species_list.csv")

species[29,] <- c("brpe", "Brown Pelican", "Pelecanus occidentalis", "no", 32, 81, rep("",21))
species[30,] <- c("gwhe",	"Great-white Heron", "Ardea herodias occidentalis", "yes", species[7,5:27])
species[31,] <- c("reeg",	"Reddish Egret", "Egretta rufescens", "no", 29, 32, rep("",21))
species[32,] <- c("baea",	"Bald Eagle", "Haliaeetus leucocephalus", "no", 35, 77, rep("",21))
species[33,] <- c("ospr",	"Osprey",	"Pandion haliaetus", "no", 39, 53, rep("",21))

species <- species %>% dplyr::arrange(species)

write.csv(species, "SiteandMethods/species_list.csv", row.names = FALSE, na = "", quote = 7:27)
