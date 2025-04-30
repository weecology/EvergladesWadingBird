### Calculate Mayfield nest success from field nest checks

# TODO:: Add checks that final hatch date is before all nestling status and after all incubating.
# TODO:: First separate nests into different scenarios that require different assumptions.

# Species: "whib","wost","greg","rosp","gbhe","glib","bcnh","trhe","lbhe","sneg","smhe","smwh"

# Unless there is an informative stage, events are assumed to occur exactly halfway between 
# observations

# How to get hatch date:
##  Lay Date: 
  # Always first use lay date to calculate forward to hatch date 
    # use egg data: if eggs are increasing, back calculate (2 days/egg) to lay date
    # use latest possible lay date (round up)
  # hatch date = lay_date + incubation_j

## Observed Hatch Date:
  # if insufficient egg data (egg numbers don't change), use hatch date from observations
  # pipping, wet_chick, hatching
  # chick_dry w/ eggs and chicks

## Nestling period:
  # last resort
  # Usually only in bad years
  # If it's all there is, nests with only chicks will get counted, n(i) is 0
  # Chicks -> empty can be interpreted as failure in bad years, rather than fledged in a more successful year
 
# Success Calculations
## Lay date is only determined to get hatch date. Then hatch date is used in calculations.
  # n(i) is start_date-hatch_date
    # start_date is date of first observation (not lay_date)
  # n(n) is hatch_date-end_date

## End date is fail or fledge
  # with good lay date or hatch date, calculate fledge
  # fledge_date = incubation_j + nestling_j + 2
  # fail date is halfway between last date with chicks and first empty date

# TO DO:
## When do nests get excluded from calculations
  # only chicks no eggs and stage isn't aged_chick
  # only 1 observation of eggs/chicks total, and it isn't hatching or pipping
  # do not include in clutch size calculations based on 1 observation
  
# TO DO: decide on inc_j for smhe
# correct old calculations days and j's

`%>%` <- magrittr::`%>%`
species <- read.csv("SiteandMethods/species_list.csv")
species_list <- c("whib","wost","greg","rosp","gbhe","glib","bcnh",
                  "trhe","lbhe","sneg","smhe","smwh")
get_year <- c(2024)


#' Get nest metrics
#'
nests <- read.csv("Nesting/nest_checks.csv", na.strings = "") %>%
         dplyr::filter(year %in% get_year,
                       species %in% species_list) %>%
         dplyr::group_by(year,colony,nest,species) %>%
         dplyr::mutate(date = lubridate::as_date(date),
                       eggs = as.integer(eggs),
                       chicks = as.integer(chicks),
                       last_visit = dplyr::lag(date),
                       days_since_last_visit = date-last_visit,
                       last_visit_stage = dplyr::lag(stage),
                       last_eggs = dplyr::lag(eggs)) %>%
         plyr::join(species[,c(1,5,6)], by = "species") %>%
         # make consistent use of stage column
         dplyr::mutate(stage = dplyr::case_when((is.na(stage) & eggs %in% c(1:10) & chicks %in% c(1:10)) ~ "hatching",
                                                (is.na(stage) & eggs %in% c(1:10)) ~ "incubating",
                                                (is.na(stage) & chicks %in% c(1:10)) ~ "nestling",
                                                (is.na(stage) & !(eggs %in% c(1:10)) & !(chicks %in% c(1:10))) ~ "empty",
                                                             TRUE ~ stage)) %>%
         dplyr::mutate(lay_date = dplyr::case_when(eggs > last_eggs ~ date - eggs*2 - 2,
                                                   eggs == 1 ~ date,
                                                   TRUE ~ NA),
                       hatch_date = dplyr::case_when(stage == "pipping" ~ date + 1,
                                                     stage == "hatching" ~ date,
                                                     stage == "wet_chick" ~ date,
                                                     stage == "chick_dry" ~ date - 1,
                                                     stage == "nestling" & last_visit_stage == "incubating" ~ date - days_since_last_visit/2,
                                                     TRUE ~ NA),
                       incubation_end = dplyr::case_when(stage == "pipping" ~ date + 1,
                                                         stage == "hatching" ~ date,
                                                         stage == "wet_chick" ~ date,
                                                         stage == "chick_dry" ~ date - 1,
                                                         stage == "nestling" ~ date - 2,
                                                         stage == "fledged" ~ date - nestling_j,
                                                         stage == "branchling" ~ date - nestling_j - 2,
                                                         TRUE ~ NA),
                       gone_date = dplyr::case_when(stage == "empty" & last_visit_stage != "empty" ~ date - days_since_last_visit/2,
                                                      TRUE ~ NA),
                       fail_date = dplyr::case_when(stage == "failed" ~ date - days_since_last_visit/2,
                                                    TRUE ~ NA),
   # replace cur_data(), 
                       fledge_date = dplyr::case_when(chicks>0 & !is.na(unique(dplyr::cur_data()$lay_date)) ~ unique(dplyr::cur_data()$lay_date) + incubation_j + nestling_j,
                                                      chicks>0 & !is.na(unique(dplyr::cur_data()$hatch_date)) ~ unique(dplyr::cur_data()$hatch_date) + nestling_j,
                                                      TRUE ~ NA))
