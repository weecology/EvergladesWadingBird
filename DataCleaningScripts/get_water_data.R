#' Functions used to reshape and clean water gage data
#'

`%>%` <- magrittr::`%>%`

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

#' Appends new water data
#'
#'

append_water <- function() {
  
  new_data_files <- list.files("~/Downloads/eve_data", full.names = TRUE)
  
  data <- new_data_files %>%
          lapply(get_water_data) %>%
          bind_rows %>%
          dplyr::arrange(date,station)
  
  # append new data
  write.table(data, file = "Water/level.csv",
              row.names = FALSE, col.names = FALSE, na = "", append = TRUE, sep = ",")
}
