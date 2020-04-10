#Tests for data post-processing
import sys
import os
import pytest
import pandas as pd
sys.path.append(os.path.dirname(os.getcwd()))

import aggregate
import utils
min_version = 91.122

@pytest.fixture()
def csv_data():
    df = aggregate.load_classifications("data/species-classifications.csv")
    df  = df[df.workflow_version > min_version]  
    df = df[~(df.annotations == '[{"task":"T0","task_label":"Species","value":[]}]')]        
    return df

def test_load_classifications():
    df = aggregate.load_classifications("data/species-classifications.csv")
    assert not df.empty

def test_parse_annotations(csv_data):  
    annotations = aggregate.parse_annotations(csv_data.annotations.iloc[0])  
    assert annotations.shape == (6,8) 

def test_parse_subject_data(csv_data):
    subject_data = aggregate.parse_subject_data(csv_data.subject_data.iloc[40])
    assert subject_data.site.iloc[0] == "CypressCity"
    assert  subject_data.event.iloc[0]  == "02282020_292"
    
def test_parse_file(csv_data):
    df = aggregate.parse_file(csv_data,min_version)
    assert not df.empty

def test_project():
    df = aggregate.load_classifications("data/species-classifications.csv")
    df = aggregate.parse_file(df, min_version)
    project_df = aggregate.project(df)
    project_df.head()
    colnames= ["box_utm_left","box_utm_bottom","box_utm_right","box_utm_top"]
    assert all([x in project_df.columns for x in colnames])

def test_spatial_join(csv_data):
    df = aggregate.parse_file(csv_data,min_version)
    project_df = aggregate.project(df)
    gdf = aggregate.spatial_join(project_df)
    assert gdf["selected_index"].loc[0]

@pytest.mark.parametrize("download", [True, False])
def test_run(download):
    aggregate.run("data/species-classifications.csv",min_version, download=download, savedir="output")
    assert os.path.exists("output/species-classifications.shp")

@pytest.mark.parametrize("generate", [True, False])
def test_download_data(generate):
    everglades_watch = utils.connect()
    df = aggregate.download_data(everglades_watch, generate=generate)
    assert not df.empty