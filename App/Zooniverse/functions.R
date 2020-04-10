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

#Site map
create_map<-function(){
  m <- leaflet() %>% addTiles() %>% setView(-80.581699, 25.396143, zoom=10) 
  return(renderLeaflet(m))
}

#Load data
load_classifications<-function(){
  raw_data<-read_sf("data/species-classifications.shp")
  
  return(raw_data)
}

#Filter classification by spatial overlap
#TODO handle tie breaks better.
filter_annotations<-function(raw_data){
  selected_ids<-unique(raw_data$selected_i)
  
  #Majority rule for labels
  majority_rule<-raw_data %>% group_by(selected_i, tool_label) %>% summarize(n=n()) %>% arrange(desc(n)) %>% slice(1) %>% as.data.frame() %>% mutate(majority_class=tool_label) %>% dplyr::select(selected_i,majority_class)
  selected_boxes<-raw_data %>% filter(index %in% selected_ids) %>% inner_join(majority_rule)
  
  return(selected_boxes)
}

totals_plot<-function(selected_boxes){
  ggplot(selected_boxes) + geom_bar(aes(x=majority_class)) + coord_flip() + ggtitle("Project Total")
}

