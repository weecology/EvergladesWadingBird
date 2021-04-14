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
import extract

def download_data(everglades_watch, min_version, generate=False):
    #see https://panoptes-python-client.readthedocs.io/en/v1.1/panoptes_client.html#module-panoptes_client.classification
    classification_export = everglades_watch.get_export('classifications', generate=generate)
    rows = []
    for row in classification_export.csv_dictreader():
        rows.append(row)    
    
    df = pd.DataFrame(rows)
    df["workflow_version"] = df.workflow_version.astype(float)
    df  = df[df.workflow_version > min_version]  
    df  = df[df.workflow_name =="Counts and Behavior"]     
    
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

def load_classifications(classifications_file, min_version):
    """Load classifications from Zooniverse
    classifications_file: path to .csv
    """
    df = pd.read_csv(classifications_file)
    df  = df[df.workflow_version > min_version]  
    df  = df[df.workflow_name =="Counts and Behavior"]          
    return df
    
def parse_additional_response(x):
    annotation_dict = json.loads(x)[0]
    response = annotation_dict["value"]
    return response

def parse_front_screen(x):
    #Extract and parse json
    annotation_dict = json.loads(x)[0]
    boxes = annotation_dict["value"]
    
    if len(boxes) == 0:
        return pd.DataFrame({"species":[None],"x":[None],"y":[None],"additional_observations":[None]})
    
    boxes = pd.DataFrame(boxes)
    boxes = boxes.rename(columns = {"tool_label": "label"})
            
    #Loop through each box and create a dataframe    
    box_df = pd.DataFrame()
    for index, box in boxes.iterrows():
        box_df = box_df.append(box,ignore_index=True)
    
    #Split label into Species and Behavior
    new_columns = box_df.label.str.split("-",n=1,expand=True)
    box_df["species"] = new_columns[0]
    box_df["behavior"] = new_columns[1]
    
    return box_df[["label","species","behavior","x","y"]]

def parse_uncommon_labels(x):
    boxes = pd.DataFrame(x)
    
    #This needs to be done carefully, as Zooniverse only returns the ordinal sublabel position
    sublabels= {0:"Flying",1:"Courting",2:"Roosting/Nesting",3:"Unknown"}
    
    #Loop through each box and create a dataframe    
    box_df = pd.DataFrame()
    for index, box in boxes.iterrows():
        #we used to allow multiples
        value = box.details[0]["value"]
        if type(value) is list:
            value = value[0]
        
        #If unknown class assign it to species, else its a behavior
        if box.tool_label == "Other":
            box["WriteInSpecies"] = value
            box["behavior"] = None
        else:
            box["behavior"] = sublabels[value]
        box_df = box_df.append(box,ignore_index=True)
    
    box_df = box_df.rename(columns = {"tool_label": "species"})
    box_df = box_df[["species","behavior","x","y"]]
    
    return box_df

def parse_additional_observations(x):
    """Parse the optional second screen of less common labels"""
    uncommon_annotation_dict = json.loads(x)[2]
    
    results = [ ]
    
    if len(uncommon_annotation_dict["value"]) > 0:
        results.append(parse_uncommon_labels(uncommon_annotation_dict["value"]))
        #combine results into a single dataframe
        results = pd.concat(results)
        return results
    else:  
        return None
    
def parse_annotations(x):
    #Parse each piece of the workflow
    front_screen = parse_front_screen(x)
    response = parse_additional_response(x)
    #TODO parse response and add to species class
    if response:
        front_screen["additional_observations"] = None
    else:
        front_screen["additional_observations"] = None
    
    if response == 'Yes':
        additional_screen = parse_additional_observations(x)
        if additional_screen is None:
            #Sometime a user selects yes, but there is no data - they were just curious
            return pd.concat([front_screen, additional_screen])
        else:
            return front_screen 
    else:
        return front_screen

