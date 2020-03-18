import pytest
import os
from .. import tile_raster

def test_run():
    tile_raster.run(path="data/SOAP_046.tif",save_dir="output/",patch_size=200)
    assert os.path.exists("output/SOAP_046_1.tif")
