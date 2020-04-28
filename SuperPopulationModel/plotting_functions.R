#Plotting functions
create_time_plot<-function(observed_data){
  df<-melt(observed_data)
  colnames(df)<-c("Nest","Week","sample","value")
  p<-df %>% group_by(Week,sample) %>% summarize(n=sum(value)) %>% 
    ggplot(.,aes(x=as.character(Week),y=n)) + geom_line(group=1) + labs(x="Week",y="Nest Count") + ylim(0,max(df$value)+10) 
  return(p)
}
