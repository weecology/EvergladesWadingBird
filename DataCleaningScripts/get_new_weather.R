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
# This function checks for new data at all NOAA stations

new_met_data <- function() {
  
  options(dplyr.summarise.inform = FALSE)  
  
  # Load existing data for comparison
  weather <- read.csv("Weather/weather.csv") %>%
    dplyr::mutate(date = lubridate::ymd(date)) %>%
    dplyr::group_by(station) %>%
    dplyr::arrange(date)
  weather_cols <- names(weather)
  maxdates <- weather %>%
    dplyr::group_by(station) %>%
    dplyr::summarize(maxdate = max(date))
  
  #httr::set_config(httr::timeout(seconds = 120))
   
  # Pull raw data
  message("Pulling raw weather data")
  
  urls <- c('http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USR0000FOAS.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USR0000FRAC.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1FLBW0166.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USC00085184.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USC00080737.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1FLBW0099.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1FLBW0131.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1FLBW0103.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1FLBW0160.csv',
            'http://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/US1FLBW0139.csv')
  all <- lapply(urls, read.csv, header = TRUE, sep = ",", stringsAsFactors = FALSE)
  all <- do.call(dplyr::bind_rows, all) %>% 
    dplyr::rename_all(. %>% tolower) %>%
    dplyr::mutate(date = lubridate::ymd(date),
                  tmax = tmax/10,
                  tmin = tmin/10, 
                  tavg = tavg/10, 
                  tobs = tobs/10, 
                  prcp = prcp/10)
  
  all[,setdiff(weather_cols, names(all))] <- NA
    
  # Set up dataframe to append
    
  new_data <- all %>%
    dplyr::group_by(station) %>%
    dplyr::left_join(maxdates, by = "station") %>%
    dplyr::filter(is.na(maxdate)|date > maxdate) %>%
    dplyr::select(dplyr::all_of(weather_cols)) %>%
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


