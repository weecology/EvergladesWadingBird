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
source("site_page.R")
source("species_page.R")
source("about_page.R")
source("functions.R")

shinyServer(function(input, output) {
   
  #create pages
  output$landing<-landing_page()
  output$site<-site_page()
  output$species<-species_page()
  output$about<-about_page()

  ####Landing page###
  output$map <- create_map()
  raw_data <- load_classifications()
  selected_boxes<-filter_annotations(raw_data)
  
  output$summary <- renderText(paste("There have been",nrow(raw_data),"classications on",length(unique(raw_data$frame)),"frames by", length(unique(raw_data$user_name)),"users at",length(unique(raw_data$site)),"sites"))
  output$totals_plot<-renderPlot(totals_plot(selected_boxes))
})
