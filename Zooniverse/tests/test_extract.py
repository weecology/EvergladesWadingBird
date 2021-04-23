#test extract bounding classification for DeepForest
import os
import sys
sys.path.append(os.path.dirname(os.getcwd()))
import pytest
from .. import extract
from .. import aggregate

@pytest.fixture()
def run_aggregate():
    aggregate.run("data/everglades-watch-classifications.csv", min_version=272.359, download=False, generate=False, savedir="output",debug=True)
    
def test_run(run_aggregate, tmpdir):
    #create an output image folder is needed
    if not os.path.exists("output/images/"):
        os.mkdir("output/images/")
    extract.run(image_data="data/everglades-watch-subjects.csv",  classification_shp="output/everglades-watch-classifications.shp",savedir=tmpdir)

def test_extract_empty(run_aggregate, tmpdir):   
    extract.extract_empty("output/parsed_annotations.csv", image_data="data/everglades-watch-subjects.csv", save_dir=tmpdir)