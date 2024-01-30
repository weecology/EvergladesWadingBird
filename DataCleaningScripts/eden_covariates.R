# Calculate standard water depth covariates from EDEN data following WADEM model

#' @name load_boundaries
#'
#' @title Calculate dry days from everwader
#'
#' @param path path to regions shapefile
#' @param level region level to load (all, wcas, or subregions)
#'
#' @export
#'
load_boundaries <- function(path = file.path("SiteandMethods/regions"),
                            level = "subregions") {
  level <- tolower(level)
  boundaries <- sf::st_read(file.path(path,paste(level,".shp",sep = "")))
  return(boundaries)
}

#' @name calc_dry_days
#'
#' @title Calculate dry days from everwader
#'
#' @param depth_data depth .nc files
#'
#' @export
#'
calc_dry_days <- function(depth_data) {
  dry_days <- depth_data %>%
    dplyr::mutate(dry_days = dplyr::case_when(depth <= units::set_units(0, cm) ~
                                                units::set_units(1, d),
                                              depth > units::set_units(0, cm) ~ units::set_units(0, d),
                                              is.na(depth) ~ units::set_units(NA, d)),
                  .keep = "none") %>%
    stars::st_apply(c(1, 2), sum)
  return(dry_days)
}

#' @name calc_recession
#'
#' @title Calculate recession from everwader
#'
#' @param depth_data depth .nc files
#'
#' @export
#'
calc_recession <- function(depth_data) {
  times <- stars::st_get_dimension_values(depth_data, 'time')
  start_depth <- depth_data |>
    dplyr::filter(time == min(times)) |>
    stars::st_set_dimensions("time", values = NULL)
  end_depth <- depth_data |>
    dplyr::filter(time == max(times)) |>
    stars::st_set_dimensions("time", values = NULL)
  recession <- start_depth - end_depth
  days <- as.integer(max(times) - min(times))
  recession_rate <- recession / days
  return(recession_rate)
}

#' @name calc_reversals
#'
#' @title Calculate reversals following Peterson 2017
#'
#' @param depth_data depth .nc files
#'
#' @export
#'
calc_reversals <- function(depth_data) {
  end_date_position <- stars::st_dimensions(depth_data)$time$to
  depth_t <- depth_data[,,,2:end_date_position] |>
    stars::st_set_dimensions("time", values = seq(1, end_date_position - 1))
  depth_t_minus_1 <- depth_data[,,,1:(end_date_position - 1)] |>
    stars::st_set_dimensions("time", values = seq(1, end_date_position - 1))
  depth_deltas <- depth_t - depth_t_minus_1
  reversals <- depth_deltas %>%
    dplyr::mutate(reversal = dplyr::case_when(depth > units::set_units(0, cm) ~
                                                units::set_units(1, d),
                                              depth <= units::set_units(0, cm) ~ units::set_units(0, d),
                                              is.na(depth) ~ units::set_units(NA, d)),
                  .keep = "none") %>%
    stars::st_apply(c(1, 2), sum)
  return(reversals)
}


#' @name extract_region_means
#'
#' @title Calculate region means from raster data
#'
#' @param raster variable raster
#' @param regions regions polygons
#'
#' @return region means spdf
#'
#' @export
#'
extract_region_means <- function(raster, regions) {
  var_name <- names(raster)
  region_means <- terra::aggregate(raster, regions, mean, na.rm=TRUE) %>%
    setNames(., "value")
  if(all(is.nan(region_means$value))) {
    region_means_spdf <- regions %>%
      dplyr::mutate(variable = var_name, value = NA)
  } else {
  region_means_spdf <- regions %>%
    dplyr::mutate(variable = var_name, value = as.numeric(region_means$value)) %>%
    dplyr::mutate_if(is.numeric, list(~dplyr::na_if(., Inf))) %>%
    dplyr::mutate_if(is.numeric, list(~dplyr::na_if(., -Inf))) %>%
    dplyr::mutate_if(is.numeric, list(~dplyr::na_if(., NaN))) 
  }
  return(region_means_spdf)
}

#' @name available_years
#'
#' @title Get list of years available for covariate calculation
#'
#' @param eden_path path where the EDEN data should be stored
#'
#' @return vector of years
#'
#' @export
#'

