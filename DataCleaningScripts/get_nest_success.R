colonies <- read.csv("SiteandMethods/colonies.csv")
species <- read.csv("SiteandMethods/species_list.csv")

success <- read.csv("Nesting/nest_success.csv") %>%
  dplyr::rename_with(tolower) %>%
  dplyr::mutate(colony = tolower(colony),
                colony = gsub(" ", "_", colony),
                colony = gsub("/", "_", colony),
                colony = gsub("-", "_", colony),
                colony = gsub("'", "", colony),
                species = tolower(species),
                species = gsub(" ", "", species),
                species = gsub("*", "", species),
                species = gsub("?", "", species),
                colony = replace(colony, colony %in% c("mud_canal","mud"), "mud_canal_south"),
                colony = replace(colony, colony=="l-28", "l_28"),
                colony = replace(colony, colony %in% c("fcity_north", "frogcity"), "frog_city_north"),
                colony = replace(colony, colony %in% c("teast_tris","t_east_1.","te_2","te_1"), "tamiami_east"),
                colony = replace(colony, colony=="hidden_", "hidden"),
                colony = replace(colony, colony=="frog_c._s." , "frog_city_south"),
                colony = replace(colony, colony %in% c("alley_n","alleynw","alleyns","alley_n_w_ibis","an_mixed_spp","an_whib"  ), "alley_north"),
                colony = replace(colony, colony %in% c("l_67east","l_67_new"  ), "horus"),
                colony = replace(colony, colony=="bigpond", "big_pond"),
                colony = replace(colony, colony=="3b_mud_east", "mud_east"),
                colony = replace(colony, colony=="vacation_island", "vacation"),
                colony = replace(colony, colony=="jarrod", "jerrod"),
                colony = replace(colony, colony=="false_l_67", "false_l67"),
                colony = replace(colony, colony %in% c("tamwest","tamwestwhib","tamiami_west_","tamw_ibis","tamw_stork"), "tamiami_west"),
                colony = replace(colony, colony %in% c("6thbridge","6thbridgewhib"), "6th_bridge"),
                colony = replace(colony, colony=="rookerybranch", "rookery_branch"),
                colony = replace(colony, colony=="cuthbert", "cuthbert_lake"),
                colony = replace(colony, colony=="paurotis", "paurotis_pond"),
                species = replace(species, species %in% c("ge","greg/smhe?","greg/smhe","greg/smwh"), "greg"),
                species = replace(species, species %in% c("swh", "smwt", "smwh*","smwh/glibrelay","smwht"), "smwh"),
                species = replace(species, species %in% c("sh", "sh?","smallheron/cormorant","smhe/bcnh","smallheron","smhe/glib","smhe*","smhe/glibrelay"), "smhe"),
                species = replace(species, species %in% c("tc", "trhe?","tche"), "trhe"),
                species = replace(species, species %in% c("se", "sneg?"), "sneg"),
                species = replace(species, species %in% c("gbhe?"), "gbhe"),
                species = replace(species, species %in% c("lb"), "lbhe"),
                species = replace(species, species %in% c("anhi?"), "anhi"),
                species = replace(species, species %in% c("greenheron"), "grhe"),
                species = replace(species, species %in% c("unknown", ""), "unkn"),
                species = replace(species, species %in% c("ce?se?","ce?"), "caeg"),
                species = replace(species, species %in% c("wi", "whib*","whibthensmhe","whib/glibrelay","whip"), "whib"),
                species = replace(species, species %in% c("bcnh*/smwhrelay", "bcnh/whibrelay","bcnh/glibrelay","bcnh/smwhrelay","bcnhorsmhe","bcnh/trhe","bcnh?","bc"), "bcnh"),
                species = replace(species, species %in% c("rosp/glibrelay" , "rosp/smherelay","rosp/greg"), "rosp")) %>%
  dplyr::mutate(across(where(is.character),~dplyr::na_if(., "na"))) %>%
  dplyr::mutate(across(where(is.character),~dplyr::na_if(., "NS"))) %>%
  dplyr::mutate(dplyr::across(c("incubation_success","clutch","brood"), stringr::str_replace, " ", ""),
                dplyr::across(c("incubation_success","clutch","clutch_size","brood"), stringr::str_replace, "\\+", ""),
                dplyr::across(c("n_days_incubation","clutch_size"), stringr::str_replace, "\\.", ""),
                dplyr::across(c("brood","fledged","young_lost"), stringr::str_replace, "\\?", ""),
                incubation_success = replace(incubation_success, incubation_success=="11", "1"),
                nestling_success = replace(nestling_success, nestling_success==14, 1),
                clutch = replace(clutch, clutch=="l","1"),
                brood = replace(brood, brood=="3or 2", "3"),
                fledged = replace(fledged, fledged=="2-Mar", "3")) %>%
  dplyr::mutate_at(c("n_days_incubation","incubation_success","n_days_nestling","nestling_success","clutch",
                     "brood","fledged","clutch_size","clutch_type","young_lost","real_success","real_failure"), as.numeric) %>%
  dplyr::mutate(year=as.integer(year),
                clutch=ifelse(is.na(clutch_size), clutch, clutch_size)) %>% 
  dplyr::select(-"clutch_size") %>%
  dplyr::arrange(year,colony,species) 

unique(success$colony[which(!(success$colony %in% colonies$colony))])
unique(success$species[which(!(success$species %in% species$species))])

success <- success %>% dplyr::arrange(year,colony,species)
write.table(success, "Nesting/nest_success.csv", row.names = FALSE, na = "", sep = ",", quote = 18)

# make metadata
success_metadata <- data.frame(name = as.vector(colnames(success))) %>%
                    dplyr::mutate(class=sapply(success,class),
                                  min=sapply(success,min,na.rm = TRUE),
                                  max=sapply(success,max,na.rm = TRUE),
                                  description=c("year","see colonies table","unique nest id","see species list",
                                                "number of days incubating","was incubation successful (1) or not (0)",
                                                "number of days chicks in nest","did chicks successfully fledge",
                                                "number of eggs","number of chicks","number of chicks fledged",
                                                "clutch type","number of young lost","confirmed successful nest",
                                                "confirmed failed nest","nest start date",
                                                "fledge or failure date","observer comments"))
write.table(success_metadata, "Nesting/nest_success_metadata.csv", row.names = FALSE, na = "", sep = ",", quote = 5)