def parse_subject_data(x):
    """Parse image metadata"""
    annotation_dict = json.loads(x)
    assert len(annotation_dict.keys()) == 1
    
    for key in annotation_dict:
        data = annotation_dict[key]
        try:
            utm_left, utm_bottom, utm_right, utm_top = data["bounds"]
        except:
            return None
        subject_reference = data["subject_reference"]
        resolution = data["resolution"][0]
            
        try:
            site_data = os.path.splitext(os.path.basename(data["site"]))[0]
            site = site_data.split("_", maxsplit=1)[0]
            event = site_data.split("_", maxsplit=1)[1]
        
        except:
            site = np.nan
            event = np.nan
            
        bounds = pd.DataFrame({"subject_ids":[key],"image_utm_left": [utm_left], "image_utm_bottom":[utm_bottom],"image_utm_right":[utm_right],"image_utm_top":[utm_top],"site":site,"event":event,"resolution":[resolution],"subject_reference":[subject_reference]})
    
    return bounds

def parse_birds(df):
    #remove empty annotations
    results = [ ]
    for index, row in df.iterrows(): 
        #Extract annotations for each image
        annotations = parse_annotations(row.annotations)  
        
        #Extract subject data
        bounds = parse_subject_data(row.subject_data)
        
        if bounds is None:
            print("Row {} had no spatial bounds".format(row["subject_data"]))
            continue
        
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

def project_box(df):
    """Convert points into utm coordinates"""
    df["box_utm_left"] = df.image_utm_left + (df.resolution * df.x)
    df["box_utm_bottom"] = df.image_utm_top - (df.resolution * df.y)
    df["box_utm_right"] = df.image_utm_left + (df.resolution * (df.x + df.width))
    df["box_utm_top"] = df.image_utm_top - (df.resolution * (df.y + df.height))
    
    #Create geopandas
    geoms = [box(left, bottom, right, top) for left, bottom, right, top in zip(df.box_utm_left, df.box_utm_bottom, df.box_utm_right, df.box_utm_top)]
    gdf = gpd.GeoDataFrame(df, geometry=geoms)
    
    #set CRS
    gdf.crs = 'epsg:32617'
    
    return gdf
    
def project_point(df):
    """Convert points into utm coordinates"""
    df["utm_x"] = df.image_utm_left + (df.resolution * df.x)
    df["utm_y"] = df.image_utm_top - (df.resolution * df.y)

    #Create geopandas
    geoms = [Point(x,y) for x,y in zip(df.utm_x, df.utm_y)]
    gdf = gpd.GeoDataFrame(df, geometry=geoms)
    
    #set CRS, this is a bit complicated as we originally started uploading in epsg 32617 (UTM) and changed for mapbox to 3857 web mercator. We can infer from first digit, but its not ideal.
    utm17 = gdf[gdf.utm_x.astype('str').str.startswith("5")]
    web_mercator = gdf[gdf.utm_x.astype('str').str.startswith("-8")]
    web_mercator.crs = 'epsg:3857'
    reprojected_utm_points = web_mercator.to_crs(epsg=32617)
    reprojected_utm_points["utm_x"] = reprojected_utm_points.geometry.apply(lambda x: x.coords[0][0])
    reprojected_utm_points["utm_y"] = reprojected_utm_points.geometry.apply(lambda x: x.coords[0][1])
    gdf = pd.concat([utm17,reprojected_utm_points], ignore_index=True)
    
    
    gdf.crs = 'epsg:32617'
    
    return gdf

