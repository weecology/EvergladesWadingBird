#Create a few sample predictions
from deepforest import deepforest
from matplotlib import pyplot as plt
import geopandas as gpd
import shapely
import rasterio as rio
import numpy as np

src = rio.open("/orange/ewhite/everglades/Palmyra/palymra.tif")
numpy_image = src.read()
numpy_image = np.moveaxis(numpy_image,0,2)
numpy_image = numpy_image[:,:,:3].astype("float32")

model_path = "/orange/ewhite/everglades/Zooniverse/predictions/20210111_185722.h5"
model = deepforest.deepforest(weights=model_path)
model.config["save_path"] = "/orange/ewhite/everglades/Palmyra/"
boxes = model.predict_tile(numpy_image=numpy_image, return_plot=False, patch_size=2500)
boxes.to_csv("/orange/ewhite/everglades/Palmyra/boxes.csv")

bounds = src.bounds
pixelSizeX, pixelSizeY  = src.res

#subtract origin. Recall that numpy origin is top left! Not bottom left.
boxes["xmin"] = (boxes["xmin"] *pixelSizeX) + bounds.left
boxes["xmax"] = (boxes["xmax"] * pixelSizeX) + bounds.left
boxes["ymin"] = bounds.top - (boxes["ymin"] * pixelSizeY) 
boxes["ymax"] = bounds.top - (boxes["ymax"] * pixelSizeY)

# combine column to a shapely Box() object, save shapefile
boxes['geometry'] = boxes.apply(lambda x: shapely.geometry.box(x.xmin,x.ymin,x.xmax,x.ymax), axis=1)
boxes = gpd.GeoDataFrame(boxes, geometry='geometry')

boxes.crs = src.crs.to_wkt()

boxes.to_file("/orange/ewhite/everglades/Palmyra/predictions.shp")