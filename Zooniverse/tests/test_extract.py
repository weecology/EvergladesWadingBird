#test extract bounding classification for DeepForest
import os
import sys
sys.path.append(os.path.dirname(os.getcwd()))

from .. import extract_old

def test_run():
    extract_old.run(image_data="data/everglades-watch-subjects.csv",  classification_shp="output/old_workflow.shp")
