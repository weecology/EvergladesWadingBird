#Predict birds in imagery
import os
from deepforest import deepforest
from deepforest import preprocess
from distributed import wait
import geopandas
import glob
import numpy as np
import rasterio
from rasterio.warp import calculate_default_transform, reproject, Resampling
import re
import shapely
from start_cluster import start

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

def utm_project_raster(path, savedir="/orange/ewhite/everglades/utm_projected/"):
    
    basename = os.path.basename(os.path.splitext(path)[0])
    dest_name = "{}/{}_projected.tif".format(savedir,basename)
    
    #don't overwrite
    if os.path.exists(dest_name):
        print("{} exists, skipping".format(dest_name))
        return dest_name
    
    #Everglades UTM Zone
    dst_crs = 32617

    with rasterio.open(path) as src:
        transform, width, height = calculate_default_transform(
            src.crs, dst_crs, src.width, src.height, *src.bounds)
        kwargs = src.meta.copy()
        kwargs.update({
            'crs': rasterio.crs.CRS.from_epsg(dst_crs),
            'transform': transform,
            'width': width,
            'height': height
        })

        with rasterio.open(dest_name, 'w', **kwargs) as dst:
            for i in range(1, src.count + 1):
                reproject(
                    source=rasterio.band(src, i),
                    destination=rasterio.band(dst, i),
                    src_transform=src.transform,
                    src_crs=src.crs,
                    dst_transform=transform,
                    dst_crs=dst_crs,
                    resampling=Resampling.nearest)

    return dest_name

def run(tile_path, model_path, savedir="."):
    """Apply trained model to a drone tile"""
    
    #optionally project
    projected_path = utm_project_raster(tile_path)
    
    model = deepforest.deepforest(weights=model_path)
    
    #Read bigtiff using rasterio and rollaxis and set to BGR
    src = rasterio.open(projected_path)
    numpy_array = src.read()
    numpy_array_rgb = np.rollaxis(numpy_array, 0,3)    
    numpy_array_bgr = numpy_array_rgb[:,:,::-1]
    try:
        boxes = model.predict_tile(numpy_image=numpy_array_bgr, patch_overlap=0, patch_size=1500)
    except Exception as e:
        return "Tile {} returned {}".format(tile_path, e)
        
    #Project
    projected_boxes = project(projected_path, boxes)
    
    #Get filename
    basename = os.path.splitext(os.path.basename(projected_path))[0]
    fn = "{}/{}.shp".format(savedir,basename)
    projected_boxes.to_file(fn)
    
    return fn

def find_files():
    paths = glob.glob("/orange/ewhite/everglades/WadingBirds2020/**/*.tif",recursive=True)
    sites = ["Joule","CypressCity","Vacation","JetPort","Jerrod","StartMel","OtherColonies","6th Bridge"]
    paths = [x for x in paths if any(w in x for w in sites)]
    paths = [x for x in paths if not "projected" in x]
    
    return paths

def get_site(path):
    path = os.path.basename(path)    
    regex = re.compile("(\\w+)_\\d+_\\d+_\\d+_projected")
    return regex.match(path).group(1)

def get_event(path):
    path = os.path.basename(path)
    regex = re.compile('\\w+_(\\d+_\\d+_\\d+)_projected')
    return regex.match(path).group(1)

def load_shapefile(x):
    shp = geopandas.read_file(x)
    shp["site"] = get_site(x)
    shp["event"] = get_event(x)
    return shp
    
def summarize(paths):
    """Take prediction shapefiles and wrap into a single file"""
    shapefiles = [load_shapefile(x) for x in paths]
    summary = geopandas.GeoDataFrame(pd.concat(shapefiles,ignore_index=True),crs=shapefiles[0].crs)
    summary["label"] = "Bird"
    summary = summary[summary.score > 0.3]
    
    return summary
    
if __name__ == "__main__":
    client = start(gpus=8,mem_size="30GB")    
    model_path = "/orange/ewhite/everglades/Zooniverse/predictions/20200722_173611.h5"
    
    paths = find_files()
    print("Found {} files".format(len(paths)))
    
    #for path in paths:
        #run(model_path=model_path, tile_path=path, savedir="/orange/ewhite/everglades/predictions")
        
    futures = client.map(run, paths[0:2], model_path=model_path, savedir="/orange/ewhite/everglades/predictions")
    wait(futures)
    completed_predictions = []
    for x in futures:
        try:
            fn = x.result()
            completed_predictions.append(fn)
        except:
            pass
    
    #write output to zooniverse app
    df = summarize(completed_predictions)
    df.to_file("../App/Zooniverse/data/PredictedBirds.shp")
    
    
    
