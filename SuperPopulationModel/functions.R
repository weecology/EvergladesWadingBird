#Simulate population
library(R2jags)
library(stringr)
library(dplyr)
library(ggplot2)
library(reshape2)
library(patchwork)
#N mean intensity of nests (poisson lambda)
#Samples_per_month number of data collection events per month
#detection_rate the probability of detecting a nest given that it is present
#survival_rate the probability of a nest being active per sample

simulate<-function(true_state=500,weeks=10,samples_per_week=1,detection_rate=1, survival_rate=1, entry_rate=1){
  result<-list()
  
  #Simulate true data
  observed_data<-simulate_data(true_state = true_state, weeks = weeks, samples_per_week = samples_per_week,detection_rate = detection_rate, survival_rate = survival_rate, entry_rate = entry_rate)
  #create_time_plot(observed_data)
  
  #Fit model
  model<-fitModel(observed_data)
  chains<-getChains(model)
  
  posterior_plot<-posterior_plot_state(chains,entry_rate = entry_rate,detection_rate = detection_rate,survival_rate = survival_rate)

  popplot<-population_plot(observed_data,chains, true_state)
  
  Nstar_plot<-estimate_NStar(chains,true_state)
  
  beta_plot<-entering_nests(chains)
  
  print(posterior_plot + popplot +  {Nstar_plot + beta_plot} + plot_layout(ncol=1))
  
  result[["observed_data"]]<-observed_data
  
  return(result)
}

simulate_data<-function(true_state, weeks,samples_per_week=1, detection_rate=1,survival_rate=1, entry_rate=1){
  #For each nest in the true state, the probability of observation is conditional on presence and detection
  
  present<-array(dim=c(true_state,weeks))
  detected<-array(dim=c(true_state,weeks,samples_per_week))
  
  #Process
  for(nest in 1:true_state){
    #First week initial conditions
    present[nest,1]<-rbinom(n=1,size=1,p=entry_rate)
    
    for(week in 2:weeks){
      #Enter population if not present
      if(present[nest,week-1]==0){
        #The current model does not allow re-nesting, can be improved. Did this nest previously exist?
        if(sum(present[nest,],na.rm = T)>=1){
          present[nest,week]<-0
        }else{
          present[nest,week]<-rbinom(n=1,size=1,p=entry_rate)
        }
        #TODO Nests can enter and exit before being sampled entered * survived
      } else{
        #did the nest survive
        present[nest,week]<-rbinom(n=1,size=1,p=survival_rate)
      }
      
    }
  }
  
  #Observation
  for(nest in 1:true_state){
    for(week in 1:weeks){
      for(sample_event in 1:samples_per_week){
        if(present[nest,week]==1){
          detected[nest,week,sample_event]<-rbinom(n=1,size=1,p=detection_rate)
        }else{
          detected[nest,week,sample_event]<-0
        }}
    }
  }
  
  return(detected)
}

#Fit model
#Source model
source("model.R")

#Run Model
fitModel<-function(observed_data){
  
  #Parameters to track
  ParsStage <- c("state","omega","NStar","BetaStar","Beta","N")
  
  #Initail state
  initStage<-function(){
    list(present=array(dim=c(dim(observed_data)[1],dim(observed_data)[2]),data=1))
  }
  #Jags Data
  
  Dat<-list(
    Y=observed_data,
    Nests=dim(observed_data)[1],
    Weeks=dim(observed_data)[2],
    Samples=dim(observed_data)[3]
  )
  
  #MCMC options
  system.time(
    model<-jags(data=Dat,parameters.to.save=ParsStage,inits = initStage,model.file="model.jags",n.thin=1,n.iter=5000,n.burnin=4500,n.chains=2,DIC=F)
  )
  return(model)
}

#Parse chains
getChains<-function(model){
  
  pc<-reshape2::melt(model$BUGSoutput$sims.array)
  colnames(pc)<-c("Draw","chain","par","value")
  
  #extract parameter name
  pc$parameter<-data.frame(str_match(pc$par,"(\\w+)"))[,-1]
  
  #Extract index
  splitpc<-split(pc,pc$parameter)
  
  #single index
  splitpc[c("Beta","BetaStar","N")]<-lapply(
    splitpc[c("Beta","BetaStar","N")],function(x){
      sv<-data.frame(str_match(x$par,"(\\w+)\\[(\\d+)]"))[,3]
      pc<-data.frame(x,Week=as.numeric(as.character(sv)))  
    })
  
  #double index
  splitpc[c("state")]<-lapply(
    splitpc[c("state")],function(x){
      sv<-data.frame(str_match(x$par,"(\\w+)\\[(\\d+),(\\d+)]"))[,3:4]
      colnames(sv)<-c("Previous","Current")
      pc<-data.frame(x,sv)  
    }) 
  
  chains<-bind_rows(splitpc)
  return(chains)}

