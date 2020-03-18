#Zooniverse upload module
import glob
import pandas as pd
from panoptes_client import Panoptes, Project, SubjectSet, Subject
import tile_raster

#Detect new files since last run
def find_files(path):
    images = {}
    image_paths = glob.glob(path + "*.png")
    counter = 1
    for i in image_paths:
        images[i] = {"subject_reference":counter}
        counter +=1
        
#TODO hash this password.
def connect():
    Panoptes.connect(username='bw4sz', password='D!2utNBno8;b')

#Create manifests
def create_subject_set(name="demo"):
    subject_set = SubjectSet()
    subject_set.links.project = "Everglades Watch"
    subject_set.display_name = name
    subject_set.save()    

def upload(subject_set, images):
    """Assign images to projecti"""
    new_subjects = []
    
    print("Uploading {} images".format(len(images)))
    for filename, metadata in images.items():
        subject = Subject()
    
        subject.links.project = tutorial_project
        subject.add_location(filename)
    
        subject.metadata.update(metadata)
        
        #Trigger upload
        subject.save()
        new_subjects.append(subject)    
    subject_set.add(new_subjects)

def main(path):
    """paths: a list of paths to run"""
    saved_file = tile_raster.run(path, save_dir)
    images = find_files(saved_file)
    subject_set = create_subject_set()
    upload(subject_set, images)
    return saved_file

if __name__ == "__main__":
    #auth
    connect()    
    
    #Which files have already been run
    uploaded = pd.read_csv("uploaded.csv")
    
    #Compare names of completed tiles
    uploaded["basename"] = uploaded.path.apply(lambda x: os.path.basename(x))
    file_pool = glob.glob("/orange/ewhite/everglades/WadingBirds2020/**/*.tif",recursive=T)
    file_pool = [os.path.basename(x) for x in file_pool]
    paths = [x for x in file_pool if not x in uploaded.basename.values]
    
    for path in paths:
        #Run .tif
        saved_file=main(path)
        
        #Confirm it exists and write to the csv file
        assert os.path.exists(saved_file)
        uploaded.path.append(saved_file)
    
    #Overwrite uploaded manifest
    uploaded.to_csv("uploaded.csv")