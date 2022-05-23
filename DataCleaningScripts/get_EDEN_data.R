library(rvest)
library(lubridate)
library(dplyr)
library(ncdf4)
library(raster)

get_data_info <- function() {
  url <- "https://sflthredds.er.usgs.gov/thredds/catalog/eden/depths/catalog.html"
  info <- url %>%
    read_html() %>%
    html_table()
  info <- info[[1]] %>%
    filter(Dataset != "depths") %>% #Drop directory name from first row
    rename(dataset = Dataset, size = Size, last_modified = `Last Modified`) %>%
    mutate(last_modified = as.POSIXct(last_modified,
                             format = "%Y-%m-%dT%H:%M:%S"))
}

get_data_urls <- function(file_names) {
  base_url <- "https://sflthredds.er.usgs.gov/thredds/fileServer/eden/depths"
  urls <- file.path(base_url, file_names)
  return(list(file_names = file_names, urls = urls))
}

get_last_download <- function(path, force_update = FALSE) {
  if ("last_download.csv" %in% list.files(path) & !force_update) {
    last_download <- read.csv(file.path(path, "last_download.csv"))
  } else {
    last_download <- data.frame(dataset = info$dataset, size = "0 Mbytes",
                       last_modified = as.POSIXct("1900-01-01 00:00:01",
                                         format = "%Y-%m-%d %H:%M:%S"))
  }
  return(last_download)
}

if (!dir.exists(download_path)) {
  dir.create(download_path, recursive = TRUE)
}

get_files_to_update <- function(eden_path, force_update = FALSE){
  info <- get_data_info()
  last_download <- get_last_download(download_path, force_update = force_update)
  to_update <- info %>%
    left_join(last_download, by = "dataset", suffix = c(".curr", ".last")) %>%
    filter(last_modified.curr > last_modified.last | size.curr != size.last | is.na(last_modified.last))
}

update_last_download <- function(eden_path){
  current_files <- list.files(download_path, pattern = "*_depth.nc")
  if (identical(sort(current_files), sort(info$dataset))) {
    write.csv(info, file.path(download_path, 'last_download.csv'))
  } else {
    warning("Some EDEN files that should have been downloaded are not\n",
            "present in the EDEN path so not updating last_download.csv")
  }
}

#' @name download_depths
#'
#' @title Download the EDEN depths data
#'
#' @param eden_path path where the EDEN data should be stored
#' @param force_update if TRUE update all data files even if checks indicate
#'   that remote files are unchanged since the current local copies were
#'   created
download_depths <- function(eden_path, force_update = FALSE) {
  to_update <- get_files_to_update(download_path, force_update = force_update)
  data_urls <- get_data_urls(to_update$dataset)
  options(timeout = 226)

  downloaded <- mapply(download.file,
    data_urls$urls,
    file.path(download_path, data_urls$file_names))

  update_last_download(eden_path)
}

combine_depths <- function(eden_path) {

}

download_depths("/home/ethan/edentest")

# Command line for combining all resulting .nc files
"ncks --mk_rec_dmn time 1991_q2_depth.nc 1991_q2_depth_fixed.nc"
"ncrcat *_depth.nc  eden_depth_combined.nc"