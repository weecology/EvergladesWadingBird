#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.

library(shiny)
library(htmltools)

#Source page UIs
source("landing_page.R")
source("time_page.R")
source("about_page.R")
source("prediction_page.R")
source("predicted_nest_page.R")
source("functions.R")

shinyServer(function(input, output) {
   
  #Load data
  raw_data <- load_classifications()
  selected_boxes<-filter_annotations(raw_data)
  colonies<-st_read("data/colonies.csv", options=c("X_POSSIBLE_NAMES=longitude","Y_POSSIBLE_NAMES=latitude"))
  
  #Setmapbox key
  readRenviron("source_token.txt")
  MAPBOX_ACCESS_TOKEN=Sys.getenv("MAPBOX_ACCESS_TOKEN")
  
  #Predictions
  df<-st_read("data/PredictedBirds.shp")
  df$event<-as.Date(df$event)
  df$tileset_id<-construct_id(df$site,df$event)
  
  #Nest predictions
  nestdf<-st_read("data/nest_detections.shp")
  
  #Create pages
  output$landing<-landing_page(selected_boxes)
  output$time<-time_page(selected_boxes)
  output$about<-about_page()
  output$colony<-colony_page(selected_boxes)
  output$predicted<-predicted_page(df)
  output$predicted_nests<-predicted_nest_page()
  
  ####Landing page###
  output$map <- create_map(colonies)
  landing_filter<-reactive({
    #filter based on selection
    if(is.null(input$landing_site)){return(selected_boxes)}
    if(!"All" %in% input$landing_site){
      to_plot <- selected_boxes %>% filter(site %in% input$landing_site) 
    }
    else{
      to_plot<-selected_boxes
    }
    return(to_plot)
  }) 
  
  landing_map_select<-reactive({
    #filter based on selection
    if(is.null(input$landing_site)){return(colonies)}
    if(!"All" %in% input$landing_site){
      to_plot <- colonies %>% filter(colony %in% input$landing_site) 
    } else{
      to_plot<-colonies
    }
    return(to_plot)
  }) 
  
  observe({
    leafletProxy("map", data=landing_map_select()) %>% clearMarkers() %>% addMarkers(popup=~colony)
  })
  
  observe({
    output$site_totals_plot<-renderPlot(site_totals(selected_boxes=landing_filter()))
  })

  output$summary <- renderText(paste("There have been",nrow(raw_data),"classifications on",length(unique(raw_data$subject_id)),"non-empty frames by", length(unique(raw_data$user_name)),"users at",length(unique(raw_data$site)),"sites"))
  output$totals_plot<-renderPlot(totals_plot(selected_boxes))
  
  # View Zooniverse annotations
  ###Colony page###
  time_series_filter<-reactive({
    #filter based on selection
    to_plot <- selected_boxes %>% filter(site %in% input$timeseries_site, species %in% input$timeseries_species,behavior %in% input$timeseries_behavior) 
    return(to_plot)
  }) 
  
  observe({
    output$site_phenology_plot<-renderPlot(site_phenology(selected_boxes=time_series_filter()))
  })
  
  ###Species page###
  output$label_heatmap<-renderPlot(behavior_heatmap(selected_boxes))
  
  ###Colony page###
  colony_filter<-reactive({
  #filter based on selection
    to_plot <- selected_boxes %>% mutate(image=paste(site,event)) %>% filter(image==input$selected_image) 
    return(to_plot)
  })
  
  observe({
    print(input$colony_map_zoom)
  })
  
  observe({
    output$colony_map<-renderLeaflet(plot_annotations(selected_boxes =colony_filter()))
  })
  
  ##Prediction page
  prediction_filter<-reactive({
    #filter based on selection
    to_plot <- df %>% filter(tileset_id==input$prediction_tileset) 
    return(to_plot)
  })
  
  output$predicted_time_plot<-renderPlot(time_predictions(df))
  output$sample_prediction_map<-renderLeaflet(plot_predictions(df=prediction_filter()))
  output$Zooniverse_Predicted_Table<-renderTable(compare_counts(df, selected_boxes))
  
  #Nest summary
  output$nest_summary_table <- renderTable(nest_summary_table(nestdf))
  output$nest_history_plot <- renderPlot(nest_history(nestdf))
  
})
