#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  
 h1("Superpopulation simulation"),
 inputPanel(h2("Parameters"),
            actionButton("simulate","Simulate"),
            textInput("N", "Population Size", value="10"),
            textInput("Weeks", "Weeks", value="10"),
            textInput("samples_per_week", "Samples per Week", value="1"),
            textInput("entry_rate", "Nesting Start Probability", value="0.8"),
            textInput("survivial_rate", "Survival Probability", value="0.8"),
            textInput("detection_rate", "Detection Probability ", value="0.7")
            ),
 #simulate data
 textOutput("Status"),
 h2("Data"),
 plotOutput("time_plot",height=400,width=800),
 plotOutput("posterior_plot",height=400,width=800),
 plotOutput("popplot",height=300,width=900)
))