create_time_plot<-function(observed_data){
  df<-melt(observed_data)
  colnames(df)<-c("Nest","Week","sample","value")
  df<-df %>% group_by(Week,sample) %>% summarize(n=sum(value))  %>% ungroup() %>% mutate(Week=Week)
  df[is.na(df$n),"n"]<-0
  p<-df %>% ggplot(.,aes(x=Week,y=n)) + geom_point(group=1) + labs(x="Week",y="Nest Count") + ylim(0,max(df$n)+20) 
  return(p)
}

convergence_plot<-function(chains){
  p<-chains %>% filter(parameter=="state") %>% ggplot(.,aes(x=Draw,y=value,color=as.factor(chain))) + geom_line() + facet_wrap(~par)
  return(p)
}

posterior_plot_state<-function(chains,entry_rate,survival_rate,detection_rate){
  statelabels<-data.frame(label=c("Remain Inactive","Begin Nesting","Nest Failure","Nest Survival","Nest Detection"),par=c("state[1,1]","state[1,2]","state[2,1]","state[2,2]","omega"),true_value=c(1-entry_rate,entry_rate,1-survival_rate,survival_rate,detection_rate))
  p<-chains %>% filter(parameter %in% c("state","omega")) %>% inner_join(statelabels) %>% ggplot(.,aes(x=value)) + geom_histogram() + facet_wrap(~label,nrow=2) + geom_vline(aes(xintercept=true_value),linetype="dashed",col="red") + ggtitle("State Transitions")
  return(p)
}

population_plot<-function(observed_data, chains,true_state){
  df<-melt(observed_data)
  colnames(df)<-c("Nest","Week","sample","value")
  df<-df %>% group_by(Week,sample) %>% summarize(n=sum(value))  %>% ungroup() %>% mutate(Week=Week)
  df[is.na(df$n),"n"]<-0
  
  p<-chains %>% filter(parameter=="N") %>% group_by(Week) %>% summarize(mean=mean(value),lower=quantile(value,0.05),upper=quantile(value,0.95)) %>% ggplot(.,aes(x=Week)) + 
    geom_ribbon(aes(y=mean,ymin=lower,ymax=upper),alpha=0.5,col="blue") +
    geom_point(data=df,aes(y=`n`),col="black",size=2) + labs(y="Nest Count") + geom_hline(aes(yintercept=true_state),linetype="dashed",col="red")
  return(p)
}

estimate_NStar<-function(chains, true_value){
  #TODO change Beta to Betastar to reflect nests that start and fail between sampling periods
  Beta<-chains %>% filter(parameter=="Beta") %>% group_by(Draw,chain,parameter) %>% summarize(sumbeta=sum(value))
  N1<-chains %>% filter(parameter=="N",Week==1) %>% select(Draw,chain,par,value)
  combined<-Beta %>% inner_join(N1) %>% mutate(NStar=sumbeta + value)
  ggplot(combined,aes(x=NStar)) + geom_histogram() + geom_vline(aes(xintercept=true_value),col="red",linetype="dashed") + labs(x="Estimated Population Nest Count")
}

entering_nests<-function(chains){
  df<-chains %>% filter(parameter %in% c("Beta","BetaStar")) %>% group_by(Week,parameter) %>% summarize(mean=mean(value),lower=quantile(value,0.05),upper=quantile(value,0.95)) %>% ungroup() %>% droplevels() %>% mutate(parameter=as.factor(parameter))
  levels(df$parameter)<-c("Nest Starts","Nest Starts + Unseen Nest Failures")
  ggplot(df,aes(x=Week)) + 
    geom_ribbon(aes(y=mean,ymin=lower,ymax=upper,fill=parameter),alpha=0.5) + labs(y="Count")
}

view_sample <- function(chains){
  chains %>% filter(Draw==1,chain==1)%>% filter(Week==2,parameter %in% c("Beta","N")) %>% select(Draw,chain,Week,parameter,value) %>% tidyr::spread(parameter,value)
}

get_site<-function(x){
  site<-str_match(x,"(\\w+)_\\d+_\\d+_\\d+_projected")[,2]
  return(site)
}

get_event<-function(x){
  event<-str_match(x,"\\w+(_\\d+_\\d+_\\d+)_projected")[,2]
  event<-as.Date(event,"%m_%d_%Y")
  return(event)
}