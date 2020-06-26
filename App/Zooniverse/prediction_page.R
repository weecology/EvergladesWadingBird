predicted_page<-function(df, selected_boxes){
    #Note, precompute the totals before shiny.
  renderUI({
    fluidPage(
      titlePanel("Predicted Counts"),
      p("Using a deep learning neural network, we predicted the location and number of individual birds in drone imagery aquired over the colonies. This work is in progress, but demonstrates the potential for broad scale monitering"),
      plotOutput("predicted_time_plot",height = 700,width = 1200),
      h1("View Predictions"),
      selectInput("prediction_site","Site",choices = available_list$site,selected="CypressCity"),
      leafletOutput("sample_prediction_map",height=800,width=1200),
      h2("Compare Zooniverse to Predicted"),
      p("Note some zooniverse colonies, such as 6th bridge, are still in progress."),
      p(tableOutput("Zooniverse_Predicted_Table"))
    )})
}

