#Bird Bird Bird Detector
import glob
import geopandas
import rtree
import rasterio
import os
import pandas as pd
import cv2


from rasterio.windows import from_bounds

def load_files(dirname):
    """Load shapefiles and concat into large frame"""
    shapefiles = glob.glob(dirname + "*.shp")
    
    #load all shapefiles to create a dataframe
    df = []
    for x in shapefiles:
        eventdf = geopandas.read_file(x)
        eventdf["Site"] = get_site(x)
        eventdf["Date"] = get_date(x)
        df.append(eventdf)
    
    df = geopandas.GeoDataFrame(pd.concat(df, ignore_index=True))
    df.crs = eventdf.crs
    
    return df
    
def get_site(x):
    """parse filename to return site name"""
    basename = os.path.basename(x)
    site = basename.split("_")[0]
    return site

def get_date(x):
    """parse filename to return event name"""
    basename = os.path.basename(x)
    event = basename.split("_")[1:4]
    event = "_".join(event)
    
    return event

def compare_site(gdf):
    """Iterate over a dataframe and check rows"""
    results = []
    claimed_indices = []
    
    #Create spatial index
    spatial_index = gdf.sindex
    
    for index, row in gdf.iterrows():
        #skip is already claimed
        if index in claimed_indices:
            continue
            
        claimed_indices.append(index)
        geom = row["geometry"]
        
        #Look up matches
        possible_matches_index = list(spatial_index.intersection(geom.bounds))
        possible_matches = gdf.iloc[possible_matches_index]
        
        #Remove any matches that are claimed by another nest detection
        matches = possible_matches[~(possible_matches.index.isin(claimed_indices))]
        
        if matches.empty:
            continue
        
        #add to claimed
        claimed_indices.extend(matches.index.values)
        
        #add target info to match
        matches = matches.append(row)        
        matches["target_index"] = index
        matches = matches.rename(columns={"xmin":"matched_xmin","max":"matched_xmax","ymin":"matched_ymin","ymax":"matched_ymax"})

        results.append(matches)
    
    if len(results) == 0:
        return None
        
    results = pd.concat(results)
    
    return results
        
def check_overlap(geom, gdf):
    """Find spatially overlapping rows between target and pool of geometries"""
    matches = gdf.intersects(geom)
    
    return matches
    
def detect_nests(dirname, savedir):
    """Given a set of shapefiles, track time series of overlaps and save a shapefile of deteced boxes"""
    
    df = load_files(dirname)
        
    grouped = df.groupby("Site")
    results = []
    for name, group in grouped:
        site_results = compare_site(group)
        if site_results is not None:
            site_results["Site"] = name
            results.append(site_results)
        
    result_shp = geopandas.GeoDataFrame(pd.concat(results, ignore_index=True))
    result_shp.crs = df.crs
    
    filename = "{}/nest_detections.shp".format(savedir)
    result_shp.to_file(filename)
        
    return filename

def find_rgb_path(paths, site, date):
    paths = [x for x in paths if site in x]
    paths = [x for x in paths if date in x]
    
    if not len(paths) == 1:
        raise ValueError("A single tile match is needed, found: {}".format(paths))
    
    return paths[0]

def crop(rgb_path, geom, extend_box=8):
    src = rasterio.open(rgb_path)
    left, bottom, right, top = geom.bounds
    window = from_bounds(left - extend_box,
                             bottom - extend_box,
                             right + extend_box,
                             top + extend_box,
                             transform=src.transform)
    
    img = src.read(window=window)
    return img
    
def crop_images(df, rgb_pool):
    """Crop images for a series of data"""
    crops = {}
    for index, row in df.iterrows():
        #find rgb data
        rgb_path = find_rgb_path(rgb_pool, row["Site"],row["Date"])
        datename = "{}_{}_{}".format(index,row["Site"],row["Date"])
        crops[datename] = crop(rgb_path, row["geometry"])
    
    return crops

def extract_nests(filename, rgb_pool, savedir):
    gdf = geopandas.read_file(filename)
    grouped = gdf.groupby("target_ind")
    for name, group in grouped:
        #atleast three detections
        if group.shape[0] < 3:
            continue
        
        #Crop with date names as key
        crops = crop_images(group, rgb_pool=rgb_pool)
        
        #save output
        dirname =  "{}/{}".format(savedir, name) 
        if not os.path.exists(dirname):
            os.mkdir(dirname)
            
        for datename in crops:
            filename = "{}/{}.png".format(dirname, datename)
            crop = crops[datename]
            cv2.imsave(crop, filename)

def find_files():
    paths = glob.glob("/orange/ewhite/everglades/WadingBirds2020/**/*.tif",recursive=True)
    sites = ["Joule","CypressCity","Vacation","JetPort","Jerrod","StartMel","OtherColonies","6th Bridge"]
    paths = [x for x in paths if any(w in x for w in sites)]
    paths = [x for x in paths if not "projected" in x]
    
    return paths

if __name__=="__main__":
    nest_shp = detect_nests("/orange/ewhite/everglades/predictions/", savedir="../App/Zooniverse/data/")
    #Write nests into folders of clips
    rgb_pool = find_files()
    extract_nests(nest_shp, rgb_pool=rgb_pool, savedir="/orange/ewhite/everglades/nest_crops/")
