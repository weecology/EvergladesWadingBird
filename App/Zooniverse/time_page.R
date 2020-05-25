time_page<-function(selected_boxes){
  #Selector options
  site_list<-unique(selected_boxes$site)
  species_list<-unique(selected_boxes$species)
  behavior_list<-unique(selected_boxes$behavior)
  
  renderUI({
    fluidPage(
      titlePanel("Select a site and label to see changes over time."),
      selectizeInput("timeseries_site", "Site", site_list, selected = site_list, multiple = TRUE,options = NULL),
      selectizeInput("timeseries_species", "Species", species_list, selected = species_list, multiple = TRUE,options = NULL),
      selectizeInput("timeseries_behavior", "Behavior", behavior_list, selected = behavior_list, multiple = TRUE,options = NULL),
      plotOutput("site_phenology_plot",height=700)
    )})
}