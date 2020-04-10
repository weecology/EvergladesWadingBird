time_page<-function(selected_boxes){
  #Selector options
  site_list<-unique(selected_boxes$site)
  label_list<-unique(selected_boxes$majority_class)
  
  renderUI({
    fluidPage(
      titlePanel("Select a site and label to see changes over time."),
      selectizeInput("timeseries_site", "Site", site_list, selected = site_list, multiple = TRUE,options = NULL),
      selectizeInput("timeseries_label", "Label", label_list, selected = label_list, multiple = TRUE,options = NULL),
      plotOutput("site_phenology_plot")
    )})
}