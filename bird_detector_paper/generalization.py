#Prepare all training sets
import comet_ml
import glob
from pytorch_lightning.loggers import CometLogger
from deepforest import main
from deepforest import preprocess
from matplotlib import pyplot as plt
from shapely.geometry import Point, box
import geopandas as gpd
import pandas as pd
import rasterio as rio
import numpy as np
import os
import shutil
from datetime import datetime
import PIL

def split_test_train(annotations, split = 0.9):
    """Split annotation in train and test by image"""
    #Currently want to mantain the random split
    np.random.seed(0)
    
    #unique annotations for the bird detector
    #annotations = annotations.groupby("selected_i").apply(lambda x: x.head(1))
    
    #add to train_names until reach target split threshold
    image_names = annotations.image_path.unique()
    target = int(annotations.shape[0] * split)
    counter = 0
    train_names = []
    for x in image_names:
        if target > counter:
            train_names.append(x)
            counter+=annotations[annotations.image_path == x].shape[0]
        else:
            break
        
    train = annotations[annotations.image_path.isin(train_names)]
    test = annotations[~(annotations.image_path.isin(train_names))]
    
    return train, test


def shapefile_to_annotations(shapefile, rgb, savedir=".", box_points=False, confidence_filter=False):
    """
    Convert a shapefile of annotations into annotations csv file for DeepForest training and evaluation
    Args:
        shapefile: Path to a shapefile on disk. If a label column is present, it will be used, else all labels are assumed to be "Tree"
        rgb: Path to the RGB image on disk
        savedir: Directory to save csv files
    Returns:
        results: a pandas dataframe
    """
    #Read shapefile
    gdf = gpd.read_file(shapefile)
    if confidence_filter:
        gdf = gdf[gdf.Confidence==1]    
    gdf = gdf[~gdf.geometry.isnull()]
        
    #raster bounds
    with rio.open(rgb) as src:
        left, bottom, right, top = src.bounds
        resolution = src.res[0]
        
    #define in image coordinates and buffer to create a box
    if box_points:
        gdf["geometry"] = gdf.geometry.boundary.centroid
        gdf["geometry"] =[Point(x,y) for x,y in zip(gdf.geometry.x.astype(float), gdf.geometry.y.astype(float))]
    
    gdf["geometry"] = [box(left, bottom, right, top) for left, bottom, right, top in gdf.geometry.buffer(0.15).bounds.values]
        
    #get coordinates
    df = gdf.geometry.bounds
    df = df.rename(columns={"minx":"xmin","miny":"ymin","maxx":"xmax","maxy":"ymax"})    
    
    #Transform project coordinates to image coordinates
    df["tile_xmin"] = (df.xmin - left)/resolution
    df["tile_xmin"] = df["tile_xmin"].astype(int)
    
    df["tile_xmax"] = (df.xmax - left)/resolution
    df["tile_xmax"] = df["tile_xmax"].astype(int)
    
    #UTM is given from the top, but origin of an image is top left
    
    df["tile_ymax"] = (top - df.ymin)/resolution
    df["tile_ymax"] = df["tile_ymax"].astype(int)
    
    df["tile_ymin"] = (top - df.ymax)/resolution
    df["tile_ymin"] = df["tile_ymin"].astype(int)    
    
    df["label"] = "Bird"
    
    #add filename
    df["image_path"] = os.path.basename(rgb)
    
    #select columns
    result = df[["image_path","tile_xmin","tile_ymin","tile_xmax","tile_ymax","label"]]
    result = result.rename(columns={"tile_xmin":"xmin","tile_ymin":"ymin","tile_xmax":"xmax","tile_ymax":"ymax"})
    
    #ensure no zero area polygons due to rounding to pixel size
    result = result[~(result.xmin == result.xmax)]
    result = result[~(result.ymin == result.ymax)]
    
    return result

