library(dplyr)
library(tidyr)

colonies <- read.csv("SiteandMethods/colonies.csv") %>%     
  mutate(group_id = as.numeric(group_id),
         latitude = as.numeric(latitude),
         longitude = as.numeric(longitude))

counts <- read.csv("Counts/maxcounts.csv")
coastal_nesting <- read.csv("Indicators/coastal_nesting.csv") %>%
  rename(total_reported = total,
         coastal_reported = coastal,
         proportion_reported = proportion)

count_total <- counts %>% left_join(colonies, by = join_by(group_id, colony)) %>% group_by(year) %>%
  filter(region!="other") %>% summarise(sum(count)) %>% rename(total = "sum(count)")
coastal_total <- counts %>% group_by(year) %>% left_join(colonies, by = join_by(group_id, colony)) %>%
  filter(subregion=="coastalenp") %>% summarise(sum(count)) %>% rename(coastal = "sum(count)")

count_total_cerp <- counts %>% left_join(colonies, by = join_by(group_id, colony)) %>%
  filter(region!="other", species %in% c("greg","rosp","sneg","whib","wost")) %>%
  group_by(year) %>% summarise(sum(count)) %>% rename(total_cerp = "sum(count)")
coastal_total_cerp <- counts %>% filter(species %in% c("greg","rosp","sneg","whib","wost")) %>%
  group_by(year) %>% left_join(colonies, by = join_by(group_id, colony)) %>% 
  filter(subregion=="coastalenp") %>% 
  summarise(sum(count)) %>% rename(coastal_cerp = "sum(count)")

coastal_ratio <- count_total %>%
  full_join(coastal_total) %>%
  full_join(count_total_cerp) %>%
  full_join(coastal_total_cerp) %>%
  mutate(across(where(is.numeric), ~ replace_na(., 0)),
         proportion = coastal/total,
         proportion_cerp = coastal_cerp/total_cerp) %>%
  full_join(coastal_nesting) %>%
  arrange(year)

options(scipen = 999)

plot(coastal_ratio$proportion_reported,coastal_ratio$proportion, col = 'lightseagreen', cex=1.3,
     xlab = "Reported Ratio", ylab = "Corrected Ratio")
points(coastal_ratio$proportion_reported,coastal_ratio$proportion_cerp, col = 'orange3', cex=1.3)
abline(a = c(0,1), col='red', lty=2,lwd=2)
legend("topleft", 
       legend = c("All species","CERP species only"), 
       col = c("lightseagreen","orange3"), 
       pch = 1,
       bty = "n",
       cex = .8)

plot(coastal_ratio$year,coastal_ratio$total_reported,col="mediumpurple4",type="l",log="xy",lwd=2,
     xlab = "Year", ylab = "Total Count", ylim = c(2800,120000))
lines(coastal_ratio$year,coastal_ratio$total,col="lightseagreen",lwd=2)
lines(coastal_ratio$year,coastal_ratio$total_cerp,col="orange3",lwd=2)
legend("topleft", 
       legend = c("Reported","All species","CERP species only"), 
       col = c("mediumpurple4","lightseagreen","orange3"), 
       lty = 1,
       bty = "n",
       cex = .8)

plot(coastal_ratio$year,coastal_ratio$coastal_reported,col="mediumpurple4",type="l",log="xy",lwd=2,
     xlab = "Year", ylab = "Coastal Count", ylim = c(10,40000))
lines(coastal_ratio$year,coastal_ratio$coastal,col="lightseagreen",lwd=2)
lines(coastal_ratio$year,coastal_ratio$coastal_cerp,col="orange3",lwd=2)
legend("topleft", 
       legend = c("Reported","All species","CERP species only"), 
       col = c("mediumpurple4","lightseagreen","orange3"), 
       lty = 1,
       bty = "n",
       cex = .8)

plot(coastal_ratio$year,coastal_ratio$proportion_reported,col="mediumpurple4",type="l",lwd=2,
     xlab = "Year", ylab = "Coastal Ratio", ylim = c(0,.5))
lines(coastal_ratio$year,coastal_ratio$proportion,col="lightseagreen",lwd=2)
lines(coastal_ratio$year,coastal_ratio$proportion_cerp,col="orange3",lwd=2)
legend("topleft", 
       legend = c("Reported","All species","CERP species only"), 
       col = c("mediumpurple4","lightseagreen","orange3"), 
       lty = 1,
       bty = "n",
       cex = .8)
