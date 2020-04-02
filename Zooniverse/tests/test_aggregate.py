#Tests for data post-processing
import sys
import os
import pandas as pd
sys.path.append(os.path.dirname(os.getcwd()))

import aggregate

min_version = 91.122

def test_load_classifications():
    df = aggregate.load_classifications("data/species-classifications.csv",min_version)
    assert not df.empty

def test_parse_annotations():
    df = aggregate.load_classifications("data/species-classifications.csv",min_version)
    annotations = aggregate.extract_bbox(df)
    annotations.head()

def test_parse_file():
    pass