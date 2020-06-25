predicted_page<-function(){
  renderUI({
    fluidPage(
      titlePanel("Predicted Counts"),
      p("Using a deep learning neural network, we predicted the location and number of individual birds in drone imagery aquired over the colonies. This work is inprogress, but demonstrate the potential for broad scale monitering"),
      plotOutput("predicted_time_plot",height = 800,width = 1000)
    )})
}