#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(reshape2)
library(ggplot2)
library(dplyr)

source("functions.R")
source("plotting_functions.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  observeEvent(input$simulate,{
    results<-simulate(N=as.numeric(input$N),weeks=as.numeric(input$Weeks),
                            samples_per_week = as.numeric(input$samples_per_week),
                            detection_rate = as.numeric(input$detection_rate),
                            survival_rate = as.numeric(input$survivial_rate),
                            entry_rate = as.numeric(input$entry_rate))
    
    output$time_plot<-renderPlot(create_time_plot(results$observed_data))
  })

})
