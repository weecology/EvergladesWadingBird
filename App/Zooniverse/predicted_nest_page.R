predicted_nest_page<-function(){
  renderUI({
    fluidPage(
      titlePanel("Predicted Nest Detections"),
      p("Using a deep learning neural network, we predicted the location and number of individual birds in drone imagery aquired over the colonies. We then overlayed subsequent detections from each week of surveys to detect birds at the same location each week. \n Multiple detections of a bird at the same location is used as a proxy for nest location. Here we use four intersecting detections over the survey season as evidence of detection."),
      h2("Site Summary"),
      tableOutput("nest_summary_table"),
      p("Nest Detection Histories"),
      plotOutput("nest_history_plot",height=1500,width = 1100)
    )})
}
