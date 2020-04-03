#aggregation script
import pandas as pd
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
            site = os.path.splitext(os.path.basename(data["site"]))[0]
        except:
            site = np.nan
        bounds = pd.DataFrame({"utm_left": [utm_left], "utm_bottom":[utm_bottom],"utm_right":[utm_right],"utm_top":[utm_right],"site":site})
    
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
        
        #Ugly, but works.
        annotations["classification_id"] = row["classification_id"]
        annotations["user_name"] = row["user_name"]
        annotations["created_at"] = row["created_at"]
        for col_name in bounds:
            annotations[col_name] = bounds[col_name].values[0]
            
        results.append(annotations)
    
    results = pd.concat(results)
        
    return results
    
