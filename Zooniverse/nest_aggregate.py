#aggregation script
import pandas as pd
import geopandas as gpd
from panoptes_client import Panoptes
from shapely.geometry import box, Point
import json
import numpy as np
import os
from datetime import datetime
import utils

def species_from_label(value):
    label_dict = {}
    label_dict[0] = "Great Egret"
    label_dict[1] = "Snowy Egret"
    label_dict[2] = "White Ibis"
    label_dict[3] = "Great Blue Heron"
    label_dict[4] = "Wood Stork"
    label_dict[5] = "Roseate Spoonbill"
    label_dict[6] = "Anhinga"
    label_dict[7] = "Other"
    label_dict[8] = "Unknown"
    
    return label_dict[value]
    
def download_data(everglades_watch, min_version, generate=False):
    #see https://panoptes-python-client.readthedocs.io/en/v1.1/panoptes_client.html#module-panoptes_client.classification
    classification_export = everglades_watch.get_export('classifications', generate=generate)
    rows = []
    for row in classification_export.csv_dictreader():
        rows.append(row)    
    
    df = pd.DataFrame(rows)
    df  = df[df.workflow_name =="Nests"]     
    df["workflow_version"] = df.workflow_version.astype(float)
    df  = df[df.workflow_version > min_version]  
    
    return df

def download_subject_data(everglades_watch, savedir, generate=False):
    #see https://panoptes-python-client.readthedocs.io/en/v1.1/panoptes_client.html#module-panoptes_client.classification
    classification_export = everglades_watch.get_export('subjects', generate=generate)
    rows = []
    for row in classification_export.csv_dictreader():
        rows.append(row)    
    
    df = pd.DataFrame(rows)    
    fname = "{}/{}.csv".format(savedir,"everglades-watch-subjects")
    
    #Overwrite subject set
    df.to_csv(fname)
    
    return df

def load_classifications(classifications_file, min_version=195.257):
    """Load classifications from Zooniverse
    classifications_file: path to .csv
    """
    df = pd.read_csv(classifications_file)
    df  = df[df.workflow_version > min_version]  
    df  = df[df.workflow_name =="Nests"]          
    return df
    
def parse_additional_response(x):
    annotation_dict = json.loads(x)[0]
    response = annotation_dict["value"]
    return response

def parse_nest_location(x):
    """Parse nest location task"""
    #Extract and parse json
    annotation_dict = json.loads(x)[1]
    
    boxes = annotation_dict["value"]
    #For each frame get the nest location and species label 
    nest_locations = [x for x in boxes if x["tool_label"] == "Nest"]
    
    nest_x = [ ]
    nest_y = [ ]
    species = [ ]
    frame = [ ]
    for x in nest_locations:
        nest_x.append(x["x"])
        nest_y.append(x["y"])
        species.append(species_from_label(x["details"][0]["value"][0]))
        frame.append(x["frame"])
        
    annotations = pd.DataFrame({"frame":frame, "nest_x":nest_x, "nest_y":nest_y,"species":species})
    
    return annotations

def parse_question_task(x):
    """Gather task valid answers"""
    annotation_dict = json.loads(x)[0]
    if annotation_dict["task"] == "T1":
        response = annotation_dict["value"]
    else:
        response = None
    
    return response == 'Yes'
     

def parse_annotations(x):
    nest_status = parse_question_task(x)    
    if nest_status:
        annotations = parse_nest_location(x)
        annotations["valid_nest"] = nest_status
    else:
        annotations = pd.DataFrame({"frame":[None], "nest_x":[None], "nest_y":[None],"species":[None], "valid_nest":[False]})
               
    return annotations
     
def parse_subject_data(x):
    """Parse image metadata"""
    annotation_dict = json.loads(x)
    assert len(annotation_dict.keys()) == 1
    
    for key in annotation_dict:
        data = annotation_dict[key]
            
        try:
            site_data = os.path.splitext(os.path.basename(data["filename"]))[0]
            site = site_data.split("_", maxsplit=2)[1]
            nest_id = site_data.split("_", maxsplit=2)[0]            
            event = site_data.split("_", maxsplit=2)[2]
            event = event.replace("_projected","")
        
        except:
            site = np.nan
            event = np.nan
            
        bounds = pd.DataFrame({"subject_ids":[key], "nest_id":[nest_id],"site":site,"event":event})
    
    return bounds

def parse_birds(df):
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
    results = results.reset_index(drop=True)
    
    return results

#def project_box(df):
    #"""Convert points into utm coordinates"""
    #df["box_utm_left"] = df.image_utm_left + (df.resolution * df.x)
    #df["box_utm_bottom"] = df.image_utm_bottom + (df.resolution * df.y)
    #df["box_utm_right"] = df.image_utm_left + (df.resolution * (df.x + df.width))
    #df["box_utm_top"] = df.image_utm_bottom + (df.resolution * (df.y + df.height))
    
    ##Create geopandas
    #geoms = [box(left, bottom, right, top) for left, bottom, right, top in zip(df.box_utm_left, df.box_utm_bottom, df.box_utm_right, df.box_utm_top)]
    #gdf = gpd.GeoDataFrame(df, geometry=geoms)
    
    ##set CRS
    #gdf.crs = 'epsg:32617'
    
    #return gdf
    
