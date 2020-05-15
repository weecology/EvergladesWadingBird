library(raster)

r<-stack("/Users/Ben/Desktop/sample.tif")
e<-extent(r)
mean_x = mean(c(e@xmax,e@xmin))
mean_y = mean(c(e@ymax,e@ymin))

for(x in c(5,10,20,30)){
  xmin<-mean_x - x
  xmax<-mean_x + x
  ymin <- mean_y - x
  ymax <- mean_y + x
  f<-extent(xmin,xmax,ymin,ymax)
  rcrop<-crop(r,f)
  size = x *2
  writeRaster(rcrop,paste("/Users/Ben/Desktop/",size,"_sample.tif",sep=""),datatype="INT1U",overwrite=T)
}