available_years <- function(eden_path = file.path("Water")) {
  eden_data_files <- list.files(file.path(eden_path), pattern = '_depth.nc')

  # Find which years need to be updated since last download
  metadata <- get_metadata()
  last_download <- get_last_download(eden_path, metadata)
  new <- metadata %>%
    dplyr::left_join(last_download, by = "dataset", suffix = c("", ".last")) %>%
    dplyr::filter(last_modified > last_modified.last | size != size.last | is.na(last_modified.last))
  years <- eden_data_files %>%
    stringr::str_split('_', simplify = TRUE) %>%
    .[, 1] %>%
    unique() %>%
    .[. %in% c(new$year, new$year+1, new$year+2)]
  return(years)
}

#' @name get_eden_covariates
#'
#' @title Generate annual scale water covariates using EDEN data
#'
#' @param level region level to load (all, wcas, or subregions)
#' @param eden_path path where the EDEN data should be stored
#' @param years numeric vector of years to generate covariates for,
#' defaults to all available years
#' @param boundaries_path name of a shape file holding the boundaries
#' within which to calculate covariates
#'
#' @return data.frame covariate data including columns for region, year,
#' covariate, value, and the geometry of the region
#'
#' @export
#'
get_eden_covariates <- function(level = "subregions",
                                eden_path = file.path("Water"),
                                years = available_years(eden_path),
                                boundaries_path = file.path("SiteandMethods/regions"))
  {

  eden_data_files <- list.files(file.path(eden_path), pattern = '_depth.nc')
  boundaries <- load_boundaries(boundaries_path,level)
  examp_eden_file <- stars::read_stars(file.path(eden_path, eden_data_files[1]))
  boundaries_utm <- sf::st_transform(boundaries, sf::st_crs(examp_eden_file))

  covariates <- c()
  for (year in years) {
    print(paste("Processing ", year, "...", sep = ""))
    pattern <- file.path(paste(year, "_.*_depth.nc", sep = ''))
    pattern2 <- file.path(paste(as.numeric(year)-1, "_.*_depth.nc", sep = ''))
    pattern3 <- file.path(paste(as.numeric(year)-2, "_.*_depth.nc", sep = ''))
    nc_files <- c(list.files(eden_path, pattern3, full.names = TRUE),
                  list.files(eden_path, pattern2, full.names = TRUE),
                  list.files(eden_path, pattern, full.names = TRUE))
    year_data <- stars::read_stars(nc_files, along = "time") %>%
      setNames(., "depth") %>%
      dplyr::mutate(depth = dplyr::case_when(depth < units::set_units(0, cm) ~ units::set_units(0, cm),
                                             depth >= units::set_units(0, cm) ~ depth,
                                             is.na(depth) ~ units::set_units(NA, cm)))

    breed_start <- as.POSIXct(paste0(year, '-01-01'))
    breed_end <- as.POSIXct(paste0(year, '-06-30'))
    breed_season_data <- year_data %>%
      dplyr::filter(time >= breed_start, time <= breed_end)
    
    dry_start <- as.POSIXct(paste0(as.numeric(year)-2, '-03-31'))
    dry_end <- as.POSIXct(paste0(year, '-06-30'))
    dry_season_data <- year_data %>%
      dplyr::filter(time >= dry_start, time <= dry_end)

    # Do a pre-breed/post-breed split to allow pre-breeding recession calculations
    # following Peterson 2017. Peterson does this on a per species basis. To start
    # just pick the mid-point for the different species to split on
    pre_breed_end <- as.POSIXct(paste0(year, '-03-01'))
    pre_breed_season_data <- year_data %>%
      dplyr::filter(time >= breed_start, time <= pre_breed_end)
    post_breed_season_data <- year_data %>%
      dplyr::filter(time >= pre_breed_end, time <= breed_end)

    # Calculate depth_breed from everwader
    breed_season_depth <- breed_season_data %>%
      stars::st_apply(c(1, 2), mean) %>%
      setNames(., "breed_season_depth")
    init_depth <- breed_season_data[,,,1] %>%
      setNames(., "init_depth")

    # Calculate recession from everwader
    recession <- calc_recession(breed_season_data) %>%
      setNames(., "recession")
    pre_recession <- calc_recession(pre_breed_season_data) %>%
      setNames(., "pre_recession")
    post_recession <- calc_recession(post_breed_season_data) %>%
      setNames(., "post_recession")

    # Calculate dryindex from everwader (USGS code calculates this from t-3 3/31 to t 6/30)
    dry_days <- calc_dry_days(dry_season_data) %>%
      setNames(., "dry_days")

    # Calculate reversals following Peterson 2017
    reversals <- calc_reversals(breed_season_data) %>%
      setNames(., "reversals")

    predictors <- list(init_depth, breed_season_depth, recession, pre_recession,
                       post_recession, dry_days, reversals)
    for (predictor in predictors) {
      year_covariates <- extract_region_means(predictor, boundaries_utm) %>%
        dplyr::mutate(year = year)
      covariates <- rbind(covariates, year_covariates)
    }
  }
  return(covariates)
}

