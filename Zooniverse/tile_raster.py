#load a raster and clip into pieces
from deepforest import preprocess
import argparse
import os
import rasterio
from rasterio.mask import mask
from shapely.geometry import box

def parse_args():
    parser = argparse.ArgumentParser(
        description='Simple script for cutting tif into tiles')
    parser.add_argument("--path")
    parser.add_argument("--save_dir",default=".")
    parser.add_argument("--patch_size",default=1000)
    
    return(parser.parse_args())

# Takes a Rasterio dataset and splits it into squares of dimensions squareDim * squareDim
def splitImageIntoCells(img, filename, squareDim):
    numberOfCellsWide = img.shape[1] // squareDim
    numberOfCellsHigh = img.shape[0] // squareDim
    x, y = 0, 0
    count = 0
    for hc in range(numberOfCellsHigh):
        y = hc * squareDim
        for wc in range(numberOfCellsWide):
            x = wc * squareDim
            geom = getTileGeom(img.transform, x, y, squareDim)
            getCellFromGeom(img, geom, filename, count)
            count = count + 1

# Generate a bounding box from the pixel-wise coordinates using the original datasets transform property
def getTileGeom(transform, x, y, squareDim):
    corner1 = (x, y) * transform
    corner2 = (x + squareDim, y + squareDim) * transform
    return box(corner1[0], corner1[1],
                        corner2[0], corner2[1])

# Write the passed in dataset as a GeoTIFF
def writeImageAsGeoTIFF(img, transform, metadata, crs, filename):
    metadata.update({"driver":"GTiff",
                     "height":img.shape[1],
                     "width":img.shape[2],
                     "transform": transform,
                     "crs": crs})
    with rasterio.open(filename+".tif", "w", **metadata) as dest:
        dest.write(img)

# Crop the dataset using the generated box and write it out as a GeoTIFF
def getCellFromGeom(img, geom, filename, count):
    crop, cropTransform = mask(img, [geom], crop=True)
    writeImageAsGeoTIFF(crop,
                        cropTransform,
                        img.meta,
                        img.crs,
                        filename+"_"+str(count))
    
def run(path,save_dir, patch_size=1000):
    """Read in raster, split into pieces and write to dir
    Returns:
        filename: path to directory of images
    """
    
    #Read image
    img = rasterio.open(path)
    basename = os.path.splitext(os.path.basename(path))[0]
    
    #Find windows
    filename = os.path.join(save_dir,basename)
    splitImageIntoCells(img, filename, patch_size)
    
    return filename