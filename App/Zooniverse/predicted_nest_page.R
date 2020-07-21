predicted_nest_page<-function(nestdf){
  renderUI({
    fluidPage(
      titlePanel("Predicted Nest Detections"),
      p("Using a deep learning neural network, we predicted the location and number of individual birds in drone imagery aquired over the colonies. We then overlayed subsequent detections from each week of surveys to detect birds at the same location each week. \n Multiple detections of a bird at the same location is used as a proxy for nest location. Here we use four intersecting detections over the survey season as evidence of detection."),
      h2("Site Summary"),
      tableOutput("nest_summary_table"),
      selectInput("nest_site","Site",choices = unique(nestdf$Site),selected="Vacation"),
      plotOutput("nest_history_plot", height=400,width=700),
      uiOutput('nestdate'),
      leafletOutput("nest_map", height=1000,width=800)
    )})
}
