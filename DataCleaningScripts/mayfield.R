# Functions for calculating mayfield nest success and success summaries
library(plyr)
library(dplyr)

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

## When do nests get excluded from calculations
  # only chicks no eggs and stage isn't aged_chick
  # only 1 observation of eggs/chicks total, and it isn't hatching or pipping
  # do not include in clutch size calculations based on 1 observation
  # exclude from incubation calculations if observation period is <<21 days,
      # and status is never hatching or pipping
  # exclude from nestling calculations if there is only one nestling observation and it's 
      # close to hatch date

#' Calculates mayfield nest success based on raw nest check data
#'
#' @param get_year year to calculate, can be an integer or vector
#'
#' @example mayfield(2006:2025)
#'
#'
#'

mayfield <- function(get_year = as.numeric(format(Sys.Date(), "%Y"))) {

  species <- read.csv("SiteandMethods/species_list.csv")
  species_list <- c("whib","wost","greg","rosp","gbhe","glib","bcnh",
                  "trhe","lbhe","sneg","smhe","smwh")

  # Get nest metrics
  nests <- read.csv("Nesting/nest_checks.csv", na.strings = "") %>%
    filter(year %in% get_year,
      species %in% species_list) %>%
      group_by(year,colony,nest,species) %>%
      mutate(date = lubridate::as_date(date),
             eggs = as.integer(eggs),
             chicks = as.integer(chicks),
             last_visit = lag(date),
             days_since_last_visit = date-last_visit,
             last_visit_stage = lag(stage),
             last_eggs = lag(eggs)) %>%
    join(species[,c(1,5,6)], by = "species") %>%
    # make consistent use of stage column
    mutate(stage = case_when((is.na(stage) & eggs %in% c(1:10) & chicks %in% c(1:10)) ~ "hatching",
                             (is.na(stage) & eggs %in% c(1:10)) ~ "incubating",
                             (is.na(stage) & chicks %in% c(1:10)) ~ "nestling",
                             (is.na(stage) & !(eggs %in% c(1:10)) & !(chicks %in% c(1:10))) ~ "empty",
                             TRUE ~ stage)) %>%
    # get dates
    mutate(lay_date = case_when(eggs > last_eggs ~ date - eggs*2 - 2,
                                eggs == 1 ~ date,
                                TRUE ~ as.Date(NA)),
           hatch_date = case_when(stage == "pipping" ~ date + 1,
                                  stage == "hatching" ~ date,
                                  TRUE ~ as.Date(NA)),
           backup_hatch_date = case_when(stage == "wet_chick" ~ date,
                                         stage == "chick_dry" ~ date - 1,
                                         stage == "nestling" & last_visit_stage == "incubating" ~ date - days_since_last_visit/2,
                                         TRUE ~ as.Date(NA)),
           incubation_end = case_when(stage == "pipping" ~ date + 1,
                                      stage == "hatching" ~ date,
                                      stage == "wet_chick" ~ date,
                                      stage == "chick_dry" ~ date - 1,
                                      stage == "nestling" ~ date - 2,
                                      stage == "fledged" ~ date - nestling_j,
                                      stage == "branchling" ~ date - nestling_j - 2,
                                      TRUE ~ as.Date(NA)),
           aged_chick_date = case_when(stage == "aged_chick" ~ date,
                                       TRUE ~ as.Date(NA)),
           gone_date = case_when(stage == "empty" & last_visit_stage != "empty" ~ date - days_since_last_visit/2,
                                 TRUE ~ as.Date(NA)),
           fail_date = case_when(stage == "failed" ~ date - days_since_last_visit/2,
                                 TRUE ~ as.Date(NA)),
           fledge_date = case_when(
             chicks > 0 & !is.na(lay_date)   ~ lay_date + incubation_j + nestling_j,
             chicks > 0 & !is.na(hatch_date) ~ hatch_date + nestling_j,
             TRUE ~ as.Date(NA) 
           )) %>%
    ungroup()

  nest_success <- nests %>% 
    dplyr::rename(nest_number = nest) %>%
    dplyr::group_by(year,colony,nest_number,species) %>%
    dplyr::summarise(incubation_j = mean(incubation_j, na.rm = TRUE),
      nestling_j = mean(nestling_j, na.rm = TRUE),
      nobs = n(),
      clutch = max(eggs, na.rm = TRUE),
      clutch = case_when(!is.finite(clutch) ~ NA,
        TRUE ~ clutch),
      brood = max(chicks, na.rm = TRUE),
      brood = case_when(!is.finite(brood) ~ NA,
        TRUE ~ brood),
      fledged = last(chicks[!is.na(chicks)]),
      lay_date = min(lay_date, na.rm=TRUE),
      lay_date = case_when(!is.finite(lay_date) ~ NA,
        TRUE ~ lay_date),
      hatch_date = min(hatch_date, na.rm=TRUE),
      hatch_date = case_when(!is.finite(hatch_date) ~ NA,
        TRUE ~ hatch_date),
      backup_hatch_date = min(backup_hatch_date, na.rm=TRUE),
      backup_hatch_date = case_when(!is.finite(backup_hatch_date) ~ NA,
        TRUE ~ backup_hatch_date),
      start_date = min(date, na.rm=TRUE),
      start_date = case_when(!is.finite(start_date) ~ NA,
        TRUE ~ start_date),
      aged_chick_date = min(aged_chick_date, na.rm=TRUE),
      aged_chick_date = case_when(!is.finite(aged_chick_date) ~ NA,
        TRUE ~ aged_chick_date),
      incubation_end = min(incubation_end, na.rm=TRUE),
      incubation_end = case_when(is.finite(lay_date) ~ lay_date + incubation_j,
        is.finite(hatch_date) ~ hatch_date,
        TRUE ~ incubation_end),
      incubation_end = case_when(!is.finite(incubation_end) ~ NA,
        TRUE ~ incubation_end),
      gone_date = min(gone_date, na.rm=TRUE),
      gone_date = case_when(!is.finite(gone_date) ~ NA,
        TRUE ~ gone_date),
      fail_date = max(fail_date, na.rm=TRUE),
      fail_date = case_when(!is.finite(fail_date) ~ NA,
        TRUE ~ fail_date),
      fledge_date = max(fledge_date, na.rm=TRUE),
      fledge_date = case_when(!is.finite(fledge_date) ~ NA,
        TRUE ~ fledge_date),
      fledged = case_when(is.finite(fail_date) ~ 0,
        TRUE ~ fledged),
      end_date = case_when(is.finite(fail_date) ~ fail_date,
        is.finite(gone_date) ~ gone_date,
        is.finite(fledge_date) ~ fledge_date,
        TRUE ~ NA),
      end_date = case_when(!is.finite(end_date) ~ NA,
        TRUE ~ end_date),
      n_days_incubation = as.numeric(incubation_end-start_date),
      n_days_nestling = as.numeric(end_date-incubation_end),
      incubation_success = case_when(brood %in% c(1:10) ~ 1,
        fledged %in% c(1:10) ~ 1,
        TRUE ~ 0),
      nestling_success = case_when(fledged %in% c(1:10) ~ 1,
        any(stage %in% c("fledged","branchling")) ~ 1,
        TRUE ~ 0)) %>%

    filter(!(is.na(clutch) & is.na(aged_chick_date))) %>%  # remove unusable nests
    filter(!(nobs==1 & is.na(hatch_date))) %>%
    mutate(clutch = case_when(clutch<brood ~ brood,
        TRUE ~ clutch),
      young_lost = clutch - fledged,
      n_days_incubation = case_when(is.na(incubation_end) ~ as.numeric(end_date-start_date),
        TRUE ~ n_days_incubation),
      n_days_nestling = case_when(n_days_incubation > incubation_j ~ n_days_nestling + n_days_incubation - incubation_j,
        n_days_nestling > nestling_j ~ nestling_j,
        is.na(n_days_nestling) & nestling_success==1 ~ nestling_j,
        is.na(n_days_nestling) ~ 0,
        n_days_nestling < 0 ~ 0,
        TRUE ~ n_days_nestling),
      n_days_incubation = case_when(n_days_incubation > incubation_j ~ incubation_j,
        is.na(n_days_incubation) ~ 0,
        n_days_incubation < 0 ~ 0,
        TRUE ~ n_days_incubation)) %>%
    ungroup()
  return(nest_success)
}

               

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

