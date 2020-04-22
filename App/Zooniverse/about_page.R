about_page<-function(){
  renderUI({
    fluidPage(
      titlePanel(""),
      h3(HTML("<a href='http://www.weecology.org/'>WEecology Lab - Interdiscliplinary Ecology</a>")),
      renderText("WEecology is an interdisciplinary ecology research group at the 
         University of Florida. We consist of Morgan Ernest’s lab, which studies how ecological systems 
         change through time and has a strong field work focus, and Ethan White’s lab which uses 
         computational and statistical methods to understand ecological systems using large ecological 
         and environmental datasets. We do cutting edge research, collect and publish large open datasets, 
         develop open source software, build websites, train scientists in computational tools, and 
         generally try to make science a better, more efficient, more diverse and inclusive place."),
      
      h3(HTML("<a href='http://wec.ifas.ufl.edu/people/wec-faculty/peter-frederick/'>
              Frederick Lab – Wetlands Ecology and Conservation</a>")),
      renderText("Interests in the Frederick lab are typically diverse, and centered around understanding 
         wetland processes both for their own sake, and as guides to restoration and conservation 
         activities."), 
      
      h3(HTML("<a href='http://www.zooniverse.org/'>Zooniverse</a>")),
      HTML("<p>These data are generated via the 
      <a href='https://www.zooniverse.org/'>Zooniverse.org</a> platform, the world’s largest and 
      most popular platform for people-powered research. Development is 
      funded by generous support, including a Global Impact Award from Google, and by a grant from 
      the Alfred P. Sloan Foundation.</p>"),
      
      h3("Everglades Field Team"),
      h5("Lindsey Garner, Research Coordinator, Everglades Projects"),
      HTML("<img src=http://wec.ifas.ufl.edu/media/wecifasufledu/images/people/faculty/frederick/LindseyGarner_profile.JPG>"),
      renderText("Lindsey Garner is the Research Coordinator for the South Florida Wading Bird Monitoring Project. 
      She received her BS and MS degrees at North Carolina State University where she studied relative 
      abundance, distribution, and the impacts of simulated harvest scenarios on American Alligator 
      populations of eastern North Carolina. She joined UF initially in 2014 and assisted in research 
      focused on native and exotic reptiles, amphibians, and crocodilians across the Greater Everglades 
      Ecosystem. As research coordinator, Lindsey trains seasonal Wading Bird field crew members, manages 
      the day-to-day field work, conducts impromptu airboat repair, and compiles annual reports. She holds 
      a remote pilot certificate and conducts aerial surveys for the lab’s new and exciting UAV program.")
    )})
}