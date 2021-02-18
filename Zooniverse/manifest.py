#Zooniverse upload module
import glob
import os
import pandas as pd
from panoptes_client import Panoptes, Project, SubjectSet, Subject
import rasterio
from rasterio.warp import calculate_default_transform, reproject, Resampling
from PIL import Image
import numpy as np

from deepforest import deepforest
from deepforest import utilities

import tile_raster
import utils

def utm_project(path):

    #Everglades UTM Zone
    dst_crs = 'EPSG:32617'

    with rasterio.open(path) as src:
        transform, width, height = calculate_default_transform(
            src.crs, dst_crs, src.width, src.height, *src.bounds)
        kwargs = src.meta.copy()
        kwargs.update({
            'crs': dst_crs,
            'transform': transform,
            'width': width,
            'height': height
        })

        dest_name = "{}_projected.tif".format(os.path.splitext(path)[0])

        with rasterio.open(dest_name, 'w', **kwargs) as dst:
            for i in range(1, src.count + 1):
                reproject(
                    source=rasterio.band(src, i),
                    destination=rasterio.band(dst, i),
                    src_transform=src.transform,
                    src_crs=src.crs,
                    dst_transform=transform,
                    dst_crs=dst_crs,
                    resampling=Resampling.nearest)

    return dest_name

def is_white(path):
    d = rasterio.open(path)
    numpy_image = d.read()
    left, bottom, right, top = d.bounds

    assert numpy_image.shape[0] == 3

    #Check if image is all white
    img_reshaped = numpy_image.reshape(-1, 3)
    white = np.sum(img_reshaped == [255,255,255])/img_reshaped.size

    if white > 0.55:
        return True
    else:
        return False

def find_files(path):
    """Search and filter images"""
    images = {}
    image_paths = glob.glob(os.path.join(path, "*.tif"))
    counter = 1

    #extract site name
    site_name = os.path.basename(path)

    for i in image_paths:
        #Load and get metadata
        d = rasterio.open(i)
        numpy_image = d.read()
        left, bottom, right, top = d.bounds

        #Write as a png
        basename = os.path.splitext(i)[0]
        png_name = "{}.png".format(basename)
        img = Image.open(i)
        img.save(png_name)

        #Create dict
        images[png_name] = {"subject_reference":counter, "bounds":[left,bottom,right,top],"crs":d.crs.to_epsg(),"site":site_name,"resolution":d.res,"filename":png_name}
        counter +=1

    return images

#Create manifests
def create_subject_set(everglades_watch, name="demo"):
    subject_set = SubjectSet()
    subject_set.links.project = everglades_watch
    subject_set.display_name = name
    subject_set.save()

    return subject_set

def upload(subject_set, images, everglades_watch):
    """Assign images to projecti"""
    new_subjects = []

    print("Uploading {} images".format(len(images)))
    for filename, metadata in images.items():
        subject = Subject()

        subject.links.project = everglades_watch
        subject.add_location(filename)

        subject.metadata.update(metadata)

        #Trigger upload
        subject.save()
        new_subjects.append(subject)
    subject_set.add(new_subjects)

def screen_blanks(images, model):
    #Load bird detection model
    model = deepforest.deepforest(saved_model=model)
    model.classes_file = utilities.create_classes("/orange/ewhite/everglades/Zooniverse/parsed_images/test.csv")    
    model.read_classes()
    screened_images = {}
    for filename, metadata in images.items():
        boxes = model.predict_image(filename, return_plot=False)

        #small score filter
        boxes = boxes[boxes.score > 0.3]
        
        if not boxes.empty:
            if any([x in boxes.label.unique() for x in ["Great Blue Heron","Snowy Egret","Wood Stork","Roseate Spoonbill"]]):
                screened_images[filename] = metadata
        else:
            print("Remove {}, screened empty".format(filename))

    return screened_images

def main(path, everglades_watch, model=None, save_dir="/orange/ewhite/everglades/Zooniverse/"):
    """Args:
        path: a .tif to run
    """
    #Create new directory in save_dir
    basename = os.path.splitext(os.path.basename(path))[0]
    dirname = "{}/{}".format(save_dir,basename)

    try:
        os.mkdir(dirname)
    except:
        pass
        #raise ValueError("dirname: {} exists)".format(dirname))

    #Crop tif
    #Project from longlat to utm
    #check if exists
    projected_raster_path = "{}_projected.tif".format(os.path.splitext(path)[0])
    if not os.path.exists(projected_raster_path):
        projected_raster_path = utm_project(path)

    saved_file = tile_raster.run(path=projected_raster_path, save_dir=dirname,)
    print("Created cropped files at {}".format(saved_file))

    #Generate metadata
    images = find_files(saved_file)

    #Screen for blanks
    if model:
        screened_images = screen_blanks(images, model)
        print("{} images ready for upload".format(len(screened_images)))
    else:
        screened_images = images
    
    #Create a new subject set
    subject_set = create_subject_set(name="{}_rare_classes".format(basename), everglades_watch=everglades_watch)

    #Upload
    upload(subject_set, screened_images[0:5], everglades_watch)

    return saved_file

if __name__ == "__main__":

    #auth
    everglades_watch = utils.connect()
    
    model = "/orange/ewhite/everglades/Zooniverse/predictions/20210212_191155/species_model.h5"

    #Currently debugging with just one site
    paths = ["/orange/ewhite/everglades/WadingBirds2020/AlleyNorth/AlleyNorth_02132020-0-6.tif"]

    for path in paths:
        print(path)
        saved_file = main(path, everglades_watch, model)