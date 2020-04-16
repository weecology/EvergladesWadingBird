landing_page<-function(selected_boxes){
  
  image_list<-c("All",selected_boxes$site)
  
  renderUI({
    fluidPage(
      sidebarPanel(leafletOutput("map",height=900)),
      mainPanel(h2("Zooniverse Summary"),
      p(textOutput("summary")),
      plotOutput("totals_plot",height=400),
      h2("Select Sites"),
      selectizeInput("landing_site", "Site", image_list, selected = "All", multiple = TRUE,options = NULL),
      plotOutput("site_totals_plot",height=400)
      )
    )})
}