`%>%` <- magrittr::`%>%`
species <- read.csv("SiteandMethods/species_list.csv")

#' Get nest metrics
#'
nests <- read.csv("Nesting/nest_checks.csv", na.strings = "") %>%
         dplyr::filter(year>=2017) %>%
         plyr::join(species[,c(1,5,6)], by = "species") %>%
         dplyr::mutate(date = lubridate::as_date(date),
                       eggs = as.integer(eggs),
                       chicks = as.integer(chicks)) %>%
         # make consistent use of stage column
         dplyr::mutate(stage = dplyr::case_when((is.na(stage) & eggs %in% c(1:10) & chicks %in% c(1:10)) ~ "hatching",
                                                (is.na(stage) & eggs %in% c(1:10)) ~ "incubating",
                                                (is.na(stage) & chicks %in% c(1:10)) ~ "nestling",
                                                (is.na(stage) & !(eggs %in% c(1:10)) & !(chicks %in% c(1:10))) ~ "empty",
                                                             TRUE ~ stage)) %>%
         dplyr::mutate(start_date = dplyr::case_when(stage == "incubating" ~ date-1,
                                                     stage == "pipping" ~ date - incubation_j,
                                                     stage == "hatching" ~ date - incubation_j,
                                                     stage == "wet_chick" ~ date - incubation_j,
                                                     stage == "chick_dry" ~ date - incubation_j - 1,
                                                     stage == "nestling" ~ date - incubation_j - 2,
                                                     TRUE ~ NA),
                       incubation_end = dplyr::case_when(stage == "pipping" ~ date,
                                                         stage == "hatching" ~ date,
                                                         stage == "wet_chick" ~ date,
                                                         stage == "chick_dry" ~ date-1,
                                                         stage == "nestling" ~ date-2,
                                                         stage == "fledged" ~ date-nestling_j,
                                                         stage == "branchling" ~ date-nestling_j-2,
                                                         TRUE ~ NA))
nest_success <- nests %>%   
                dplyr::rename(nest_number = nest) %>%
                dplyr::group_by(year,colony,nest_number,species) %>%
                dplyr::summarise(clutch = max(eggs, na.rm = TRUE),
                                 brood = max(chicks, na.rm = TRUE),
                                 brood = dplyr::case_when(!is.finite(brood) ~ NA,
                                                           TRUE ~ brood),
                                 clutch = dplyr::case_when(!is.finite(clutch) ~ brood,
                                                           clutch<brood ~ brood,
                                                           TRUE ~ clutch),
                                 fledged = dplyr::last(chicks[!is.na(chicks)]),
                                 young_lost = clutch - fledged,
                                 start_date = min(start_date, na.rm=TRUE),
                                 incubation_end = max(incubation_end, na.rm=TRUE),
                                 end_date = max(date, na.rm=TRUE),
                                 start_date = dplyr::case_when(!is.finite(start_date) ~ NA,
                                                          TRUE ~ start_date),
                                 incubation_end = dplyr::case_when(!is.finite(incubation_end) ~ NA,
                                                               TRUE ~ incubation_end),
                                 end_date = dplyr::case_when(!is.finite(end_date) ~ NA,
                                                                   TRUE ~ end_date),
                                 n_days_incubation = as.numeric(incubation_end-start_date),
                                 n_days_nestling = as.numeric(end_date-incubation_end),
                                 incubation_success = dplyr::case_when(brood %in% c(1:10) ~ 1,
                                                                       fledged %in% c(1:10) ~ 1,
                                                                       TRUE ~ 0),
                                 nestling_success = dplyr::case_when(fledged %in% c(1:10) ~ 1,
                                                                     TRUE ~ 0))

#' Do summary calculations
#'
success_summary <- read.csv("Nesting/nest_success_summary.csv")
nest_success_manual <- read.csv("Nesting/nest_success.csv") 

success <- nest_success %>%
  dplyr::filter(year>=2017) %>%
  plyr::join(species[,c(1,5,6)], by = "species") %>%
  # make consistent use of success columns
  dplyr::mutate(incubation_success = dplyr::case_when(is.na(incubation_success) & brood %in% c(1:10) ~ 1,
                                               is.na(incubation_success) & fledged %in% c(1:10) ~ 1,
                                               TRUE ~ incubation_success),
                nestling_success = dplyr::case_when(is.na(nestling_success) & fledged %in% c(1:10) ~ 1,
                                                      TRUE ~ nestling_success)) %>%
  dplyr::group_by(year,colony,species) %>%
    dplyr::summarise(incubation_k=sum(!is.na(nest_number)), 
                     incubation_sumy=sum(incubation_success==1, na.rm=TRUE), 
                     incubation_e=sum(n_days_incubation, na.rm = TRUE), 
                     incubation_j=mean(incubation_j, na.rm = TRUE),
                     nestling_k=sum(incubation_success==1, na.rm=TRUE), 
                     nestling_sumy=sum(nestling_success==1, na.rm=TRUE), 
                     nestling_e=sum(n_days_nestling, na.rm = TRUE), 
                     nestling_j=mean(nestling_j, na.rm = TRUE)) %>%
    dplyr::mutate(incubation_p = 1-((incubation_k-incubation_sumy)/incubation_e), 
                  incubation_pj = incubation_p^incubation_j, 
                  incubation_varp=(incubation_p*(1-incubation_p))/incubation_e, 
                  incubation_varpj = incubation_varp*((incubation_j*(incubation_p^(incubation_j-1)))^2),
                  incubation_sdpj = sqrt(incubation_varpj),
                  nestling_p = 1-((nestling_k-nestling_sumy)/nestling_e), 
                  nestling_pj = nestling_p^nestling_j, 
                  nestling_varp=(nestling_p*(1-nestling_p))/nestling_e, 
                  nestling_varpj = nestling_varp*((nestling_j*(nestling_p^(nestling_j-1)))^2),
                  nestling_sdpj = sqrt(nestling_varpj),
                  overall_p = (incubation_p^incubation_j)*(nestling_p^nestling_j),
                  overall_varp = ((incubation_pj^2)*nestling_varpj)+((nestling_pj^2)*incubation_varpj)+(incubation_varpj*nestling_varpj),
                  overall_sd = sqrt(overall_varp))

