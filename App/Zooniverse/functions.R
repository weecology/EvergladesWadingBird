#functions
library(dplyr)
library(ggplot2)
library(leaflet)
library(sf)
library(gridExtra)
library(stringr)
library(htmltools)


#Site map
create_map<-function(colonies){
  m <- leaflet(data=colonies) %>% addTiles() %>% addMarkers(popup =~colony) 
  return(renderLeaflet(m))
}

#Load data
load_classifications<-function(){
  raw_data<-read_sf("data/everglades-watch-classifications.shp")
  st_crs(raw_data)<-32617
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
  majority_rule<-raw_data %>% group_by(selected_i, label) %>% summarize(n=n()) %>% arrange(desc(n)) %>% slice(1) %>% as.data.frame() %>% mutate(majority_class=label) %>%
    dplyr::select(selected_i,majority_class)
  
  selected_boxes<-raw_data %>% filter(selected_i %in% selected_ids) %>% inner_join(majority_rule) %>% filter(!is.na(event))
  
  #!!Temp hotfix!!! until events are seperated from dates
  #selected_boxes$event<-sapply(selected_boxes$event,check_events)
  selected_boxes$event[selected_boxes$event %in% "03112020"]<-gsub(x=selected_boxes$event[selected_boxes$event %in% "03112020"],pattern="03112020",replacement="03_11_2020")
  
  selected_boxes$event<-as.Date(selected_boxes$event,"%m_%d_%Y")
  return(selected_boxes)
}

totals_plot<-function(selected_boxes){
  ggplot(selected_boxes) + geom_bar(aes(x=species)) + coord_flip() + ggtitle("Project Total") + labs(x="Label") + theme(text = element_text(size=20))
}

site_totals<-function(selected_boxes){
  #Site totals
  selected_sites <-selected_boxes %>% group_by(site) %>% summarize(n=n()) %>% filter(n>2)
  to_plot<-selected_boxes %>% group_by(site,species) %>% summarize(n=n()) %>% filter(site %in% selected_sites$site)
  ggplot(to_plot) + geom_col(aes(x=species,y=n,fill=site),position = position_dodge()) + coord_flip() + labs(x="Label",y="Count",fill="Site") +
    theme(text = element_text(size=20))
}

site_phenology<-function(selected_boxes){
  to_plot<-selected_boxes %>% group_by(event,species,behavior) %>% summarize(n=n()) 
  ggplot(to_plot,aes(x=event,y=n,col=species,shape=behavior)) + geom_point(size=5) + geom_line(size=1) + labs(x="Event",y="Count",col="label") + stat_smooth() +
    theme(text = element_text(size=20))
}

plot_annotations<-function(selected_boxes){
  pal <- colorFactor(
    palette = 'Dark2',
    domain = selected_boxes$species
  )
  
  selected_centroids<-st_transform(selected_boxes,4326)
  mapbox_url = "https://api.mapbox.com/styles/v1/bweinstein/ck94nmzn20an31imrz6ffplun/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYndlaW5zdGVpbiIsImEiOiJ2THJ4dWRNIn0.5Pius_0u0NxydUzkY9pkWA"
  m<-leaflet(data=selected_centroids,options=tileOptions(maxNativeZoom =22, maxZoom = 24)) %>% addTiles(mapbox_url,options=providerTileOptions(minZoom = 8, maxNativeZoom=22, maxZoom = 24)) %>%
    addCircles(stroke = T,color=~pal(species),fillOpacity = 0.1,radius = 0.25,popup = ~htmlEscape(label))
  return(m)
}

plot_predictions<-function(df){
  df<-df %>% filter(score>0.40)
  df<-st_transform(df,4326)
  mapbox_url = "https://api.mapbox.com/styles/v1/bweinstein/ck94nmzn20an31imrz6ffplun/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYndlaW5zdGVpbiIsImEiOiJ2THJ4dWRNIn0.5Pius_0u0NxydUzkY9pkWA"
  m<-leaflet(data=df,options=tileOptions(maxNativeZoom = 22, maxZoom = 24)) %>% addTiles(mapbox_url,options=providerTileOptions(minZoom = 8, maxNativeZoom=22, maxZoom = 24)) %>%
    addCircles(stroke = T,fillOpacity = 0.1,radius = 0.25,popup = ~htmlEscape(paste(label,round(score,2),sep=":")))
  return(m)
}

behavior_heatmap<-function(selected_boxes){
  
  class_totals<-selected_boxes %>% group_by(majority_class) %>% summarize(total=n())
  p<-selected_boxes %>% group_by(majority_class,behavior) %>% summarize(n=n()) %>% as.data.frame() %>% select(-geometry) %>% 
    inner_join(class_totals) %>% mutate(prop=n/total * 100) %>% ggplot(.) + 
    geom_tile(aes(x=majority_class,y=behavior,fill=n)) + 
    scale_fill_continuous(low="blue",high="red") + 
    labs(x="Label",y="Behavior",fill="% of Label Total") + theme(axis.text.x  = element_text(angle = -90),text = element_text(size=20))
  plot(p)
}

time_predictions<-function(df){
  #only plot sites with more than one event
  site_names <- df %>% as.data.frame() %>% select(site,event) %>% group_by(site) %>% summarize(n=length(unique(event))) %>% filter(n>1) %>% .$site
  df %>% group_by(site,event) %>% filter(site %in% site_names,score>0.40) %>% summarize(n=n()) %>% ggplot(.,aes(x=event,y=n)) + geom_point() + geom_line() + facet_wrap(~site,ncol=3,scales="free") + labs(y="Predicted Birds",x="Date") + theme(text = element_text(size=20))
}

compare_counts<-function(df, selected_boxes){
  automated_count<-data.frame(df) %>% filter(score>0.40) %>% select(site,event) %>% group_by(site,event) %>% summarize(predicted=n())
  zooniverse_count<-data.frame(selected_boxes) %>% select(site,event) %>% group_by(site,event) %>% summarize(Zooniverse=n())
  comparison_table<-automated_count %>% inner_join(zooniverse_count) %>% mutate(event=as.character(event))
  comparison_table<-comparison_table %>% filter(!site=="6thBridge")
  return(comparison_table)
}

##Nest detection
nest_summary_table<-function(nestdf){
  nest_table <- nestdf %>% as.data.frame() %>% group_by(Site, target_ind) %>% 
    summarize(n=n()) %>% filter(n>3) %>% group_by(Site) %>% summarize(Nests=n(), Average_Detections = mean(n)) 
  return(nest_table)
}

#TODO create array table
nest_history<-function(nestdf){
  as_df <- nestdf %>% as.data.frame()
  dat<-as_df %>% group_by(Site, target_ind) %>% 
    summarize(n=n()) %>% filter(n>3) %>% group_by(Site) %>% inner_join(as_df) %>% droplevels() %>% group_by(Site) %>%
    mutate(reindex=as.character(as.numeric(as.factor(target_ind))),Date=as.Date(Date,"%m_%d_%Y"))
  
  date_order<-data.frame(o=unique(dat$Date),j=format(unique(dat$Date),format="%j")) %>% arrange(j)
  dat$factorDate<-factor(dat$Date,labels=format(date_order$o,format="%b-%d"),ordered = T)
  #set order
  ggplot(dat, aes(x=reindex,y=factorDate)) + facet_wrap(~Site,scales="free",ncol=2) + geom_tile() + coord_flip() + theme(axis.text.y = element_blank()) + labs(y="Nest") +
    theme(axis.text.x  = element_text(angle = -90),text = element_text(size=20))
}
