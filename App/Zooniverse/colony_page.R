colony_page<-function(selected_boxes){
  image_list<-unique(paste(selected_boxes$site,selected_boxes$event))
  
  renderUI({
    fluidPage(
      titlePanel("Visit the colonies!"),
      selectizeInput("selected_image", "Site", image_list, selected = "6thBridge 03112020", multiple = FALSE,options = NULL),
      leafletOutput("colony_map",height=1000)
    )})
}