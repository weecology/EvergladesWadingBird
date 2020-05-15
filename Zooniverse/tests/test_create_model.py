#test deepforest development
from .. import create_model
import pytest
import rasterio

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
    
def test_format_shapefiles(shp_dir):
    results = create_model.format_shapefiles(shp_dir=shp_dir)
    assert all(results.columns == ["image_path","xmin","ymin","xmax","ymax","label"])
    assert results.xmin.dtype == int
    
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

def test_run(shp_dir):
    create_model.run(shp_dir, save_dir="output/")
    assert len(glob.glob("output/*.h5"))==1
    