nest_success <- nests %>%   
                dplyr::rename(nest_number = nest) %>%
                dplyr::group_by(year,colony,nest_number,species) %>%
                dplyr::summarise(incubation_j = mean(incubation_j, na.rm = TRUE),
                                 nestling_j = mean(nestling_j, na.rm = TRUE),
                                 clutch = max(eggs, na.rm = TRUE),
                                 brood = max(chicks, na.rm = TRUE),
                                 brood = dplyr::case_when(!is.finite(brood) ~ NA,
                                                           TRUE ~ brood),
                                 clutch = dplyr::case_when(!is.finite(clutch) ~ brood,
                                                           clutch<brood ~ brood,
                                                           TRUE ~ clutch),
                                 fledged = dplyr::last(chicks[!is.na(chicks)]),
                                 lay_date = min(lay_date, na.rm=TRUE),
                                 hatch_date = min(hatch_date, na.rm=TRUE),
                                 start_date = min(date, na.rm=TRUE),
                                 incubation_end = min(incubation_end, na.rm=TRUE),
                                 incubation_end = dplyr::case_when(is.finite(lay_date) ~ lay_date + incubation_j,
                                                                   is.finite(hatch_date) ~ hatch_date,
                                                                   TRUE ~ incubation_end),
                                 gone_date = min(gone_date, na.rm=TRUE),
                                 fail_date = max(fail_date, na.rm=TRUE),
                                 fledge_date = max(fledge_date, na.rm=TRUE),
                                 fledged = dplyr::case_when(is.finite(fail_date) ~ 0,
                                                            TRUE ~ fledged),
                                 young_lost = clutch - fledged,
                                 end_date = dplyr::case_when(is.finite(fail_date) ~ fail_date,
                                                             is.finite(gone_date) ~ gone_date,
                                                             is.finite(fledge_date) ~ fledge_date,
                                                             TRUE ~ NA),
                                 start_date = dplyr::case_when(!is.finite(start_date) ~ NA,
                                                          TRUE ~ start_date),
                                 lay_date = dplyr::case_when(!is.finite(lay_date) ~ NA,
                                                               TRUE ~ lay_date),
                                 hatch_date = dplyr::case_when(!is.finite(hatch_date) ~ NA,
                                                               TRUE ~ hatch_date),
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
                                                                     any(stage %in% c("fledged","branchling")) ~ 1,
                                                                     TRUE ~ 0)) %>%
               dplyr::mutate(n_days_incubation = dplyr::case_when(is.na(incubation_end) ~ as.numeric(end_date-start_date),
                                                                  TRUE ~ n_days_incubation),
                             n_days_nestling = dplyr::case_when(n_days_incubation > incubation_j ~ n_days_nestling + n_days_incubation - incubation_j,
                                                                n_days_nestling > nestling_j ~ nestling_j,
                                                                is.na(n_days_nestling) & nestling_success==1 ~ nestling_j,
                                                                is.na(n_days_nestling) ~ 0,
                                                                n_days_nestling < 0 ~ 0,
                                                                TRUE ~ n_days_nestling),
                             n_days_incubation = dplyr::case_when(n_days_incubation > incubation_j ~ incubation_j,
                                                                  is.na(n_days_incubation) ~ 0,
                                                                  n_days_incubation < 0 ~ 0,
                                                                  TRUE ~ n_days_incubation))


# Compare example 
#

nest_success_compare <- read.csv("Nesting/nest_success.csv") %>%
                        dplyr::filter(year %in% get_year) %>%
                        dplyr::full_join(nest_success, 
                                         by=c("year","colony","species","nest_number")) %>%
                        dplyr::select("year","colony","species","nest_number",
                                      order(colnames(.)),
                                      -"clutch_type")

               
# Do summary calculations
#
# smhe and smwh are used to combine trhe, lbhe, sneg when they cannot be distinguished
# trhe, lbhe, sneg nests are impossible to tell apart
  # combine everything into smhe for incubation calculations
# do trhe, lbhe, sneg separately if possible for nestling calculations
  # once trhe hatch, they are distinguishable
  # or trhe and smwh separately
  # lbhe, sneg chicks difficult to tell apart
# lump back into smhe for overall

## trhe implies successful incubation
# smwh implies successful incubation
# smhe implies incubation failure

# TO DO: This ^

success_summary <- read.csv("Nesting/nest_success_summary.csv")

success <- nest_success %>%
  dplyr::filter(year %in% get_year) %>%

  # make consistent use of success columns
  dplyr::mutate(incubation_success = dplyr::case_when(is.na(incubation_success) & brood %in% c(1:10) ~ 1,
                                               is.na(incubation_success) & fledged %in% c(1:10) ~ 1,
                                               TRUE ~ incubation_success),
                nestling_success = dplyr::case_when(is.na(nestling_success) & fledged %in% c(1:10) ~ 1,
                                                      TRUE ~ nestling_success)) %>%
  dplyr::group_by(year,colony,species) %>%
  dplyr::mutate(species = replace(species, species %in% c("trhe", "lbhe", "sneg"), "smhe")) %>%
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
                  overall_sd = sqrt(overall_varp)) %>%
    dplyr::mutate_if(is.double, list(~dplyr::na_if(., Inf))) %>% 
    dplyr::mutate_if(is.double, list(~dplyr::na_if(., -Inf)))

compare <- dplyr::left_join(success,success_summary, by=dplyr::join_by(year, colony, species)) %>%
           dplyr::filter(species %in% species_list) %>%
           dplyr::select("year","colony","species",order(colnames(.)))

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
  geom_point(aes(color=species)) +
  geom_abline(slope = 1, intercept = 0) +
  annotate(geom="text", x=22, y=28, color="red",
           label=paste("Missing:",sum(is.na(compare$incubation_j.y)))) +
  xlab("Raw Incubation j") +
  ylab("Reported Incubation j") +
  theme_minimal()

h <- ggplot(compare, aes(x=nestling_j.x, y=nestling_j.y)) + 
  geom_point(aes(color=species)) +
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
