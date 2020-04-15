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
  
  #Create pages
  output$landing<-landing_page()
  output$time<-time_page(selected_boxes)
  output$species<-species_page()
  output$about<-about_page()
  output$colony<-colony_page(selected_boxes)
  
  ####Landing page###
  output$map <- create_map(selected_boxes)
  raw_data <- load_classifications()
  
  output$summary <- renderText(paste("There have been",nrow(raw_data),"classications on",length(unique(raw_data$frame)),"frames by", length(unique(raw_data$user_name)),"users at",length(unique(raw_data$site)),"sites"))
  output$totals_plot<-renderPlot(totals_plot(selected_boxes))
  output$site_totals_plot<-renderPlot(site_totals(selected_boxes))
  
  ###Time page###
  ###Colony page###
  time_series_filter<-reactive({
    #filter based on selection
    print(paste())
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
