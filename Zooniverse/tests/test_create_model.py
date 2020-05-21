#test deepforest development
import os
import sys
sys.path.append(os.path.dirname(os.getcwd()))

from .. import create_model
from .. import extract
from .. import aggregate

import pytest
import rasterio
import geopandas as gp

#Setup method
@pytest.fixture(scope="session", autouse=True)
def extract_images():
    #create an output image folder is needed
    if not os.path.exists("output/images/"):
        os.mkdir("output/images/")
    extract.run(image_data="data/everglades-watch-subjects.csv",  classification_shp="output/everglades-watch-classifications.shp",savedir="output/images/")

@pytest.fixture()
def shp_dir():
    return "output/images"

@pytest.fixture()
def annotations(shp_dir):
    annotations = create_model.format_shapefiles(shp_dir=shp_dir)    
    return annotations

def test_shapefile_to_annotations():
    rgb_path="output/images/43845552.png"
    df = create_model.shapefile_to_annotations(shapefile="output/images/43845552.shp", rgb_path=rgb_path)
    assert all(df.columns == ["image_path","xmin","ymin","xmax","ymax","label"])
    
    #assert that the coordinates are in the image system
    with rasterio.open(rgb_path) as src:
        height, width = src.shape
        
    assert (df.iloc[0].xmin >= 0) & (df.iloc[0].xmax <= width)
    assert (df.iloc[0].ymin >= 0) & (df.iloc[0].ymax <= height)
    
    #Assert total number of records
    gdf = gp.read_file("output/images/43845552.shp")
    assert gdf.shape[0] == df.shape[0]
    
    #Assert no duplicates
    gdf_dropped_duplicates = gdf.drop_duplicates()
    assert gdf_dropped_duplicates.shape[0] == gdf.shape[0]    
    
def test_format_shapefiles(extract_images, shp_dir):
    results = create_model.format_shapefiles(shp_dir=shp_dir)
    assert all(results.columns == ["image_path","xmin","ymin","xmax","ymax","label"])
    assert results.xmin.dtype == int
    
    #Assert no duplicates
    results_dropped_duplicates = results.drop_duplicates()
    assert results_dropped_duplicates.shape[0] == results.shape[0]
    
def test_split_test_train(annotations):
    
    train, test = create_model.split_test_train(annotations)
    
    #Assert no overlapping cases and known deepforest format
    assert not test.empty
    assert not train.empty
    assert all(train.columns == ["image_path","xmin","ymin","xmax","ymax","label"])
    assert all(test.columns == ["image_path","xmin","ymin","xmax","ymax","label"])
    assert all(test.label == "Bird")
    assert all(train.label == "Bird")
    assert test[test.image_path.isin(train.image_path.unique())].empty
    
    #Assert that data is same total sum
    assert annotations.shape[0] == (test.shape[0] + train.shape[0])
    
    #Assert no duplicates
    train_dropped_duplicates = train.drop_duplicates()
    assert train_dropped_duplicates.shape[0] == train.shape[0]    