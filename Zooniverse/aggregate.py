#aggregation script
import pandas as pd
import json

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
    return df

def parse_annotations(x):
    annotation_dict = json.loads(x)[0]
    boxes = annotation_dict["value"]
    boxes = pd.DataFrame(boxes)
    boxes.rename(columns = {"tool_label": "Species"})
    
    box_list = [ ]
    #Loop through each box and create a dataframe
    for index, box in boxes.iterrows():
        box_list.append(pd.DataFrame(box))
    
    #Combine rows 
    box_df = pd.concat(box_list)
    return box_df 

def parse_subject_data():
    example = '{"41752799":{"retired":null,"crs":4326,"site":"/orange/ewhite/everglades/Zooniverse//Vacation_03192020/Vacation_03192020_501","bounds":[-80.6292373808215,25.9139206378957,-80.62913053182149,25.9140172671957],"subject_reference":30}}'

def parse_file(classifications_file, version):
    
    #Load Classifications
    df = load_classifications(classifications_file, version)
    
    #remove empty annotations
    df = df[~(df.annotations == '[{"task":"T0","task_label":"Species","value":[]}]')]
    
    annotation_df = [ ]
    for index, row in df.iterrows(): 
        #Extract annotations for each image
        annotations = extract_bbox(df)  
        
        #Extract subject data
        parse_subject_data(row)
        
        #Merge the key columns
        row["classification_id","user_name","created_at"]
        
    
