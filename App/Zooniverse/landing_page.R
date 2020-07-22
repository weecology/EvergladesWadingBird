landing_page<-function(selected_boxes){
  
  site_list<-c("All",selected_boxes$site)
  select_image_list<-unique(selected_boxes$tileset_id)
  
  renderUI({
    fluidPage(
      sidebarPanel(leafletOutput("map",height=900)),
      mainPanel(h2("Zooniverse Summary"),
                p(textOutput("summary")),
                plotOutput("zooniverse_anotation"),
                
                plotOutput("totals_plot",height=400),
                h2("Select Sites"),
                selectizeInput("landing_site", "Site", site_list, selected = "All", multiple = TRUE,options = NULL),
                plotOutput("site_totals_plot",height=400),
                
                h2("View Annotations"),
                selectizeInput("selected_image", "Site", select_image_list, selected = "JetportSouth_03_23_2020", multiple = FALSE,options = NULL),
                leafletOutput("colony_map",height=1000)
      )
    )})
}