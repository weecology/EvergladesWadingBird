library(tidyr)
library(dplyr)
library(ggplot2)

groundcounts_old <- read.csv("Counts/groundcounts_table.csv") %>%
  arrange(year) %>%
  pivot_longer(cols = -year , names_to = "species", values_to = "old_total")

groundcounts <- read.csv("Counts/ground_counts.csv") %>%
  filter(standard_survey==1) %>%
  group_by(year,species) %>%
  summarise(total=sum(count, na.rm=TRUE))

all_ground <- full_join(groundcounts_old, groundcounts, by = c("year","species")) %>%
  filter(species %in% groundcounts_old$species)

ggplot(all_ground, aes(year, total, colour = species)) + 
  geom_line() +
  geom_line(aes(year, old_total, colour = species), linetype = 2) +
  facet_wrap("species", scales = "free") +
  theme_bw() +
  theme(legend.position="none")

ggplot(all_ground, aes(total, old_total, colour = species)) + 
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  facet_wrap("species", scales = "free") +
  theme_bw() +
  theme(legend.position="none")

