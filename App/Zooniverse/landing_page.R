landing_page<-function(){
  
  #TODO plots must be larger fonts
  renderUI({
    fluidPage(
      leafletOutput("map"),
      h1("Zooniverse Summary"),
      p(textOutput("summary")),
      plotOutput("totals_plot",height=400),
      h1("Site Summary"),
      plotOutput("site_totals_plot",height=400)
    )})
}