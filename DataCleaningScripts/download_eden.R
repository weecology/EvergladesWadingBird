# Functions to find and download EDEN water depth data
#' @name get_metadata
#'
#' @title Get EDEN metadata
#'
#' @export
#'

get_metadata <- function() {
  url <- "https://sflthredds.er.usgs.gov/thredds/catalog/eden/depths/catalog.html"
  metadata <- url %>%
    rvest::read_html() %>%
    rvest::html_table()
  metadata <- as.data.frame(metadata[[1]]) %>%
    dplyr::filter(Dataset != "depths") %>% #Drop directory name from first row
    dplyr::rename(dataset = Dataset, size = Size, last_modified = `Last Modified`) %>%
    dplyr::mutate(last_modified = as.POSIXct(last_modified,
                             format = "%Y-%m-%dT%H:%M:%S"),
                  year = as.integer(substr(dataset, start = 1, stop = 4)))
}

#' @name get_data_urls
#'
#' @title Get EDEN depths data URLs for download
#'
#' @param file_names file names to download from metadata
#'
#' @return list of file urls
#'
#' @export
#'

get_data_urls <- function(file_names) {
  base_url <- "https://sflthredds.er.usgs.gov/thredds/fileServer/eden/depths"
  urls <- file.path(base_url, file_names)
  return(list(file_names = file_names, urls = urls))
}

#' @name get_last_download
#'
#' @title Get list of EDEN depths data already downloaded
#'
#' @param eden_path path where the EDEN data should be stored
#' @param metadata EDEN file metadata
#' @param force_update if TRUE update all data files even if checks indicate
#'   that remote files are unchanged since the current local copies were
#'   created
#'
#' @return table of files already downloaded
#'
#' @export
#'
get_last_download <- function(eden_path = file.path("Water"),
                              metadata, force_update = FALSE) {
  if ("last_download.csv" %in% list.files(eden_path) & !force_update) {
    last_download <- read.csv(file.path(eden_path, "last_download.csv")) %>%
                       dplyr::mutate(last_modified = as.POSIXct(last_modified))
  } else {
    last_download <- data.frame(dataset = metadata$dataset, size = "0 Mbytes",
                       last_modified = as.POSIXct("1900-01-01 00:00:01",
                                         format = "%Y-%m-%d %H:%M:%S"))
  }
  return(last_download)
}

#' @name get_files_to_update
#'
#' @title Determine list of new EDEN files to download
#'
#' @param eden_path path where the EDEN data should be stored
#' @param metadata EDEN file metadata
#' @param force_update if TRUE update all data files even if checks indicate
#'   that remote files are unchanged since the current local copies were
#'   created
#'
#' @export
#'
get_files_to_update <- function(eden_path = file.path("Water"),
                                metadata, force_update = FALSE){

  # Find files that have been updated since last download
  last_download <- get_last_download(eden_path, metadata, force_update = force_update)
  new <- metadata %>%
    dplyr::left_join(last_download, by = "dataset", suffix = c("", ".last")) %>%
    dplyr::filter(last_modified > last_modified.last | size != size.last | is.na(last_modified.last))
  
  unlink(file.path(eden_path, new$dataset))
  unchanged_files <- list.files("Water", pattern = "*_depth.nc")
  metadata %>%
    dplyr::filter(year %in% c(new$year-2, new$year-1, new$year, new$year+1, new$year+2)) %>%
    dplyr::filter(!(dataset %in% unchanged_files))
  }

#' @name update_last_download
#'
#' @title Write new metadata file for files already downloaded
#'
#' @param eden_path path where the EDEN data should be stored
#' @param metadata EDEN file metadata
#'
#' @export
#'
update_last_download <- function(eden_path = file.path("Water"),
                                 metadata){
  current_files <- list.files(eden_path, pattern = "*_depth.nc")
  write.csv(metadata, file.path(eden_path, 'last_download.csv'))
}

#' @name download_eden_depths
#'
#' @title Download the EDEN depths data
#'
#' @param eden_path path where the EDEN data should be stored
#' @param force_update if TRUE update all data files even if checks indicate
#'   that remote files are unchanged since the current local copies were
#'   created
#'
#' @return char vector of downloaded/updated files
#'
#' @export
#'
download_eden_depths <- function(eden_path = file.path("Water"),
                                 force_update = FALSE) {

  if (!dir.exists(eden_path)) {
    dir.create(eden_path, recursive = TRUE)
  }

  metadata <- get_metadata()
  to_update <- get_files_to_update(eden_path, metadata,
                                   force_update = force_update)
  data_urls <- get_data_urls(to_update$dataset)
  options(timeout = 500)

  downloaded <- mapply(download.file,
    data_urls$urls,
    file.path(eden_path, data_urls$file_names))

  return(file.path(eden_path, data_urls$file_names))
}
