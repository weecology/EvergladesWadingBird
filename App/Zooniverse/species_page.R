species_page<-function(){
  renderUI({
    fluidPage(
      titlePanel("Species Summary"),
      h2("Behavior by label"),
      plotOutput("label_heatmap",height=600)
    )})
}