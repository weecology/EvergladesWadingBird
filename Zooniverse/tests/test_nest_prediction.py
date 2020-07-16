#test nest_detection
import os
import sys
sys.path.append(os.path.dirname(os.getcwd()))
import pytest
import nest_detection

def test_load_files():
    df = nest_detection.load_files("data/predictions/")
    assert not df.empty
    assert df.Site.unique() == ["Joule"]

def test_compare_site():
    df = nest_detection.load_files("data/predictions/")
    results = nest_detection.compare_site(df)
    
    assert not results.empty
    
def test_detect_nests():
    filename = nest_detection.detect_nests("data/predictions/",savedir="output/")
    
    assert os.path.exists(filename)
    
    
    