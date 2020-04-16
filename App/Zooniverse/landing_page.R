landing_page<-function(selected_boxes){
  
  image_list<-c("All",selected_boxes$site)
  
  #TODO plots must be larger fonts
  renderUI({
    fluidPage(
      sidebarPanel(leafletOutput("map",height=900)),
      mainPanel(h1("Zooniverse Summary"),
      p(textOutput("summary")),
      plotOutput("totals_plot",height=400),
      h1("Select Sites Summary"),
      selectizeInput("landing_site", "Site", image_list, selected = "All", multiple = TRUE,options = NULL),
      plotOutput("site_totals_plot",height=400)
      )
    )})
}