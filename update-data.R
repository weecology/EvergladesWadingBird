message("Updating weather station data")
source("DataCleaningScripts/get_new_weather.R"); append_weather()
message("Updating EDEN water data")
source("DataCleaningScripts/get_water_data.R"); update_water()
