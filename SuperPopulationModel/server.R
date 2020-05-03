#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
source("functions.R")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  output$Status<-renderText("Status: Ready")
  
    observeEvent(input$simulate,{
    
    #Simulate data
    true_state<-simulate_true_state(as.numeric(input$N))
    output$Status<-renderText("Status: Simulating Data")
    
    observed_data<-simulate_data(true_state=true_state,weeks=as.numeric(input$Weeks),
                            samples_per_week = as.numeric(input$samples_per_week),
                            detection_rate = as.numeric(input$detection_rate),
                            survival_rate = as.numeric(input$survivial_rate),
                            entry_rate = as.numeric(input$entry_rate))
    
    output$time_plot<-renderPlot(create_time_plot(observed_data))
    
    output$Status<-renderText("Status: Fiting Model")
    withProgress(message = 'Calculation in progress', {
      model<-fitModel(observed_data)
    })
    
    #Get chains
    output$Status<-renderText("Status: Drawing posterior")
    chains<-getChains(model)
    
    output$posterior_plot<-renderPlot(posterior_plot_state(chains,
                                                           entry_rate = as.numeric(input$entry_rate),
                                                           detection_rate = as.numeric(input$detection_rate),
                                                           survival_rate = as.numeric(input$survivial_rate)))
    output$popplot<-renderPlot(population_plot(chains = chains, observed_data = observed_data, true_state = true_state))
    output$Nstarplot<-renerPlot(estimate_NStar(chains = chains,true_value = true_state))
  })
})