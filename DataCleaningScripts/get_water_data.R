#' Functions used to retrieve and process water gauge data
#'

`%>%` <- magrittr::`%>%`

# Downloads new EDEN depth data, calculates covariates, appends to covariate file

get_eden_data <- function() {

wader::download_eden_depths()

new_data <- wader::get_eden_covariates()
new_data2 <- wader::get_eden_covariates(level="all")
new_data3 <- wader::get_eden_covariates(level="wcas")
all_data <- dplyr::bind_rows(new_data,new_data2,new_data3) %>%
  dplyr::select(.data$year, region=.data$Name, .data$variable, .data$value) %>%
  as.data.frame() %>%
  dplyr::select(-geometry) %>%
  tidyr::pivot_wider(names_from="variable", values_from="value") %>%
  dplyr::arrange("year", "region")

levels <- c("subregions", "all", "wcas")
new_depths <- sapply(levels, wader::get_eden_depths)
new_depths <- dplyr::bind_cols(date=new_depths[[2]], region=new_depths[[1]], depth=new_depths[[3]]) %>%
  dplyr::bind_rows(dplyr::bind_cols(date=new_depths[[5]], region=new_depths[[4]], depth=new_depths[[6]])) %>%
  dplyr::bind_rows(dplyr::bind_cols(date=new_depths[[8]], region=new_depths[[7]], depth=new_depths[[9]])) %>%
  dplyr::mutate(date=as.Date(date))

return(list(new_covariates=new_covariates, new_depths=new_depths))
}

#' Appends new water data
#'
#'

update_water <- function() {

  data <- get_eden_data()

  write.table(data$new_covariates, "../Water/eden_covariates.csv", row.names = FALSE, col.names = TRUE,
            na="", sep = ",", quote = FALSE)

  write.table(data$new_depths, file = "../Water/eden_depth.csv",
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