# trhe implies successful incubation
# smwh implies successful incubation
# smhe implies incubation failure

#' Calculates nest success summaries at the colony level based on nest-level mayfield calculations
#'
#' @param get_year year to calculate, can be an integer or vector
#' @param nest_success result of mayfield()
#'
#' @example success(2006:2025, nest_success)
#'
#'
#'
success <- function(get_year = as.numeric(format(Sys.Date(), "%Y")), nest_success) {
  
  nest_success %>%
    dplyr::filter(year %in% get_year) %>%
  # make consistent use of success columns
    dplyr::mutate(incubation_success = case_when(is.na(incubation_success) & brood %in% c(1:10) ~ 1,
                                          is.na(incubation_success) & fledged %in% c(1:10) ~ 1,
                                          TRUE ~ incubation_success),
           nestling_success = case_when(is.na(nestling_success) & fledged %in% c(1:10) ~ 1,
                                      TRUE ~ nestling_success)) %>%
    dplyr::mutate(species = replace(species, species %in% c("trhe", "lbhe", "sneg"), "smhe")) %>%
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
           overall_sd = sqrt(overall_varp)) %>%
    dplyr::mutate_if(is.double, list(~na_if(., Inf))) %>% 
    dplyr::mutate_if(is.double, list(~na_if(., -Inf))) %>%
    ungroup()
}