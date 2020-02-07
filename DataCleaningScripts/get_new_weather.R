#' Functions for downloading and processing the weather data
#'

`%>%` <- magrittr::`%>%`

#' Selects new weather data
#'
#'
#'
#' @example new_met_data()
#'
#'
#'
# This function checks for new data at the datalogger-hosted website

new_met_data <- function() {
  
  #httr::set_config(httr::timeout(seconds = 120))
  
  # Pull raw data
  message("Pulling raw weather data")
  
  oasis <- read.csv(url(
   'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USR0000FOAS.csv'),
    header = TRUE, sep = ",", stringsAsFactors = FALSE)  %>% 
    dplyr::rename_all(. %>% tolower) %>%
    dplyr::select(-c(latitude, longitude, name, elevation)) %>%
    dplyr::mutate(date = lubridate::ymd(date),
                  tmax = tmax/10,
                  tmin = tmin/10, 
                  tavg = tavg/10)
  
  raccoon <- read.csv(url(
    'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USR0000FRAC.csv'),
    header = TRUE, sep = ",", stringsAsFactors = FALSE)  %>% 
    dplyr::rename_all(. %>% tolower) %>%
    dplyr::select(-c(latitude, longitude, name, elevation)) %>%
    dplyr::mutate(date = lubridate::ymd(date),
                  tmax = tmax/10,
                  tmin = tmin/10, 
                  tavg = tavg/10)
  
  # Load existing data for comparison
  weather <- read.csv("Weather/weather.csv") %>%
    dplyr::mutate(date = lubridate::ymd(date))
  weather_cols <- names(weather)

  oasis_latest <- max(weather$date[weather$station=="USR0000FOAS"])
  raccoon_latest <- max(weather$date[weather$station=="USR0000FRAC"])
  
  oasis[,setdiff(weather_cols, names(oasis))] <- NA
  raccoon[,setdiff(weather_cols, names(raccoon))] <- NA
  
  # Keep only new data
  new_oasis <- oasis %>%
    dplyr::filter(date > oasis_latest) %>%
    dplyr::select(weather_cols)
  
  new_raccoon <- raccoon %>%
    dplyr::filter(date > raccoon_latest) %>%
    dplyr::select(weather_cols)
    
  # Set up dataframe to append
    
  new_data <- dplyr::bind_rows(new_oasis, new_raccoon) %>%
    dplyr::arrange(date)
  
  return(new_data)
  
}

#' Appends new weather data
#'
#'
#'
#' @example append_weather()
#'
#'
#'

append_weather <- function() {
  
  data <- new_met_data()
  
  # append new data
  write.table(data, file = "Weather/weather.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
}


