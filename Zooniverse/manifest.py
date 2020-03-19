#Zooniverse upload module
import glob
import os
import pandas as pd
from panoptes_client import Panoptes, Project, SubjectSet, Subject
import tile_raster
import rasterio
from PIL import Image

#Detect new files since last run
def find_files(path):
    images = {}
    image_paths = glob.glob(os.path.join(path, "*.tif"))
    counter = 1
    for i in image_paths:
        #Load and get metadata
        d = rasterio.open(i)
        left,bottom, right, top = d.bounds 
        
        #Write as a png
        basename = os.path.splitext(i)[0]
        png_name = "{}.png".format(basename)
        img = Image.open(i)        
        img.save(png_name)
        
        #Create dict
        images[png_name] = {"subject_reference":counter, "bounds":[left,bottom,right,top],"crs":d.crs.to_epsg()}
        counter +=1
    
    return images
    
def connect():
    #TODO hash this password.    
    Panoptes.connect(username='bw4sz', password='D!2utNBno8;b')
    everglades_watch = Project.find(10951)
    return everglades_watch

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

def main(path, everglades_watch, save_dir="/orange/ewhite/everglades/Zooniverse/"):
    """Args:
        path: a .tif to run
    """
    
    #Create new directory in save_dir
    basename = os.path.splitext(os.path.basename(path))[0]
    dirname = "{}/{}".format(save_dir,basename)
    
    try:
        os.mkdir(dirname)
    except:
        raise ValueError("dirname: {} exists)".format(dirname))
    
    #Crop tif
    saved_file = tile_raster.run(path=path, save_dir=dirname)
    print("Created cropped files at {}".format(saved_file))
    
    #Generate metadata
    images = find_files(saved_file)
    print("{} images ready for upload".format(len(images)))
    
    #Create a new subject set
    subject_set = create_subject_set(name=basename, everglades_watch=everglades_watch)
    
    #Upload
    upload(subject_set, images, everglades_watch)
    
    return saved_file

if __name__ == "__main__":
    #auth
    everglades_watch = connect()    
    
    #Which files have already been run
    uploaded = pd.read_csv("uploaded.csv")
    
    #Compare names of completed tiles
    uploaded["basename"] = uploaded.path.apply(lambda x: os.path.basename(x))
    
    #Files to process
    file_pool = glob.glob("/orange/ewhite/everglades/WadingBirds2020/**/*.tif",recursive=True)
    file_pool_basenames = [os.path.basename(x) for x in file_pool]
    paths = [file_pool[index] for index, x in enumerate(file_pool_basenames) if not x in uploaded.basename.values]
        
    print("Running files:{}".format(paths))
    for path in paths:
        #Run .tif
        saved_file = main(path, everglades_watch)
        
        #Confirm it exists and write to the csv file
        assert os.path.exists(saved_file)
        uploaded.path.append(saved_file)
    
    #Overwrite uploaded manifest
    uploaded.to_csv("uploaded.csv")