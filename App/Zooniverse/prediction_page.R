predicted_page<-function(){
  renderUI({
    fluidPage(
      titlePanel("Predicted Counts"),
      p("Using a deep learning neural network, we predicted the location and number of individual birds in drone imagery aquired over the colonies. This work is in progress, but demonstrates the potential for broad scale monitering"),
      plotOutput("predicted_time_plot",height = 800,width = 1000),
      h1("Cypress City 3/25/2020"),
      leafletOutput("sample_prediction_map",height=800,width=1200),
      h2("Compare Zooniverse to Predicted"),
      p("Note some zooniverse colonies are still in progress"),
      p(tableOutput("Zooniverse_Predicted_Table"))
    )})
}

