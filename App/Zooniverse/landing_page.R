landing_page<-function(){
  renderUI({
    fluidPage(
      titlePanel("Landing page"),
      leafletOutput("map")
    )})
}