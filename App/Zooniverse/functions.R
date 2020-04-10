#functions
library(dplyr)
library(ggplot2)
library(leaflet)
library(sf)
library(gridExtra)
library(stringr)

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
  
  #!!Temp hotfix!!! until events are seperated from dates
  selected_boxes$event<-str_match(selected_boxes$event,"(\\w+)_")[,2]
  selected_boxes$event<-as.Date(selected_boxes$event,"%m%d%Y")
  return(selected_boxes)
}

totals_plot<-function(selected_boxes){
  ggplot(selected_boxes) + geom_bar(aes(x=majority_class)) + coord_flip() + ggtitle("Project Total")
}

site_totals<-function(selected_boxes){
  #Site totals
  selected_sites <-selected_boxes %>% group_by(site) %>% summarize(n=n()) %>% filter(n>2)
  to_plot<-selected_boxes %>% group_by(site,majority_class) %>% summarize(n=n()) %>% filter(site %in% selected_sites$site)
  ggplot(to_plot) + geom_col(aes(x=majority_class,y=n,fill=site),position = position_dodge()) + coord_flip() + ggtitle("Site Totals") + labs(x="Label",y="Count")
}

site_phenology<-function(selected_boxes){
  to_plot<-selected_boxes %>% group_by(event,majority_class) %>% summarize(n=n()) 
  ggplot(to_plot,aes(x=event,y=n,col=majority_class)) + geom_point() + geom_line(linetype="dashed",aes(group=majority_class)) + labs(x="Event",y="Count",col="label") + stat_smooth()
}

plot_annotations<-function(selected_boxes){
  m<-leaflet(data=selected_boxes) %>% addTiles() %>% addPolygons()
  return(m)
}