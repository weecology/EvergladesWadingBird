#Bird Bird Bird Detector
import glob
import geopandas
import rtree
import rasterio
import os
import pandas as pd
import cv2
import numpy as np
from panoptes_client import Panoptes, Project, SubjectSet, Subject
import utils

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

def find_rgb_paths(site, paths):
    paths = [x for x in paths if site in x]
    
    return paths

def crop(rgb_path, geom, extend_box=3):
    src = rasterio.open(rgb_path)
    left, bottom, right, top = geom.bounds    
    window = from_bounds(left - extend_box,
                             bottom - extend_box,
                             right + extend_box,
                             top + extend_box,
                             transform=src.transform)
    
    numpy_array = src.read(window=window)
    numpy_array_rgb = np.rollaxis(numpy_array, 0,3)    
    numpy_array_bgr = numpy_array_rgb[:,:,::-1]    
    return numpy_array_bgr
    
def crop_images(df, rgb_images):
    """Crop images for a series of data"""
    crops = {}
    geom = df.geometry.iloc[0]
    target_ind = df.target_ind.unique()[0]
   
    for tile in rgb_images:
        #find rgb data
        basename = os.path.splitext(os.path.basename(tile))[0]
        datename = "{}_{}".format(target_ind, basename)
        crops[datename] = crop(tile, geom)
    
    return crops

def create_subject(filenames, everglades_watch):
    subject = Subject()

    subject.links.project = everglades_watch
    for filename in filenames:
        subject.add_location(filename)
        subject.metadata.update({"filename":filename})

    #Trigger upload
    subject.save()    
    
    return subject
    
def create_subject_set(everglades_watch, name="Nest detections"):
    subject_set = SubjectSet()
    subject_set.links.project = everglades_watch
    subject_set.display_name = name
    subject_set.save()

    return subject_set

def write_timestamp(image, text):
    text = text.replace("projected","")
    image = np.asarray(image)
    image = cv2.putText(image, text, (10,image.shape[1]), 1, 2, 2)
    return image
    
def extract_nests(filename, rgb_pool, savedir, upload=False):
    gdf = geopandas.read_file(filename)
    grouped = gdf.groupby("target_ind")
    if upload:
        everglades_watch = utils.connect()
        subject_set = create_subject_set(everglades_watch)
        subjects = []
    
    for name, group in grouped:
        #atleast three detections
        if group.shape[0] < 3:
            continue
        
        #Crop with date names as key
        site = group.Site.unique()[0]
        rgb_images = find_rgb_paths(site, rgb_pool)
        crops = crop_images(group, rgb_images=rgb_images)
        
        #save output
        dirname =  "{}/{}_{}".format(savedir,name,group["Site"].unique()[0])
        if not os.path.exists(dirname):
            os.mkdir(dirname)
        
        filenames = []
        for datename in crops:
            filename = "{}/{}.png".format(dirname, datename)
            crop = crops[datename]
            if not crop.shape[2] == 3:
                continue      
            
            #Write timestamp as watermark
            crop = write_timestamp(crop, datename)
            
            cv2.imwrite(filename, crop)
            filenames.append(filename)
            
        if upload:
            subject = create_subject(filenames, everglades_watch)
            subjects.append(subject)
            
    if upload:
        subject_set.add(subjects[0:2])
            
def find_files():
    paths = glob.glob("/orange/ewhite/everglades/utm_projected/*.tif")
    
    return paths

if __name__=="__main__":
    nest_shp = detect_nests("/orange/ewhite/everglades/predictions/", savedir="../App/Zooniverse/data/")
    #Write nests into folders of clips
    rgb_pool = find_files()
    extract_nests(nest_shp, rgb_pool=rgb_pool, savedir="/orange/ewhite/everglades/nest_crops/", upload=True)
