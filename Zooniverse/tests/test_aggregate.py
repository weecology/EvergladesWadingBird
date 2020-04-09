#Tests for data post-processing
import sys
import os
import pytest
import pandas as pd
sys.path.append(os.path.dirname(os.getcwd()))

import aggregate

min_version = 91.122

@pytest.fixture()
def csv_data():
    df = aggregate.load_classifications("data/species-classifications.csv",min_version)
    return df

def test_load_classifications():
    df = aggregate.load_classifications("data/species-classifications.csv",min_version)
    assert not df.empty

def test_parse_annotations(csv_data):
    annotations = aggregate.parse_annotations(csv_data.annotations.iloc[0])  
    assert annotations.shape == (6,8) 

def test_parse_subject_data(csv_data):
    subject_data = aggregate.parse_subject_data(csv_data.subject_data.iloc[40])
    assert subject_data.site.iloc[0] == "CypressCity_02282020_292"
    
def test_parse_file():
    df = aggregate.parse_file("data/species-classifications.csv",min_version)
    df.head()

def test_project():
    df = aggregate.parse_file("data/species-classifications.csv",min_version)
    project_df = aggregate.project(df)
    project_df.head()
    colnames= ["box_utm_left","box_utm_bottom","box_utm_right","box_utm_top"]
    assert all([x in project_df.columns for x in colnames])

def test_spatial_join():
    df = aggregate.parse_file("data/species-classifications.csv",min_version)
    project_df = aggregate.project(df)
    aggregate.spatial_join(project_df)