def prepare_palmyra(generate=True):
    test_path = "/orange/ewhite/b.weinstein/generalization/crops/palmyra_test.csv"
    train_path = "/orange/ewhite/b.weinstein/generalization/crops/palmyra_train.csv"      
    if generate:      
        df = shapefile_to_annotations(
            shapefile="/orange/ewhite/everglades/Palmyra/TNC_Dudley_annotation.shp",
            rgb="/orange/ewhite/everglades/Palmyra/palmyra.tif", box_points=True, confidence_filter=True)
        df.to_csv("Figures/test_annotations.csv",index=False)
        
        src = rio.open("/orange/ewhite/everglades/Palmyra/palmyra.tif")
        numpy_image = src.read()
        numpy_image = np.moveaxis(numpy_image,0,2)
        numpy_image = numpy_image[:,:,:3].astype("uint8")
        
        test_annotations = preprocess.split_raster(numpy_image=numpy_image,
                                                   annotations_file="Figures/test_annotations.csv",
                                                   patch_size=1000, patch_overlap=0.05, base_dir="/orange/ewhite/b.weinstein/generalization/crops/", image_name="palmyra.tif")
        
        test_annotations.to_csv(test_path,index=False)
        
        src = rio.open("/orange/ewhite/everglades/Palmyra/CooperStrawn_53m_tile_clip_projected.tif")
        numpy_image = src.read()
        numpy_image = np.moveaxis(numpy_image,0,2)
        training_image = numpy_image[:,:,:3].astype("uint8")
        
        df = shapefile_to_annotations(
            shapefile="/orange/ewhite/everglades/Palmyra/TNC_Cooper_annotation_03192021.shp", 
            rgb="/orange/ewhite/everglades/Palmyra/CooperStrawn_53m_tile_clip_projected.tif", box_points=True,
            confidence_filter=True
        )
    
        df.to_csv("Figures/training_annotations.csv",index=False)
        
        train_annotations = preprocess.split_raster(
            numpy_image=training_image,
            annotations_file="Figures/training_annotations.csv",
            patch_size=1000,
            patch_overlap=0.05,
            base_dir="/orange/ewhite/b.weinstein/generalization/crops/",
            image_name="CooperStrawn_53m_tile_clip_projected.tif",
            allow_empty=False
        )
        train_annotations.to_csv(train_path,index=False)
            
    return {"train":train_path, "test":test_path}

