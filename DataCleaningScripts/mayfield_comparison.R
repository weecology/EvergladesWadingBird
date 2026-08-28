# Compare function results to handmade calculations
this_year <- 2025
nest_success <- mayfield(this_year)

filepath <- "~/Desktop/Mayfield_Calender_2025.xlsx"
new_data <- readxl::read_excel(path = filepath) %>%
  dplyr::rename_with(tolower) %>%
  dplyr::rename(nest_number = nest,
                species = species,
                n_days_incubation = "n(i)",
                incubation_success = "s(i)", 
                n_days_nestling = "n(n)",
                nestling_success = "s(n)",
                clutch = clutch,
                brood = brood,
                fledged = fledged,
                real_success = "reliable(1yes/0no)",
                notes = "comments") %>%
  dplyr::mutate(nest_number = as.character(nest_number),
                clutch_type = NA,
                young_lost = NA,
                real_failure = NA, 
                start_date = NA, 
                end_date = NA) %>%
  dplyr::select("year","colony","nest_number","species", "n_days_incubation", 
                "incubation_success", "n_days_nestling", "nestling_success",
                "clutch", "brood", "fledged", "clutch_type", "young_lost", "real_success", 
                "real_failure", "start_date", "end_date", "notes")

nest_success_compare <- new_data %>%
  full_join(nest_success, 
            by=c("year","colony","species","nest_number")) %>%
  select("year","colony","species","nest_number",
         order(colnames(.)),
         -"clutch_type")

success <- success(this_year, nest_success)

######################################################################################

# Make plot comparisons of all data
success_summary <- read.csv("Nesting/nest_success_summary.csv")
compare <- left_join(success,success_summary, by=join_by(year, colony, species)) %>%
  filter(species %in% species_list) %>%
  select("year","colony","species",order(colnames(.)))

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
