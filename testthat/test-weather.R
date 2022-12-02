context("checks new weather data")

weather <- read.csv(file = "../Weather/weather.csv",header=T) %>%
  dplyr::mutate(date = lubridate::ymd(date))
weather_cols <- colnames(weather)

test_that("required column names in new weather df", {
  
  expect_identical(weather_cols, 
                   c("date","station","daev","daev_attributes","dapr","dapr_attributes","dawm",
                     "dawm_attributes","evap","evap_attributes","mdev","mdev_attributes", "mdpr",
                     "mdpr_attributes","mdwm","mdwm_attributes","mnpn","mnpn_attributes","mxpn",
                     "mxpn_attributes","prcp","prcp_attributes","tavg","tavg_attributes","tmax",
                     "tmax_attributes","tmin","tmin_attributes","tobs","tobs_attributes","wdmv",
                     "wdmv_attributes","wt01","wt01_attributes","wt03","wt03_attributes","wt05",
                     "wt05_attributes","wt06","wt06_attributes","wt08","wt08_attributes","wt11",
                     "wt11_attributes","wt14","wt14_attributes","wt16","wt16_attributes"))
})

test_that("Dates valid", {
  
  expect_false(any(is.na(weather$date)))
})

test_that("Air Temperature ok", {
  
  expect_true(all(weather$tobs > -20, na.rm=TRUE))
  expect_true(all(weather$tobs <= 45, na.rm=TRUE))
  expect_true(all(weather$tavg > -20, na.rm=TRUE))
  expect_true(all(weather$tavg <= 60, na.rm=TRUE))  
  expect_true(all(weather$tmin > -20, na.rm=TRUE))
  expect_true(all(weather$tmin <= 45, na.rm=TRUE))
  expect_true(all(weather$tmax > -20, na.rm=TRUE))
  expect_true(all(weather$tmax <= 65, na.rm=TRUE))
  expect_true(all(weather$tmax >= weather$tmin, na.rm=TRUE))
})

test_that("Precipitation ok", {
  
  expect_true(all(weather$prcp >= 0, na.rm=TRUE))
})

test_that("no duplicated rows", {
  
  expect_false(any(duplicated(weather)))
})