def prepare_penguin(generate=True):
    test_path = "/orange/ewhite/b.weinstein/generalization/crops/penguins_test.csv"
    train_path = "/orange/ewhite/b.weinstein/generalization/crops/penguins_train.csv"
    
    if generate:
        df = shapefile_to_annotations(shapefile="/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.shp", rgb="/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
        df.to_csv("/orange/ewhite/b.weinstein/penguins/test_annotations.csv",index=False)
        
        src = rio.open("/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
        numpy_image = src.read()
        numpy_image = np.moveaxis(numpy_image,0,2)
        numpy_image = numpy_image[:,:,:3].astype("uint8")
        
        test_annotations = preprocess.split_raster(numpy_image=numpy_image, annotations_file="/orange/ewhite/b.weinstein/penguins/test_annotations.csv", patch_size=800, patch_overlap=0.05,
                                                   base_dir="/orange/ewhite/b.weinstein/penguins/crops", image_name="cape_wallace_survey_8.tif")
        
        test_annotations.to_csv(test_path,index=False)
    
        src = rio.open("/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.tif")
        numpy_image = src.read()
        numpy_image = np.moveaxis(numpy_image,0,2)
        training_image = numpy_image[:,:,:3].astype("uint8")
        
        df = shapefile_to_annotations(shapefile="/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.shp", rgb="/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.tif")
    
        df.to_csv("/orange/ewhite/b.weinstein/penguins/training_annotations.csv",index=False)
        
        train_annotations = preprocess.split_raster(
            numpy_image=training_image,
            annotations_file="/orange/ewhite/b.weinstein/penguins/training_annotations.csv",
            patch_size=800,
            patch_overlap=0.05,
            base_dir="/orange/ewhite/b.weinstein/generalization/crops",
            image_name="offshore_rocks_cape_wallace_survey_4.tif",
            allow_empty=False
        )
        
        train_annotations.to_csv(train_path,index=False)
        
    return {"train":train_path, "test":test_path}

def prepare_everglades():
    
    #too large to repeat here, see create_model.py
    train_path = "/orange/ewhite/b.weinstein/generalization/crops/everglades_train.csv"
    test_path = "/orange/ewhite/b.weinstein/generalization/crops/everglades_test.csv"
    
    return {"train":train_path, "test":test_path}

def prepare_terns(generate=True):
    PIL.Image.MAX_IMAGE_PIXELS = 933120000
    
    test_path = "/orange/ewhite/b.weinstein/generalization/crops/tern_test.csv"
    train_path = "/orange/ewhite/b.weinstein/generalization/crops/terns_train.csv"        
    if generate:   
        df = shapefile_to_annotations(shapefile="/orange/ewhite/b.weinstein/terns/birds.shp", rgb="/orange/ewhite/b.weinstein/terns/seabirds_rgb.tif")
        df.to_csv("/orange/ewhite/b.weinstein/terns/seabirds_rgb.csv")
        
        annotations = preprocess.split_raster(
            path_to_raster="/orange/ewhite/b.weinstein/terns/seabirds_rgb.tif",
            annotations_file="/orange/ewhite/b.weinstein/terns/seabirds_rgb.csv",
            patch_size=1000,
            patch_overlap=0,
            base_dir="/orange/ewhite/b.weinstein/generalization/crops",
            image_name="seabirds_rgb.tif",
            allow_empty=False
        )
        
        #split into train test
        train, test = split_test_train(annotations)
        train.to_csv(train_path,index=False)    
        
        #Test        
        test.to_csv(test_path,index=False)
    
    return {"train":train_path, "test":test_path}

def prepare_murres():
    return {"train":train_path, "test":test_path}

def prepare():
    paths = {}
    #paths["murres"] = prepare_murres()
    paths["terns"] = prepare_terns()
    paths["everglades"] = prepare_everglades()
    paths["penguins"] = prepare_penguin()
    paths["palmyra"] = prepare_palmyra()
    
    return paths

def train(path_dict, train_sets = ["penguins","terns","everglades","palmyra"],test_sets=["everglades"]):
    comet_logger = CometLogger(api_key="ypQZhYfs3nSyKzOfz13iuJpj2",
                                  project_name="everglades", workspace="bw4sz")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_dir="/orange/ewhite/b.weinstein/generalization/"
    model_savedir = "{}/{}".format(save_dir,timestamp)  
    
    try:
        os.mkdir(model_savedir)
    except Exception as e:
        print(e)
    
    comet_logger.experiment.log_parameter("timestamp",timestamp)
    comet_logger.experiment.log_parameter("train_set",train_sets)
    comet_logger.experiment.log_parameter("test_set",test_sets)
    
    comet_logger.experiment.add_tag("Generalization")
    
    all_sets = []
    for x in train_sets:
        df = pd.read_csv(path_dict[x]["train"])
        all_sets.append(df)
    
    train_annotations = pd.concat(all_sets)
    train_annotations.to_csv("/orange/ewhite/b.weinstein/generalization/crops/training_annotations.csv")

    all_val_sets = []
    for x in test_sets:
        df = pd.read_csv(path_dict[x]["test"])
        all_val_sets.append(df)
    
    test_annotations = pd.concat(all_val_sets)
    test_annotations.to_csv("/orange/ewhite/b.weinstein/generalization/crops/test_annotations.csv")

    comet_logger.experiment.log_parameter("training_images",len(train_annotations.image_path.unique()))
    comet_logger.experiment.log_parameter("training_annotations",train_annotations.shape[0])

    model = main.deepforest()

    try:
        os.mkdir(model_savedir)
    except:
        pass
    
    model.config["train"]["csv_file"] = "/orange/ewhite/b.weinstein/generalization/crops/training_annotations.csv"
    model.config["train"]["root_dir"] = "/orange/ewhite/b.weinstein/generalization/crops"    
    model.config["validation"]["csv_file"] = "/orange/ewhite/b.weinstein/generalization/crops/test_annotations.csv"
    model.config["validation"]["root_dir"] = "/orange/ewhite/b.weinstein/generalization/crops"
    
    model.create_trainer(logger=comet_logger)
    comet_logger.experiment.log_parameters(model.config)
    
    model.trainer.fit(model)
    
    test_results = model.evaluate(csv_file="/orange/ewhite/b.weinstein/penguins/crops/test_annotations.csv", root_dir="/orange/ewhite/b.weinstein/penguins/crops/", iou_threshold=0.25)
    
    if comet_logger is not None:
        try:
            test_results["results"].to_csv("{}/iou_dataframe.csv".format(model_savedir))
            comet_logger.experiment.log_asset("{}/iou_dataframe.csv".format(model_savedir))
            
            test_results["class_recall"].to_csv("{}/class_recall.csv".format(model_savedir))
            comet_logger.experiment.log_asset("{}/class_recall.csv".format(model_savedir))
            
            for index, row in test_results["class_recall"].iterrows():
                comet_logger.experiment.log_metric("{}_Recall".format(row["label"]),row["recall"])
                comet_logger.experiment.log_metric("{}_Precision".format(row["label"]),row["precision"])
            
            comet_logger.experiment.log_metric("Average Class Recall",test_results["class_recall"].recall.mean())
            comet_logger.experiment.log_metric("Box Recall",test_results["box_recall"])
            comet_logger.experiment.log_metric("Box Precision",test_results["box_precision"])
        except Exception as e:
            print(e)
    
    recall = test_results["box_recall"]
    precision = test_results["box_precision"]    
    print("Recall is {}".format(recall))
    print("Precision is {}".format(precision))
    
    comet_logger.experiment.log_metric("precision",precision)
    comet_logger.experiment.log_metric("recall", recall)
    
    #log images
    model.predict_file(csv_file = model.config["validation"]["csv_file"], root_dir = model.config["validation"]["root_dir"], savedir=model_savedir)
    images = glob.glob("{}/*.png".format(model_savedir))
    for img in images:
        comet_logger.experiment.log_image(img)
        
    comet_logger.experiment.end()
    
    formatted_results = pd.DataFrame({"train": train_sets, "test": test_sets, "precision": [precision],"recall": [recall]})
    
    return formatted_results        


if __name__ =="__main__":
    path_dict = prepare()
    result = train(path_dict=path_dict, train_sets=["penguins","everglades","palmyra"], test_sets=["terns"])
    