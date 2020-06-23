#Predict birds in imagery
import glob
from deepforest import deepforest
from deepforest import preprocess
import geopandas
import rasterio
from start_cluster import start
from distributed import wait

def project(raster_path, boxes):
    """
    Convert image coordinates into a geospatial object to overlap with input image. 
    Args:
        raster_path: path to the raster .tif on disk. Assumed to have a valid spatial projection
        boxes: a prediction pandas dataframe from deepforest.predict_tile()
    Returns:
        a geopandas dataframe with predictions in input projection.
    """
    with rasterio.open(raster_path) as dataset:
        bounds = dataset.bounds
        pixelSizeX, pixelSizeY  = dataset.res

    #subtract origin. Recall that numpy origin is top left! Not bottom left.
    boxes["xmin"] = (boxes["xmin"] *pixelSizeX) + bounds.left
    boxes["xmax"] = (boxes["xmax"] * pixelSizeX) + bounds.left
    boxes["ymin"] = bounds.top - (boxes["ymin"] * pixelSizeY) 
    boxes["ymax"] = bounds.top - (boxes["ymax"] * pixelSizeY)
    
    # combine column to a shapely Box() object, save shapefile
    boxes['geometry'] = boxes.apply(lambda x: shapely.geometry.box(x.xmin,x.ymin,x.xmax,x.ymax), axis=1)
    boxes = geopandas.GeoDataFrame(boxes, geometry='geometry')
    
    boxes.crs = dataset.crs.to_wkt()
    
    #Shapefiles could be written with geopandas boxes.to_file(<filename>, driver='ESRI Shapefile')
    
    return boxes

def run(model_path, tile_path, savedir="."):
    """Apply trained model to a drone tile"""
    
    model = deepforest.deepforest(weights=model_path)
    boxes = model.predict_tile(raster_path=tile_path, patch_overlap=0, patch_size=1500)
    
    #Project
    projected_boxes = project(tile_path, boxes)
    
    #Get filename
    basename = os.path.splitext(os.path.basename(tile_path))[0]
    fn = "{}/{}.shp".format(savedir,basename)
    projected_boxes.to_file(fn)
    
    return fn

def find_files():
    paths = glob.glob("/orange/ewhite/everglades/WadingBirds2020/**/*.tif")
    
    #remove UTM projected for the moment, unsure.
    paths = [x for x in paths if not "projected" in x]
    return paths

if __name__ == "__main__":
    client = start(gpus=2)
    
    model_path = "/orange/ewhite/everglades/Zooniverse/predictions/20200525_173758.h5"
    
    paths = find_files()
    futures = []
    for path in paths:
        future = client.map(run, path, model_path=model_path,savedir="/orange/ewhite/everglades/predictions")
        futures.append(future)
    
    wait(futures)
    
    