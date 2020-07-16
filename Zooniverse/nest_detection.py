#Bird Bird Bird Detector
import glob
import geopandas
import rtree
import os
import pandas as pd

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

if __name__=="__main__":
    detect_nests("/orange/ewhite/everglades/predictions/20200714_184132/", savedir="/orange/ewhite/everglades/predictions/20200714_184132/")