compare <- dplyr::left_join(success,success_summary, by=dplyr::join_by(year, colony, species)) %>%
           dplyr::filter(species %in% c("bcnh","gbhe","glib","greg","rosp","smhe","sneg","whib","wost"))

library(ggplot2)
library(ggpubr)
# Compare basics
a <- ggplot(compare, aes(x=incubation_k.x, y=incubation_k.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=20, y=150, color="red",
           label=paste("Missing:",sum(is.na(compare$incubation_k.y)))) +
  xlab("Raw Incubation K") +
  ylab("Reported Incubation K") +
  theme_minimal()

b <- ggplot(compare, aes(x=nestling_k.x, y=nestling_k.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=20, y=110, color="red",
           label=paste("Missing:",sum(is.na(compare$nestling_k.y)))) +
  xlab("Raw Nestling K") +
  ylab("Reported Nestling K") +
  theme_minimal()

c <- ggplot(compare, aes(x=incubation_sumy.x, y=incubation_sumy.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=20, y=100, color="red",
           label=paste("Missing:",sum(is.na(compare$incubation_sumy.y)))) +
  xlab("Raw Incubation SumY") +
  ylab("Reported Incubation SumY") +
  theme_minimal()

d <- ggplot(compare, aes(x=nestling_sumy.x, y=nestling_sumy.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=20, y=100, color="red",
           label=paste("Missing:",sum(is.na(compare$nestling_sumy.y)))) +
  xlab("Raw Nestling_SumY") +
  ylab("Reported Nestling SumY") +
  theme_minimal()

e <- ggplot(compare, aes(x=incubation_e.x, y=incubation_e.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=2500, y=2500, color="red",
           label=paste("Missing:",sum(is.na(compare$incubation_e.y)))) +
  xlab("Raw Incubation E") +
  ylab("Reported Incubation E") +
  theme_minimal()

f <- ggplot(compare, aes(x=nestling_e.x, y=nestling_e.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=500, y=3500, color="red",
           label=paste("Missing:",sum(is.na(compare$nestling_e.y)))) +
  xlab("Raw Nestling E") +
  ylab("Reported Nestling E") +
  theme_minimal()

g <- ggplot(compare, aes(x=incubation_j.x, y=incubation_j.y)) + 
  geom_jitter(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=22, y=28, color="red",
           label=paste("Missing:",sum(is.na(compare$incubation_j.y)))) +
  xlab("Raw Incubation j") +
  ylab("Reported Incubation j") +
  theme_minimal()

h <- ggplot(compare, aes(x=nestling_j.x, y=nestling_j.y)) + 
  geom_jitter(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=20, y=50, color="red",
           label=paste("Missing:",sum(is.na(compare$nestling_j.y)))) +
  xlab("Raw Nestling j") +
  ylab("Reported Nestling j") +
  theme_minimal()

ggarrange(a, b, c, d, e, f, g, h, ncol = 4, nrow = 2,  common.legend = TRUE)

# Compare calculations
u <- ggplot(compare, aes(x=incubation_pj.x, y=incubation_pj.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  xlab("Raw Incubation pj") +
  ylab("Reported Incubation pj") +
  theme_minimal()

v <- ggplot(compare, aes(x=nestling_pj.x, y=nestling_pj.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  xlab("Raw Nestling pj") +
  ylab("Reported Nestling pj") +
  theme_minimal()

w <- ggplot(compare, aes(x=incubation_p.x, y=incubation_p.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  xlim(0,1) +
  ylim(0,1) +
  xlab("Raw Incubation p") +
  ylab("Reported Incubation p") +
  theme_minimal()

x <- ggplot(compare, aes(x=nestling_p.x, y=nestling_p.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  xlim(0,1) +
  ylim(0,1) +
  xlab("Raw Nestling p") +
  ylab("Reported Nestling p") +
  theme_minimal()

y <- ggplot(compare, aes(x=overall_p.x, y=overall_p.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  xlab("Raw Overall p") +
  ylab("Reported Overall p") +
  theme_minimal()

z <- ggplot(compare, aes(x=overall_varp.x, y=overall_varp.y)) + 
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  xlab("Raw Overall Variance") +
  ylab("Reported Overall Variance") +
  theme_minimal()

ggarrange(u, v, w, x, y, z, ncol = 3, nrow = 2,  common.legend = TRUE)
