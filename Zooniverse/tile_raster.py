#load a raster and clip into pieces
from deepforest import preprocess
import argparse
from rasterio.mask import mask

def parse_args():
    parser = argparse.ArgumentParser(
        description='Simple script for cutting tif into tiles')
    parser.add_argument("--path")
    parser.add_argument("--save_dir",default=".")
    parser.add_argument("--patch_size",default=1000)
    
    return(parser.parse_args())

# Write the passed in dataset as a GeoTIFF
def writeImageAsGeoTIFF(img, transform, metadata, crs, filename):
    metadata.update({"driver":"GTiff",
                     "height":img.shape[1],
                     "width":img.shape[2],
                     "transform": transform,
                     "crs": crs})
    with rasterio.open(filename+".tif", "w", **metadata) as dest:
        dest.write(img)

def run(path,save_dir, patch_size=1000):
    """Read in raster, split into pieces and write to dir"""
    
    #Read image
    img = rasterio.open(path)
    basename = os.path.splitext(os.path.basename(path))[0]
    
    #Find windows
    windows = preprocess.compute_windows(img, patch_size=patch_size,patch_overlap=0.05)
    for window in windows:
        crop, cropTransform = mask(img, window.getIndices(), crop=True)        
        filename = "{}/{}".format(save_dir, basename)
        writeImageAsGeoTIFF(crop,
                            cropTransform,
                            img.meta,
                            img.crs,
                            filename+"_"+str(count))    
    
if __name__ == "__main__":
    #Parse args and run
    args = parse_args()
    
    run(args.path,args.save_dir,args.patch_size)