#def project_point(df):
    #"""Convert points into utm coordinates"""
    #df["utm_x"] = df.image_utm_left + (df.resolution * df.x)
    #df["utm_y"] = df.image_utm_top - (df.resolution * df.y)

    ##Create geopandas
    #geoms = [Point(x,y) for x,y in zip(df.utm_x, df.utm_y)]
    #gdf = gpd.GeoDataFrame(df, geometry=geoms)
    
    ##set CRS, this is a bit complicated as we originally started uploading in epsg 32617 (UTM) and changed for mapbox to 3857 web mercator. We can infer from first digit, but its not ideal.
    #utm17 = gdf[gdf.utm_x.astype('str').str.startswith("5")]
    #web_mercator = gdf[gdf.utm_x.astype('str').str.startswith("-8")]
    #web_mercator.crs = 'epsg:3857'
    #reprojected_utm_points = web_mercator.to_crs(epsg=32617)
    #reprojected_utm_points["utm_x"] = reprojected_utm_points.geometry.apply(lambda x: x.coords[0][0])
    #reprojected_utm_points["utm_y"] = reprojected_utm_points.geometry.apply(lambda x: x.coords[0][1])
    #gdf = pd.concat([utm17,reprojected_utm_points], ignore_index=True)
    #gdf.crs = 'epsg:32617'
    
    #return gdf

#def spatial_join(gdf, IoU_threshold = 0.2):
    #"""Find overlapping predictions in a geodataframe
    #IoU_threshold: float threshold [0-1] for degree of overlap to merge annotations and vote on class
    #"""    
    ##Create spatial index
    #spatial_index = gdf.sindex
    
    ##Turn buffered points into boxes
    #gdf["bbox"] = [box(left, bottom, right, top) for left, bottom, right, top in gdf.geometry.buffer(1).bounds.values]
    
    ##for each overlapping image
    #for name, group in gdf.groupby("subject_ids"):
        #if len(group.classification_id.unique()) == 1:
            #group["selected_index"] = group.index.values
        #else:
            #for index, row in group.iterrows():
                #geom = row["bbox"]
                ##Spatial clip to window using spatial index for faster querying
                #possible_matches_index = list(spatial_index.intersection(geom.bounds))
                #possible_matches = gdf.iloc[possible_matches_index]
                
                ##If just matches itself, skip indexing
                #if len(possible_matches) == 1:
                    #gdf.loc[index, "selected_index"] = index
                #else:
                    #boxes_to_merge = { }
                    #labels = []
                    
                    ##Add target box to consider
                    #boxes_to_merge[index] = geom
                    #labels.append(row["species"])
                    
                    ##Find intersection over union
                    #for match_index, match_row in possible_matches.iterrows():
                        #match_geom = match_row["bbox"]
                        #IoU = calculate_IoU(geom, match_geom)
                        
                        #if IoU > IoU_threshold:
                            #boxes_to_merge[match_index] = match_geom
                            #labels.append(match_row["species"])
                    
                    ##Choose final box and labels
                    #selected_key = choose_box(boxes_to_merge)
                    #gdf.loc[index, "selected_index"] = selected_key
            
        ##remove duplicates
        #return gdf
        
#def choose_box(boxes_to_merge):
    #"""Choose the smallest box of a set to mantain"""
    #smallest_box_index = np.argmin([boxes_to_merge[x].area for x in boxes_to_merge])
    #key=list(boxes_to_merge.keys())[smallest_box_index]
    
    #return key
    
#def calculate_IoU(geom, match):
    #"""Calculate intersection-over-union scores for a pair of boxes"""
    #intersection = geom.intersection(match).area
    #union = geom.union(match).area
    #iou = intersection/float(union)
    
    #return iou

def run(classifications_file=None, savedir=".", download=False, generate=False,min_version=195.257, debug=False):
    
    #Authenticate
    if download:
        everglades_watch = utils.connect()    
        df = download_data(everglades_watch, min_version, generate=generate)
        
        #add subject data to dir
        download_subject_data(everglades_watch, savedir=savedir)

    else:
        #Read file from zooniverse download
        df = load_classifications(classifications_file, min_version=min_version)        
    
    #if debug for testing, just sample 50 rows    
    if debug:
        df = df.sample(n=50)        
    
    #Parse JSON and filter
    df = parse_birds(df)
    
    #Write parsed data
    df.to_csv("{}/{}.csv".format(savedir, "parsed_nest_annotations"),index=True)
    
    #Remove blank frames and spatial coordinates of bird points
    #df = df[df.species.notna()]
    
    #gdf = project_point(df)
    
    #Find overlapping annotations and select annotations. Vote on best class for final box
    #selected_annotations = spatial_join(gdf)
            
    #write shapefile
    #selected_annotations=selected_annotations.drop(columns=["bbox"])
    
    #Connect to index
    fname = "{}/{}.csv".format(savedir, "nest_aggregate")
    selected_annotations.to_csv(fname)
    
    return fname

if __name__ == "__main__":
    #Download from Zooniverse and parse
    
    fname = run(savedir="../App/Zooniverse/data/", download=True, 
       generate=False, min_version=195.257)