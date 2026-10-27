library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)

initiation_reported <- read.csv("Reports/performance_metrics/stork_initiation_old.csv") %>%
  mutate(
    initiation_month = case_when(
      !is.na(ymd(initiation)) ~ as.character(month(ymd(initiation), label = TRUE, abbr = FALSE)),
      TRUE                    ~ initiation
    ),
    initiation_month = replace(initiation_month, initiation_month=="February March", "March"),
    date_observed = make_date(year-1, month = 11, day = 1) + days_past_nov_1,
    type = "reported") %>%
  select("year","date_observed","initiation_month","date_score","type")
  
initiation <- read.csv("Indicators/stork_initiation.csv") %>%
  mutate(type = "corrected",
         date_observed = as.Date(date_observed)) %>%
  bind_rows(initiation_reported) %>%
  mutate(
    month_number = case_when(
      initiation_month=="November" ~ 5,
      initiation_month=="December" ~ 4,
      initiation_month=="January" ~ 3,
      initiation_month=="February" ~ 2,
      initiation_month=="March" ~ 1,
      TRUE                    ~ 0
    ))

arrows_month <- initiation %>%
  select(year, type, month_number) %>%
  pivot_wider(
    names_from = type,
    values_from = month_number
  ) %>%
  filter(reported != corrected)

arrows_datescore <- initiation %>%
  select(year, type, date_score) %>%
  pivot_wider(
    names_from = type,
    values_from = date_score
  ) 

ggplot(arrows_datescore, aes(x = reported, y = corrected)) +
  geom_point() +
  geom_abline(
    slope = 1,
    intercept = 0,
    linetype = 2,
    color = "red"
  ) +
  theme_bw() +
  xlab("Reported Date Score") +
  ylab("Corrected Date Score")

arrows_datescore <- arrows_datescore %>% filter(reported != corrected)
         
ggplot(initiation, aes(x = year, y = month_number, color = type, group = type)) +
  geom_hline(yintercept=4.5, linetype=2, linewidth=.5) +
  geom_segment(
    data = arrows_month,
    aes(
      x = year,
      xend = year,
      y = reported,
      yend = corrected
    ),
    inherit.aes = FALSE,
    color = "black",
    arrow = arrow(length = unit(0.15, "in"))
  ) +
  geom_point(alpha=2, size=3, shape=15) +
  scale_y_reverse(limits=c(5,1), breaks=c(5,4,3,2,1),
                           labels=c("November","December","January","February","March")) +
  theme_bw() +
  #    theme(panel.border = element_blank()) +
  xlab("Year") +
  ylab("Month")

ggplot(initiation, aes(x = year, y = date_score, color = type, group = type)) +
  geom_hline(yintercept=4.5, linetype=2, linewidth=.5) +
  geom_segment(
    data = arrows_datescore,
    aes(
      x = year,
      xend = year,
      y = reported,
      yend = corrected
    ),
    inherit.aes = FALSE,
    color = "black",
    arrow = arrow(length = unit(0.15, "in"))
  ) +
  geom_point(alpha=2, size=3, shape=15) +
  scale_y_reverse(limits=c(5,1), breaks=c(5,4,3,2,1),
                  labels=c("November","December","January","February","March")) +
  theme_bw() +
  theme(legend.title = element_blank()) +
  xlab("Year") +
  ylab("Date Score")