def spatial_join(gdf, IoU_threshold = 0.2, buffer_size=1):
    """Find overlapping predictions in a geodataframe
    IoU_threshold: float threshold [0-1] for degree of overlap to merge annotations and vote on class
    buffer_size: in the units of the gdf, meters if projected, pixels if not.
    """    
    #Create spatial index
    spatial_index = gdf.sindex
    
    #Turn buffered points into boxes
    gdf["bbox"] = [box(left, bottom, right, top) for left, bottom, right, top in gdf.geometry.buffer(buffer_size).bounds.values]
    
    #for each overlapping image
    for name, group in gdf.groupby("subject_ids"):
        
        #Unique index for each image
        unique_index_value = 0
        
        if len(group.classification_id.unique()) == 1:
            gdf.loc[group.index.values,"selected_index"] = unique_index_value
        else:
            for index, row in group.iterrows():
                geom = row["bbox"]
                #Spatial clip to window using spatial index for faster querying
                possible_matches_index = list(spatial_index.intersection(geom.bounds))
                possible_matches = gdf.iloc[possible_matches_index]
                
                #If just matches itself, skip indexing
                if len(possible_matches) == 1:
                    gdf.loc[index, "selected_index"] = unique_index_value
                else:
                    boxes_to_merge = { }
                    labels = []
                    
                    #Add target box to consider
                    boxes_to_merge[index] = geom
                    labels.append(row["species"])
                    
                    #Find intersection over union
                    for match_index, match_row in possible_matches.iterrows():
                        match_geom = match_row["bbox"]
                        IoU = calculate_IoU(geom, match_geom)
                        if IoU > IoU_threshold:
                            boxes_to_merge[match_index] = match_geom
                            labels.append(match_row["species"])
                    
                    #Choose final box and labels
                    average_geom = create_average_box(boxes_to_merge,buffer_size=buffer_size)
                    for x in boxes_to_merge:
                        gdf.loc[x,"bbox"] = average_geom
                        gdf.loc[x,"selected_index"] = unique_index_value
                        gdf.loc[x,"species"] = vote_on_label(labels)
                unique_index_value+=1
            
    #remove duplicates
    gdf["geometry"] = gdf["bbox"]
    return gdf

def vote_on_label(labels):
    choosen_label = pd.Series(labels).mode()[0]
    
    return choosen_label

def create_average_box(boxes_to_merge, buffer_size):
    """Create a mean centered box based on input annotations"""
    centroid_x = np.mean([boxes_to_merge[x].centroid.x for x in boxes_to_merge])
    centroid_y = np.mean([boxes_to_merge[x].centroid.y for x in boxes_to_merge])
    point_geom = Point(centroid_x,centroid_y)
    left, bottom, right, top = point_geom.buffer(buffer_size).bounds
    geom = box(left, bottom, right, top)
    
    return geom
    
def calculate_IoU(geom, match):
    """Calculate intersection-over-union scores for a pair of boxes"""
    intersection = geom.intersection(match).area
    union = geom.union(match).area
    iou = intersection/float(union)
    
    return iou

def run(classifications_file=None, savedir=".", download=False, generate=False,min_version=300, debug=False):
    
    #Authenticate
    if download:
        everglades_watch = utils.connect()    
        df = download_data(everglades_watch, min_version, generate=generate)
        
        #add subject data to dir
        download_subject_data(everglades_watch, savedir=savedir)

    else:
        #Read file from zooniverse download
        df = load_classifications(classifications_file, min_version=min_version)        
    
    #if debug for testing, just sample 20 rows    
    if debug:
        df = df.sample(n=30)        
    
    #Parse JSON and filter
    #df = df[df.subject_ids == "58104676"]    
    df = parse_birds(df)
    
    #Write parsed data
    df.to_csv("{}/{}.csv".format(savedir, "parsed_annotations"),index=True)
    
    #Remove blank frames and spatial coordinates of bird points
    df = df[df.species.notna()]
    

    #save an unprojected copy
    geoms = [Point(x,y) for x,y in zip(df.x, df.y)]
    unprojected_data_gdf = gpd.GeoDataFrame(df, geometry=geoms)
    unprojected_data_gdf = spatial_join(unprojected_data_gdf, buffer_size=100)    
    fname = "{}/{}.shp".format(savedir, "everglades-watch-classifications_unprojected")
    unprojected_data_gdf=unprojected_data_gdf.drop(columns=["bbox"])    
    unprojected_data_gdf.to_file(fname)    
    
    projected_data = df[~(df.image_utm_left == 0)]
    projected_data_gdf = project_point(projected_data)
    
    #Find overlapping annotations and select annotations. Vote on best class for final box
    projected_data_gdf = spatial_join(projected_data_gdf, buffer_size=1)
    
    #write shapefile
    projected_data_gdf=projected_data_gdf.drop(columns=["bbox"])
    
    #Connect to index
    fname = "{}/{}.shp".format(savedir, "everglades-watch-classifications")
    projected_data_gdf.to_file(fname)

    return fname

if __name__ == "__main__":
    #Download from Zooniverse and parse
    
    fname = run(savedir="../App/Zooniverse/data/", download=True, 
       generate=False, min_version=300)