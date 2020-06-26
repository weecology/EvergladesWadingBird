predicted_page<-function(df, selected_boxes){
  available_list<-data.frame(site=c("CypressCity","Joule","Vacation","6thBridge","JetPort","Jerrod","Enlil","Aerie","Hidden","Yonteau","Frodo","Nanse","StartMel","Vulture"),
                             event=as.Date(c("2020-03-25","2020-03-24","2020-03-24","2020-03-18","2020-03-23","2020-03-24","2020-04-27","2020-04-27","2020-04-06","2020-04-27","2020-04-27","2020-04-08","2020-03-24","2020-04-14")))
  
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

