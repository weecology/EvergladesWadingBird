#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
library(shiny)
library(shinythemes)

#Define thumbnail dir
#Source additional pages

# Define UI for application that draws a histogram
shinyUI(fluidPage(theme = shinytheme("readable"),
                  
                  #Navbar to each page
                  navbarPage("Everglades Wading Birds",
                             tabPanel("Zooniverse",uiOutput('landing')),
                             tabPanel("Time Series",uiOutput('time')),
                             tabPanel("Predicted Counts",uiOutput('predicted')),
                             tabPanel("Predicted Nests",uiOutput('predicted_nests')),
                             tabPanel("About",uiOutput('about'))
                  )))
