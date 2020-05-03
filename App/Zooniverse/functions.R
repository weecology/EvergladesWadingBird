#functions
library(dplyr)
library(ggplot2)
library(leaflet)
library(sf)
library(gridExtra)
library(stringr)

#Site map
create_map<-function(colonies){
  m <- leaflet(data=colonies) %>% addTiles() %>% addMarkers(popup =~colony) 
  return(renderLeaflet(m))
}

#Load data
load_classifications<-function(){
  raw_data<-read_sf("data/species-classifications.shp")
  return(raw_data)
}

#Filter classification by spatial overlap
#TODO handle tie breaks better.

check_events<-function(x){
  if(str_detect(x,"_")){
    return(str_match(x,"(\\w+)_")[,2])
  }else{
    return(x)
  }
}
filter_annotations<-function(raw_data){
  selected_ids<-unique(raw_data$selected_i)
  
  #Majority rule for labels
  majority_rule<-raw_data %>% group_by(selected_i, tool_label) %>% summarize(n=n()) %>% arrange(desc(n)) %>% slice(1) %>% as.data.frame() %>% mutate(majority_class=tool_label) %>% dplyr::select(selected_i,majority_class)
  selected_boxes<-raw_data %>% filter(index %in% selected_ids) %>% inner_join(majority_rule)
  
  #!!Temp hotfix!!! until events are seperated from dates
  
  selected_boxes$event<-sapply(selected_boxes$event,check_events)
  selected_boxes$event<-as.Date(selected_boxes$event,"%m%d%Y")
  return(selected_boxes)
}

totals_plot<-function(selected_boxes){
  ggplot(selected_boxes) + geom_bar(aes(x=majority_class)) + coord_flip() + ggtitle("Project Total") + labs(x="Label") + theme(text = element_text(size=20))
}

site_totals<-function(selected_boxes){
  #Site totals
  selected_sites <-selected_boxes %>% group_by(site) %>% summarize(n=n()) %>% filter(n>2)
  to_plot<-selected_boxes %>% group_by(site,majority_class) %>% summarize(n=n()) %>% filter(site %in% selected_sites$site)
  ggplot(to_plot) + geom_col(aes(x=majority_class,y=n,fill=site),position = position_dodge()) + coord_flip() + labs(x="Label",y="Count",fill="Site") +
    theme(text = element_text(size=20))
}

site_phenology<-function(selected_boxes){
  to_plot<-selected_boxes %>% group_by(event,majority_class) %>% summarize(n=n()) 
  ggplot(to_plot,aes(x=event,y=n,col=majority_class)) + geom_point(size=7) + geom_line(linetype="dashed",aes(group=majority_class),size=3) + labs(x="Event",y="Count",col="label") + stat_smooth() +
    theme(text = element_text(size=20))
}


plot_annotations<-function(selected_boxes){
  pal <- colorFactor(
    palette = 'Dark2',
    domain = selected_boxes$majority_class
  )
  
  st_crs(selected_boxes)<-32617
  selected_centroids<-st_transform(selected_boxes,4326) %>% st_centroid()
  mapbox_url = "https://api.mapbox.com/styles/v1/bweinstein/ck94nmzn20an31imrz6ffplun/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYndlaW5zdGVpbiIsImEiOiJ2THJ4dWRNIn0.5Pius_0u0NxydUzkY9pkWA"
  m<-leaflet(data=selected_centroids,options = tileOptions(minZoom = 7, maxZoom = 22)) %>% addTiles(mapbox_url) %>% addCircles(color=~pal(majority_class),opacity = 0.5,radius = 0.1)
  return(m)
}

behavior_heatmap<-function(selected_boxes){
  
  class_totals<-selected_boxes %>% group_by(majority_class) %>% summarize(total=n())
  p<-selected_boxes %>% group_by(majority_class,subtask) %>% summarize(n=n()) %>% as.data.frame() %>% select(-geometry) %>% 
    inner_join(class_totals) %>% mutate(prop=n/total * 100) %>% ggplot(.) + 
    geom_tile(aes(x=majority_class,y=subtask,fill=n)) + 
    scale_fill_continuous(low="blue",high="red") + 
    labs(x="Label",y="Behavior",fill="% of Label Total") + theme(axis.text.x  = element_text(angle = -90),text = element_text(size=20))
  plot(p)
}
