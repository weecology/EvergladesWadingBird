colony_page<-function(selected_boxes){
  image_list<-paste(selected_boxes$site,selected_boxes$event)
  
  renderUI({
    fluidPage(
      titlePanel("Coming Soon: Visit the colonies!"),
      selectizeInput("selected_image", "Site", image_list, selected = image_list[1], multiple = TRUE,options = NULL),
      leafletOutput("colony_map")
    )})
}