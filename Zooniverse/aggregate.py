#aggregation script
import pandas as pd
import geopandas as gpd
from shapely.geometry import box
import json
import numpy as np
import os

#TODO
def download_data():
    pass

def load_classifications(classifications_file, version):
    """Load classifications from Zooniverse
    classifications_file: path to .csv
    version: minimum version workflow
    """
    df = pd.read_csv(classifications_file)
    df  = df[df.workflow_version > version]  
    
    df = df[~(df.annotations == '[{"task":"T0","task_label":"Species","value":[]}]')]
    
    return df

def parse_annotations(x):
    #Extract and parse json
    annotation_dict = json.loads(x)[0]
    boxes = annotation_dict["value"]
    boxes = pd.DataFrame(boxes)
    boxes.rename(columns = {"tool_label": "Species"})
    
    #Loop through each box and create a dataframe    
    box_df = pd.DataFrame()
    for index, box in boxes.iterrows():
        box_df = box_df.append(box,ignore_index=True)
        
    return box_df 

def parse_subject_data(x):
    """Parse image metadata"""
    annotation_dict = json.loads(x)
    assert len(annotation_dict.keys()) == 1
    
    for key in annotation_dict:
        data = annotation_dict[key]
        utm_left, utm_bottom, utm_right, utm_top = data["bounds"]
        
        try:
            resolution = data["resolution"]
        except:
            print("Resolution not known, assigning 1cm. THIS IS TEMPORARY!!!!")
            resolution = 0.01
            
        try:
            site = os.path.splitext(os.path.basename(data["site"]))[0]
        except:
            site = np.nan
        bounds = pd.DataFrame({"image_utm_left": [utm_left], "image_utm_bottom":[utm_bottom],"image_utm_right":[utm_right],"image_utm_top":[utm_right],"site":site,"resolution":[resolution]})
    
    return bounds

def parse_file(classifications_file, version):
    
    #Load Classifications
    df = load_classifications(classifications_file, version)
    
    #remove empty annotations
    results = [ ]
    for index, row in df.iterrows(): 
        #Extract annotations for each image
        annotations = parse_annotations(row.annotations)  
        
        #Extract subject data
        bounds = parse_subject_data(row.subject_data)
        
        #Assign columns
        annotations["classification_id"] = row["classification_id"]
        annotations["user_name"] = row["user_name"]
        annotations["created_at"] = row["created_at"]
        
        for col_name in bounds:
            annotations[col_name] = bounds[col_name].values[0]
            
        results.append(annotations)
    
    results = pd.concat(results)
        
    return results

def project(df):
    """Convert bounding boxes to utm coordinates"""
    df["box_utm_left"] = df.image_utm_left + (df.resolution * df.x)
    df["box_utm_bottom"] = df.image_utm_bottom + (df.resolution * df.y)
    df["box_utm_right"] = df.image_utm_left + (df.resolution * (df.x + df.width))
    df["box_utm_top"] = df.image_utm_bottom + (df.resolution * (df.y + df.height))
    
    #Create geopandas
    geoms = [box(left, bottom, right, top) for left, bottom, right, top in zip(df.box_utm_left, df.box_utm_bottom, df.box_utm_right, df.box_utm_top)]
    gdf = gpd.GeoDataFrame(df, geometry=geoms)
    
    return gdf
    
def spatial_join(gdf, IoU_threshold = 0.2):
    """Find overlapping predictions in a geodataframe
    IoU_threshold: float threshold [0-1] for degree of overlap to merge annotations and vote on class
    """    
    #Create spatial index
    spatial_index = gdf.sindex
    
    filtered_boxes = [ ]
    data = [ ]
    for index, row in gdf.iterrows():
        geom = row["geometry"]
        #Spatial clip to window using spatial index for faster querying
        possible_matches_index = list(spatial_index.intersection(geom.bounds))
        possible_matches = gdf.iloc[possible_matches_index]
        
        boxes_to_merge = []
        labels = [ ]
        
        #Add target box to consider
        boxes_to_merge.append(geom)
        labels.append(row["tool_label"])
        
        #Find intersection over union
        for match_index, match_row in possible_matches.iterrows():
            match_geom = match_row["geometry"]
            IoU = calculate_IoU(geom,match_geom)
            
            if IoU > IoU_threshold:
                boxes_to_merge.append(match_geom)
                labels.append(match_row["tool_label"])
        
        #Choose final box and labels
        selected_box = choose_box(boxes_to_merge)
        species_class = majority_vote(labels)
        filtered_boxes.append(selected_box)
        data.append({"label":species_class})
    
    filtered_df = gpd.GeoDataFrame(data, geometry=filtered_boxes)
    #remove duplicates
    filtered_df
    return filtered_boxes
        
def choose_box(boxes_to_merge):
    """Choose the smallest box of a set to mantain"""
    smaller_box_index = np.argmin([x.area for x in boxes_to_merge])
    smallest_box = boxes_to_merge[smaller_box_index]
    
    return smallest_box
    
def calculate_IoU(geom, match):
    """Calculate intersection-over-union scores for a pair of boxes"""
    intersection = geom.intersection(match).area
    union = geom.union(match).area
    iou = intersection/float(union)
    
    return iou

def majority_vote(labels):
    """Vote on classes of overlapping boxes
    TODO tie breaks?
    """
    return pd.Series(labels).value_counts().idxmax()    

def run(classifications_file, version, savedir="."):
    #Read file from zooniverse
    df = parse_file(classifications_file, version)
    
    #Get spatial coordinates
    gdf = project(df)
    
    #Find overlapping annotations and select annotations. Vote on best class for final box
    selected_annotations = reduce_annotations(gdf)
    
    basename = os.path.splitext(os.path.basename(classifications_file))[0]
    
    #write shapefile
    selected_annotations.to_file("{}/{}.shp".format(savedir,basename))
