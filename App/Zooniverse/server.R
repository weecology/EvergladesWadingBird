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

  #Field site maps
  output$map <- create_map()
})
