#Simulate population
#N mean intensity of nests (poisson lambda)
#Samples_per_month number of data collection events per month
#detection_rate the probability of detecting a nest given that it is present
#survival_rate the probability of a nest being active per sample

simulate<-function(N=100,weeks=10,samples_per_week=1,detection_rate=0.8, survival_rate=0.95, entry_rate=0.5){
  result<-list()
  
  true_state<-simulate_true_state(N)
  observed_data<-simulate_data(N, weeks, samples_per_week,detection_rate, survival_rate, entry_rate)
  #parameters<-extract_parameters(observed_data)
  #fited_model<-fit_model()
  #estimate_state<-predict()
  
  result[["observed_data"]]<-observed_data
  
  return(result)
}

simulate_true_state<-function(N=100){
  return(rpois(1,N))
}

simulate_data<-function(true_state, weeks,samples_per_week=1, detection_rate=1,survival_rate=0.5, entry_rate=0.5){
  #For each nest in the true state, the probability of observation is conditional on presence and detection

  present<-array(dim=c(true_state,weeks))
  survival<-array(dim=c(true_state,weeks))
  detected<-array(dim=c(true_state,weeks,samples_per_week))
  
  #Process
  for(nest in 1:true_state){
    #First week initial conditions
    present[nest,1]<-rbinom(n=1,size=1,p=entry_rate)
    survival[nest,1]<-present[nest,1]
    
    for(week in 2:weeks){
        #Enter population if not present
        if(present[nest,week-1]==0){
          present[nest,week]<-rbinom(n=1,size=1,p=entry_rate)
        } else{
          present[nest,week]<-1
        }
        
        #Remain in population if survived
        if(present[nest,week]==1){
          survival[nest,week]<-rbinom(n=1,size=1,p=survival_rate)
        } else{
          survival[nest,week]<-0
        }
      }
  }
  
  #Observation
  for(nest in 1:true_state){
    for(week in 1:weeks){
        if(survival[nest,week]==1){
          for(sample in samples_per_week){
            detected[nest,week,sample]<-rbinom(n=1,size=1,p=detection_rate)
        }}
          else{
          detected[nest,week,sample]<-0
        }
    }
  }

  return(detected)
}
