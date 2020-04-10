landing_page<-function(){
  renderUI({
    fluidPage(
      titlePanel("Landing page"),
      leafletOutput("map"),
      h1("Zooniverse Summary"),
      p(textOutput("summary")),
      plotOutput("totals_plot")
    )})
}