#test extract bounding classification for DeepForest
import os
import sys
sys.path.append(os.path.dirname(os.getcwd()))

from .. import extract

def test_run():
    extract.run(image_data="data/everglades-watch-subjects.csv",  classification_shp="output/everglades-watch-classifications.shp",savedir="output/images/")