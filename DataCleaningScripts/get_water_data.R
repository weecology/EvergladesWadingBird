#' Functions used to retrieve and process water gauge data
#'

`%>%` <- magrittr::`%>%`
source("DataCleaningScripts/download_eden.R")
source("DataCleaningScripts/eden_covariates.R")

# Downloads new EDEN depth data, calculates covariates, appends to covariate file

get_eden_data <- function() {

download_eden_depths()

covariate_data <- read.table("Water/eden_covariates.csv", header = TRUE, sep = ",")
new_data <- get_eden_covariates()
new_data2 <- get_eden_covariates(level="all")
new_data3 <- get_eden_covariates(level="wcas")
all_data <- dplyr::bind_rows(new_data,new_data2,new_data3) %>%
  dplyr::select(year, region=Name, variable, value) %>%
  as.data.frame() %>%
  dplyr::select(-geometry) %>%
  tidyr::pivot_wider(names_from="variable", values_from="value") %>%
  dplyr::arrange("year", "region")
new_covariates <- all_data %>%
  merge(dplyr::filter(covariate_data, !date %in% all_data$year)) %>%
  dplyr::arrange("year", "region")

depth_data <- read.table("Water/eden_depth.csv", header = TRUE, sep = ",") %>%
              dplyr::mutate(date=as.Date(date))
new_depths <- get_eden_depths() %>%
              dplyr::bind_rows(get_eden_depths(level="all")) %>%
              dplyr::bind_rows(get_eden_depths(level="wcas")) %>%
              dplyr::mutate(date=as.Date(date))
new_depths <- new_depths %>%
              merge(dplyr::filter(depth_data, !date %in% new_depths$date)) %>%
              dplyr::arrange("date", "region")

file.remove(dir(path=file.path('Water'),  pattern="_.*_depth.nc"))

return(list(new_covariates=new_covariates, new_depths=new_depths))
}

#' Writes new water data
#'
#'

update_water <- function() {

  data <- get_eden_data()

  write.table(data$new_covariates, "Water/eden_covariates.csv", row.names = FALSE, col.names = TRUE,
            na="", sep = ",", quote = FALSE)

  write.table(data$new_depths, file = "Water/eden_depth.csv",
              row.names = FALSE, col.names = TRUE, na = "", sep = ",", quote = FALSE)
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
