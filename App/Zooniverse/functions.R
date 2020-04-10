#functions
library(dplyr)
library(ggplot2)
library(leaflet)
library(sf)
library(raster)
library(gridExtra)
library(lidR)
library(rgl)
library(stringr)
library(reticulate)

create_map<-function(){

  m <- leaflet() %>% addTiles() %>% setView(-80.581699, 25.396143, zoom=10) 

  return(renderLeaflet(m))
}
