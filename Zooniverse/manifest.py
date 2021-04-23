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

        #Check if image is all white
        #white_flag = is_white(i)

        #if white_flag:
        #    continue

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
    model = deepforest.deepforest(weights=model)
    screened_images = {}
    for filename, metadata in images.items():
        boxes = model.predict_image(filename, return_plot=False)

        #small score filter
        boxes = boxes[boxes.score > 0.4]

        if not boxes.empty:
            screened_images[filename] = metadata
        else:
            print("Remove {}, screened empty".format(filename))

    #return keys for dict

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
    subject_set = create_subject_set(name=basename, everglades_watch=everglades_watch)

    #Upload
    upload(subject_set, screened_images, everglades_watch)

    return saved_file

if __name__ == "__main__":

    #auth
    everglades_watch = utils.connect()

    #set model
    model = "/orange/ewhite/everglades/Zooniverse/predictions/20201110_161912.h5"

    #Currently debugging with just one site
    paths = ["/orange/ewhite/everglades/WadingBirds2020/6thBridge/6thBridge_03_25_2020.tif"]

    for path in paths:
        print(path)
        saved_file = main(path, everglades_watch, model)

        ##Which files have already been run
        #uploaded = pd.read_csv("uploaded.csv")

        ##Compare names of completed tiles
        #uploaded["basename"] = uploaded.path.apply(lambda x: os.path.basename(x))

        ##Files to process
        #file_pool = glob.glob("/orange/ewhite/everglades/WadingBirds2020/**/*.tif",recursive=True)
        #file_pool_basenames = [os.path.basename(x) for x in file_pool]
        #paths = [file_pool[index] for index, x in enumerate(file_pool_basenames) if not x in uploaded.basename.values]

        #print("Running files:{}".format(paths))
        #for path in paths:
            ##Run .tif
            #try:
                #saved_file = main(path, everglades_watch, model)
                ##Confirm it exists and write to the csv file
                #assert os.path.exists(saved_file)
                #uploaded["path"] = uploaded.path.append(pd.Series({"path":saved_file}),ignore_index=True)
            #except Exception as e:
                #print("{} failed with exception {}".format(path, e))

        #Overwrite uploaded manifest
        #uploaded.to_csv("uploaded.csv",index=False)
