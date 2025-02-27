#' Functions used to retrieve and process water gauge data
#'

`%>%` <- magrittr::`%>%`
source("DataCleaningScripts/download_eden.R")
source("DataCleaningScripts/eden_covariates.R")

# Downloads new EDEN depth data, calculates covariates, appends to covariate file

get_eden_data <- function() {
  
metadata <- get_metadata()
last_download <- get_last_download() %>% dplyr::select(-X)

if(identical(metadata,last_download)) {
  return(NULL)
} else {

download_eden_depths()
  
covariate_data <- read.table("Water/eden_covariates.csv", header = TRUE, sep = ",")
new_covariates <- get_eden_covariates() %>%
                  dplyr::bind_rows(get_eden_covariates(level="all")) %>%
                  dplyr::bind_rows(get_eden_covariates(level="wcas")) %>%
                  dplyr::select(year, region=Name, variable, value) %>%
                  as.data.frame() %>%
                  dplyr::select(-geometry) %>%
                  tidyr::pivot_wider(names_from="variable", values_from="value") %>%
                  dplyr::mutate(year = as.integer(year)) %>%
                  dplyr::arrange("year", "region")
covariate_data <- dplyr::filter(covariate_data, !year %in% new_covariates$year) %>%
                  rbind(new_covariates) %>%
                  dplyr::arrange("year", "region")

depth_data <- read.table("Water/eden_depth.csv", header = TRUE, sep = ",") %>%
              dplyr::mutate(date=as.Date(date))
new_depths <- get_eden_depths() %>%
              dplyr::bind_rows(get_eden_depths(level="all")) %>%
              dplyr::bind_rows(get_eden_depths(level="wcas")) %>%
              dplyr::mutate(date=as.Date(date))

depth_data <- dplyr::filter(depth_data, !date %in% new_depths$date) %>%
              rbind(new_depths) %>%
              dplyr::arrange("date", "region")

update_last_download(metadata = metadata)
}

return(list(covariate_data=covariate_data, depth_data=depth_data))
}

#' Writes new water data
#'
#'

update_water <- function() {

  data <- get_eden_data()
  
  if(is.null(data)) { 
    return(cat("...No new data..."))
    } else {

  write.table(data$covariate_data, "Water/eden_covariates.csv", row.names = FALSE, col.names = TRUE,
            na="", sep = ",", quote = FALSE)

  write.table(data$depth_data, file = "Water/eden_depth.csv",
              row.names = FALSE, col.names = TRUE, na = "", sep = ",", quote = FALSE)
    }
}

#' Reads downloaded sophia.usgs gauge files
#' Reshapes into long format

get_water_data <- function(data_path) {

water_level1 <- read_csv(data_path,
                         col_types = cols(.default = "c"),
                         skip = 3)

water_level <- water_level1 %>%
              dplyr::select(-"Water level quality flag (F=final; P=provisional; R=real-time)") %>%
               dplyr::rename(date=Date) %>%
               tidyr::pivot_longer(
                 cols = dplyr::ends_with(c("NAVD88)", "M=missing)")),
                                   names_to = c("station","column"),
                                   names_sep = " ",
                                   values_to = "value") %>%
  dplyr::mutate(column = replace(column, column=="Daily", "level"),
                column = replace(column, column=="Water", "type")) %>%
  tidyr::pivot_wider(names_from = column, values_from = value) %>%
  filter(!is.na(level))

}
