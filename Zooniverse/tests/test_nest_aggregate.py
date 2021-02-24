#Tests for data post-processing
import sys
import os
import pytest
import pandas as pd
sys.path.append(os.path.dirname(os.getcwd()))

import nest_aggregate
import utils
min_version = 195

@pytest.fixture()
def csv_data():
    df = nest_aggregate.load_classifications("data/everglades-watch-classifications.csv", min_version=min_version)
    return df

def test_load_classifications():
    df = nest_aggregate.load_classifications("data/everglades-watch-classifications.csv", min_version=min_version)
    assert not df.empty

def test_parse_question_task(csv_data):
    #Contains data
    response = nest_aggregate.parse_question_task(csv_data.loc[7971].annotations)  
    assert response == True
        
def test_parse_nest_location(csv_data):  
    annotations = nest_aggregate.parse_nest_location(csv_data.loc[7971].annotations)  
    assert annotations.shape == (2,4)
    
def test_parse_annotations(csv_data):  
    #No additional data
    annotations = nest_aggregate.parse_annotations(csv_data.loc[7971].annotations)  
    assert annotations.shape == (2,5) 

def test_parse_subject_data(csv_data):
    subject_data = nest_aggregate.parse_subject_data(csv_data.loc[7971].subject_data)
    assert subject_data.site.iloc[0] == "Vacation"
    assert  subject_data.event.iloc[0]  == "05_29_2020"
    
def test_parse_birds(csv_data):
    df = nest_aggregate.parse_birds(csv_data.loc[7971])
    assert not df.empty
    
    #assert size is mantained
    assert len(df.classification_id.unique()) == 100

#def test_project_point(csv_data):
    #df = nest_aggregate.parse_birds(csv_data.loc[7971])
    #df = df[df.species.notna()]
    #project_df = nest_aggregate.project_point(df)
    #colnames= ["utm_x","utm_y"]
    #assert all([x in project_df.columns for x in colnames])

#def test_spatial_join(csv_data):
    #debug_data = csv_data.iloc[0:100]
    #df = nest_aggregate.parse_birds(debug_data)
    #project_df = nest_aggregate.project_point(df)
    #project_df = project_df[df.species.notna()] 
    #gdf = nest_aggregate.spatial_join(project_df)
    #assert gdf["selected_index"].iloc[0]
    
    ##assert the shape size is mantained
    #print("{} non-empty frames".format(len(gdf.classification_id.unique())))
    #assert len(gdf.classification_id.unique()) < debug_data.shape[0]

@pytest.mark.parametrize("download", [True, False])
def test_run(download):
    nest_aggregate.run("data/everglades-watch-classifications.csv", min_version=min_version, download=download, generate=False, savedir="output",debug=False)
    assert os.path.exists("output/everglades-watch-classifications.shp")
    assert os.path.exists("output/parsed_annotations.csv")
    
    df = pd.read_csv("output/parsed_annotations.csv")

@pytest.mark.parametrize("generate", [False])
def test_download_data(generate):
    everglades_watch = utils.connect()
    df = nest_aggregate.download_data(everglades_watch, generate=generate, min_version=min_version)
    assert not df.empty
    
def test_download_subject_data():
    everglades_watch = utils.connect()
    nest_aggregate.download_subject_data(everglades_watch, savedir="output/", generate=False)
    assert os.path.exists("output/everglades-watch-subjects.csv")
    df = pd.read_csv("output/everglades-watch-subjects.csv")
    assert not df.empty