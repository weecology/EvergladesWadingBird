#Extract old zooniverse annotations. We had a test workflow on bounding boxes, let's salvage what we an
import pandas as pd
import paramiko
import os
import geopandas as gp
import everglade_tokens
import rasterio
import requests
import json
from shapely.geometry import box
from PIL import Image

#source keys outside of git control
import everglade_tokens

def hipergator_auth():
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    client.connect(everglade_tokens.get_ip(), username=everglade_tokens.get_username(),password=everglade_tokens.get_password())
    return client

def download_from_zooniverse(name, url):
    #check first if it exists
    if not os.path.exists(name):
        with open(name, 'wb') as handle:
            response = requests.get(url, stream=True)
        
            if not response.ok:
                print(response)
        
            for block in response.iter_content(1024):
                if not block:
                    break
        
                handle.write(block)

def extract_empty(parsed_data, image_data,save_dir="."):
    
    df = pd.read_csv(parsed_data)
    
    #get empty frames
    df = df[df.species.isna()]
    df["subject_id"] = df.subject_ids.astype(int)
        
    #Read in image location data
    image_df = pd.read_csv(image_data)
    image_df = image_df[["subject_id","locations"]]
    image_df = image_df.drop_duplicates()
    
    joined_df = df.merge(image_df,on="subject_id")    
    
    #buffer the points by 1m
    joined_df["url"] = joined_df.locations.apply(lambda x: json.loads(x)['0'])
    grouped_df = joined_df.groupby("url")
    
    #Split into image groups and download the image and write a shapefile
    group_data = [grouped_df.get_group(x) for x in grouped_df.groups]

    empty_paths = []
    for group in group_data:
        
        #Format for download
        download_url = group.url.unique()[0]
        
        #Download image
        basename = "{}".format(group.subject_id.unique()[0])
        name = "{}.png".format(os.path.join(os.path.abspath(save_dir),basename))
        download_from_zooniverse(name=name, url=download_url)   
        
        #confirm file can be opened 
        try:
            a = rasterio.open(name)
            b = Image.open(name).convert('RGB')
        except Exception as e:
            print("{} failed with {}".format(name, e))
            continue
        
        empty_paths.append(name)
        
    #Write dict in retinanet format
    empty_frame_df = pd.DataFrame({"image_path":empty_paths})
    csv_name = "{}.csv".format(os.path.join(save_dir,"empty_frames"))
    empty_frame_df.to_csv(csv_name)
    
def run(classification_shp, image_data ,savedir="."):
    """
    classification_shp: path to a processed .shp, see aggregate.py
    image_data: subject id download from zooniverse everglades-watch-subjects.csv
    """
    #Read in species data
    df = gp.read_file(classification_shp)
    df = df[["subject_id","x","y","species","behavior","geometry","selected_i"]]
    df.subject_id = df.subject_id.astype(int)
    
    #Read in image location data
    image_df = pd.read_csv(image_data)
    image_df = image_df[["subject_id","locations"]]
    
    #drop duplicates
    image_df = image_df.drop_duplicates()
    df.subject_id = df.subject_id.astype("int")
    joined_df = df.merge(image_df,on="subject_id")
    
    #assert single matches
    assert joined_df.shape[0] == df.shape[0]
    
    #buffer the points by 1m
    joined_df["url"] = joined_df.locations.apply(lambda x: json.loads(x)['0'])
    grouped_df = joined_df.groupby("url")
    
    #Split into image groups and download the image and write a shapefile
    group_data = [grouped_df.get_group(x) for x in grouped_df.groups]
    
    for group in group_data:
        
        #Format for download
        download_url = group.url.unique()[0]
        
        #Download image
        basename = "{}".format(group.subject_id.unique()[0])
        name = "{}.png".format(os.path.join(savedir,basename))
        download_from_zooniverse(name=name, url=download_url)
        
        #Confirm file can be opened
        try:
            a = rasterio.open(name)
            b = Image.open(name).convert('RGB')
        except Exception as e:
            print("{} failed with {}".format(name, e))
            continue
        
        group["geometry"] = [box(left, bottom, right, top) for left, bottom, right, top in group.geometry.buffer(1).bounds.values]
        
        #Create a shapefile
        shpname = "{}.shp".format(os.path.join(savedir,basename))
        group.to_file(shpname)
        
if __name__=="__main__":
    #Download images
    run(
        classification_shp="/home/b.weinstein/EvergladesWadingBird/App/Zooniverse/data/everglades-watch-classifications.shp",
        image_data="/home/b.weinstein/EvergladesWadingBird/App/Zooniverse/data/everglades-watch-subjects.csv",
        savedir="/orange/ewhite/everglades/Zooniverse/parsed_images/"
    ) 
    
    #Optionally download and format empty frames
    extract_empty(
        parsed_data="/home/b.weinstein/EvergladesWadingBird/App/Zooniverse/data/parsed_annotations.csv",
        image_data="/home/b.weinstein/EvergladesWadingBird/App/Zooniverse/data/everglades-watch-subjects.csv",
        save_dir= "/orange/ewhite/everglades/Zooniverse/parsed_images/"
    )
        