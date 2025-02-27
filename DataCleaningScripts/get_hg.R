#' Used to clean and validate mercury data from field format
#'

`%>%` <- magrittr::`%>%`

colonies <- read.csv("SiteandMethods/colonies.csv")
feather_hg <- read.csv("Hg/feather_hg.csv")



new_hg <- new_hg %>%
          dplyr::rename_with(tolower) %>%
  dplyr::mutate(colony = tolower(colony),
                colony = gsub(" ", "_", colony),
                colony = gsub("/", "_", colony),
                colony = gsub("/.", "_", colony),
                colony = replace(colony, colony=="alleynorth", "alley_north"),
                colony = replace(colony, colony=="l67", "horus"),
                colony = replace(colony, colony=="mudcanal", "mud_canal_south"),
                colony = replace(colony, colony=="tameast", "tamiami_east"),
                colony = replace(colony, colony=="3bmud" , "heron_alley"),
                colony = replace(colony, colony=="falsel67", "false_l67"),
                colony = replace(colony, colony=="tamwest", "tamiami_west"),
                colony = replace(colony, colony=="3bmud_east", "mud_east"),
                colony = replace(colony, colony=="cypresscity", "cypress_city"),
                colony = replace(colony, colony=="6bridge", "6th_bridge"),
                colony = replace(colony, colony=="rook.br.", "rookery_branch"),
                colony = replace(colony, colony=="andytown", "andytown_north"),
                colony = replace(colony, colony=="cuthbert", "cuthbert_lake"),
                colony = replace(colony, colony=="paurotis", "paurotis_pond")) %>%
  dplyr::mutate(colony_year = paste(colony, "_", year),
                unique_feather_id = paste(colony_year, "_", nest_feather_id))
  
if(!all(new_hg$colony %in% colonies$colony)) {
  print(unique(new_hg$colony[which(!(new_hg$colony %in% colonies$colony))]))
}


new_hg <- feather_hg %>% dplyr::select(year,colony,nest,feather_id,hg,culmen,tarsus,mass,date,everything(),notes)


write.table(feather_hg, "Hg/feather_hg.csv", row.names = FALSE, col.names = TRUE, 
            na = "", sep = ",", quote = 24)