#' @name get_eden_depths
#'
#' @title Generate regional daily mean depth using EDEN data
#'
#' @param level region level to load (all, wcas, or subregions)
#' @param eden_path path where the EDEN data should be stored
#' @param years numeric vector of years to collect, defaults to all available years
#' @param boundaries_path name of a shape file holding the boundaries
#' within which to calculate depth
#'
#' @return data.frame covariate data including columns for region, date,
#' depth value, and the geometry of the region
#'
#' @export
#'
get_eden_depths <- function(level="subregions",
                            eden_path = file.path("Water"),
                            years = available_years(eden_path),
                            boundaries_path = file.path("SiteandMethods/regions"))
  {

  eden_data_files <- list.files(eden_path, pattern = '_depth.nc', full.names = TRUE)
  boundaries <- load_boundaries(boundaries_path,level)
  examp_eden_file <- stars::read_stars(file.path(eden_data_files[1]))
  boundaries_utm <- sf::st_transform(boundaries, sf::st_crs(examp_eden_file))

  new_data <- c()
  for (year in years) {
    print(paste("Processing ", year, "...", sep = ""))
    pattern <- file.path(paste(year, "_.*_depth.nc", sep = ''))
    nc_files <- list.files(eden_path, pattern, full.names = TRUE)
    year_data <- stars::read_stars(nc_files, along = "time") %>%
      setNames(., "depth") %>%
      dplyr::mutate(depth = dplyr::case_when(depth < units::set_units(0, cm) ~ units::set_units(0, cm),
                                             depth >= units::set_units(0, cm) ~ depth,
                                             is.na(depth) ~ units::set_units(NA, cm)))

    region_means <- terra::aggregate(year_data, boundaries_utm, mean, na.rm=TRUE)
    region_sd <- terra::aggregate(year_data, boundaries_utm, sd, na.rm=TRUE)
    region_max <- terra::aggregate(year_data, boundaries_utm, max, na.rm=TRUE)
    region_min <- terra::aggregate(year_data, boundaries_utm, min, na.rm=TRUE)

    new_year <- reshape_star(region_means, variable="depth_mean", year=year, boundaries=boundaries_utm) %>%
                merge(reshape_star(region_sd, variable="depth_sd", year=year, boundaries=boundaries_utm)) %>%
                merge(reshape_star(region_max, variable="depth_max", year=year, boundaries=boundaries_utm)) %>%
                merge(reshape_star(region_min, variable="depth_min", year=year, boundaries=boundaries_utm))

    new_data <- rbind(new_data, new_year)
  }
 return(new_data)
}

#' @name reshape_star
#'
#' @title Reshapes star object to dataframe
#'
#' @param data data to reshape
#' @param variable value to reshape on
#' @param year data year
#' @param boundaries boundaries object
#'
#' @return data.frame depth data including columns for region, date, depth type value
#'
#' @export
#'
reshape_star <- function(data, variable="depth", year, boundaries) {

 region_spdf <- boundaries %>% dplyr::mutate(value = data$depth)
 new_region <- as.data.frame(region_spdf$value) %>%
                              dplyr::mutate_all(as.double)
 colnames(new_region) <- as.character(as.Date(stars::st_get_dimension_values(data, 'time')))
 new_data <- new_region %>%
             dplyr::mutate(region = region_spdf$Name) %>%
             tidyr::pivot_longer(starts_with(as.character(year)),
             names_to = "date", values_to = "value") %>%
             dplyr::select(date, region, value) %>%
             dplyr::rename(!!variable := value)
 return(new_data)
}
