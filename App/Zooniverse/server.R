#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

#Source page UIs
source("landing_page.R")
source("time_page.R")
source("species_page.R")
source("colony_page.R")
source("about_page.R")
source("functions.R")

shinyServer(function(input, output) {
   
  #create pages
  raw_data <- load_classifications()
  selected_boxes<-filter_annotations(raw_data)
  colonies<-st_read("data/colonies.csv", options=c("X_POSSIBLE_NAMES=longitude","Y_POSSIBLE_NAMES=latitude"))
  
  #Create pages
  output$landing<-landing_page(selected_boxes)
  output$time<-time_page(selected_boxes)
  output$species<-species_page()
  output$about<-about_page()
  output$colony<-colony_page(selected_boxes)
  
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
    leafletProxy("map", data=landing_map_select()) %>% clearMarkers() %>% addMarkers()
  })
  
  observe({
    output$site_totals_plot<-renderPlot(site_totals(selected_boxes=landing_filter()))
  })

  output$summary <- renderText(paste("There have been",nrow(raw_data),"classications on",length(unique(raw_data$frame)),"frames by", length(unique(raw_data$user_name)),"users at",length(unique(raw_data$site)),"sites"))
  output$totals_plot<-renderPlot(totals_plot(selected_boxes))

  ###Time page###
  ###Colony page###
  time_series_filter<-reactive({
    #filter based on selection
    to_plot <- selected_boxes %>% filter(site %in% input$timeseries_site, majority_class %in% input$timeseries_label) 
    return(to_plot)
  }) 
  
  observe({
    output$site_phenology_plot<-renderPlot(site_phenology(selected_boxes=time_series_filter()))
  })
  
  ###Species page###
  
  ###Colony page###
  colony_filter<-reactive({
  #filter based on selection
    to_plot <- selected_boxes %>% mutate(image=paste(site,event)) %>% filter(image==input$selected_image) 
    return(to_plot)
  })
  
  observe({
    output$colony_map<-renderLeaflet(plot_annotations(selected_boxes =colony_filter()))
  })
  
  
})
