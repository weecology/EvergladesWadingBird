"""Script to take the trained everglades model and predict the Palmyra data"""
#srun -p gpu --gpus=1 --mem 40GB --time 5:00:00 --pty -u bash -i
# conda activate Zooniverse_pytorch
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
import start_cluster
from dask.distributed import wait
import traceback
import IoU

def shapefile_to_annotations(shapefile, rgb, savedir="."):
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
    gdf = gdf[~gdf.geometry.isnull()]
        
    #raster bounds
    with rio.open(rgb) as src:
        left, bottom, right, top = src.bounds
        resolution = src.res[0]
        
    #define in image coordinates and buffer to create a box
    gdf["geometry"] = [box(left, bottom, right, top) for left, bottom, right, top in gdf.geometry.buffer(0.2).bounds.values]
        
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
    
    #Add labels is they exist
    if "label" in gdf.columns:
        df["label"] = gdf["label"]
    else:
        df["label"] = "Tree"
    
    #add filename
    df["image_path"] = os.path.basename(rgb)
    
    #select columns
    result = df[["image_path","tile_xmin","tile_ymin","tile_xmax","tile_ymax","label"]]
    result = result.rename(columns={"tile_xmin":"xmin","tile_ymin":"ymin","tile_xmax":"xmax","tile_ymax":"ymax"})
    
    #ensure no zero area polygons due to rounding to pixel size
    result = result[~(result.xmin == result.xmax)]
    result = result[~(result.ymin == result.ymax)]
    
    return result
 
def prepare_test(patch_size=2000):
    df = shapefile_to_annotations(shapefile="/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.shp", rgb="/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
    df.to_csv("/orange/ewhite/b.weinstein/penguins/test_annotations.csv",index=False)
    
    src = rio.open("/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
    numpy_image = src.read()
    numpy_image = np.moveaxis(numpy_image,0,2)
    numpy_image = numpy_image[:,:,:3].astype("uint8")
    
    test_annotations = preprocess.split_raster(numpy_image=numpy_image, annotations_file="/orange/ewhite/b.weinstein/penguins/test_annotations.csv", patch_size=patch_size, patch_overlap=0.05,
                                               base_dir="/orange/ewhite/b.weinstein/penguins/crops", image_name="cape_wallace_survey_8.tif")
    print(test_annotations.head())
    test_annotations.to_csv("/orange/ewhite/b.weinstein/penguins/crops/test_annotations.csv",index=False)

def prepare_train(patch_size=2000):
    src = rio.open("/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.tif")
    numpy_image = src.read()
    numpy_image = np.moveaxis(numpy_image,0,2)
    training_image = numpy_image[:,:,:3].astype("uint8")
    
    df = shapefile_to_annotations(shapefile="/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.shp", rgb="/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.tif")

    df.to_csv("/orange/ewhite/b.weinstein/penguins/training_annotations.csv",index=False)
    
    train_annotations = preprocess.split_raster(
        numpy_image=training_image,
        annotations_file="/orange/ewhite/b.weinstein/penguins/training_annotations.csv",
        patch_size=patch_size,
        patch_overlap=0.05,
        base_dir="/orange/ewhite/b.weinstein/penguins/crops",
        image_name="offshore_rocks_cape_wallace_survey_4.tif",
        allow_empty=False
    )
    
    train_annotations.to_csv("/orange/ewhite/b.weinstein/penguins/crops/full_training_annotations.csv",index=False)
    
def training(proportion, patch_size=2000,pretrained=True, iteration=None):

    os.environ["SLURM_JOB_NAME"] = "bash"

    comet_logger = CometLogger(api_key="ypQZhYfs3nSyKzOfz13iuJpj2",
                                  project_name="everglades", workspace="bw4sz")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    save_dir="/orange/ewhite/everglades/Palmyra/"
    model_savedir = "{}/{}".format(save_dir,timestamp)  
    
    try:
        os.mkdir(model_savedir)
    except Exception as e:
        print(e)
    
    comet_logger.experiment.log_parameter("timestamp",timestamp)
    
    comet_logger.experiment.log_parameter("proportion",proportion)
    comet_logger.experiment.log_parameter("patch_size",patch_size)
    
    comet_logger.experiment.add_tag("Penguin")
    
    train_annotations = pd.read_csv("/orange/ewhite/b.weinstein/penguins/crops/full_training_annotations.csv")
    crops = train_annotations.image_path.unique()    
    
    if not proportion == 0:
        if proportion < 1:  
            #set new seed
            np.random.seed()
            selected_crops = np.random.choice(crops, size = int(proportion*len(crops)),replace=False)
            train_annotations = train_annotations[train_annotations.image_path.isin(selected_crops)]
    
    train_annotations.to_csv("/orange/ewhite/b.weinstein/penguins/crops/training_annotations.csv", index=False)
    
    comet_logger.experiment.log_parameter("training_images",len(train_annotations.image_path.unique()))
    comet_logger.experiment.log_parameter("training_annotations",train_annotations.shape[0])
    comet_logger.experiment.log_parameter("pretrained", pretrained)
        
    if pretrained:
        model = main.deepforest.load_from_checkpoint("/orange/ewhite/everglades/Zooniverse/predictions//20210404_180042/species_model.pl")
    else:
        model = main.deepforest()
    try:
        os.mkdir("/orange/ewhite/b.weinstein/penguins/{}/".format(proportion))
    except:
        pass
    
    #if not pretrained, train for 50% longer
    if not pretrained:
        model.config["train"]["epochs"] = int(model.config["train"]["epochs"] * 2)
        
    model.config["train"]["csv_file"] = "/orange/ewhite/b.weinstein/penguins/crops/training_annotations.csv"
    model.config["train"]["root_dir"] = "/orange/ewhite/b.weinstein/penguins/crops"    
    model.config["validation"]["csv_file"] = "/orange/ewhite/b.weinstein/penguins/crops/test_annotations.csv"
    model.config["validation"]["root_dir"] = "/orange/ewhite/b.weinstein/penguins/crops"
    
    model.create_trainer(logger=comet_logger)
    comet_logger.experiment.log_parameters(model.config)
    
    if not proportion == 0:
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
                
    ##Evaluate against model
    #src = rio.open("/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
    #numpy_image = src.read()
    #numpy_image = np.moveaxis(numpy_image,0,2)
    #numpy_image = numpy_image[:,:,:3].astype("uint8")    
    #boxes = model.predict_tile(image=numpy_image, return_plot=False, patch_size=patch_size, patch_overlap=0.05)
    
    #if boxes is None:
        #return 0,0
    
    #bounds = src.bounds
    #pixelSizeX, pixelSizeY  = src.res
    
    ##subtract origin. Recall that numpy origin is top left! Not bottom left.
    #boxes["xmin"] = (boxes["xmin"] *pixelSizeX) + bounds.left
    #boxes["xmax"] = (boxes["xmax"] * pixelSizeX) + bounds.left
    #boxes["ymin"] = bounds.top - (boxes["ymin"] * pixelSizeY) 
    #boxes["ymax"] = bounds.top - (boxes["ymax"] * pixelSizeY)
    
    ## combine column to a shapely Box() object, save shapefile
    #boxes['geometry'] = boxes.apply(lambda x: shapely.geometry.box(x.xmin,x.ymin,x.xmax,x.ymax), axis=1)
    #boxes = gpd.GeoDataFrame(boxes, geometry='geometry')
    
    #boxes.crs = src.crs.to_wkt()
    #boxes.to_file("Figures/predictions_{}.shp".format(proportion))
    #comet_logger.experiment.log_asset("Figures/predictions_{}.shp".format(proportion))
    
    ##define in image coordinates and buffer to create a box
    #gdf = gpd.read_file("/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.shp")
    #gdf = gdf[~gdf.geometry.isnull()]
    #gdf["geometry"] = [box(left, bottom, right, top) for left, bottom, right, top in gdf.geometry.buffer(0.15).bounds.values]
    
    #results = IoU.compute_IoU(gdf, boxes)
    #results["match"] = results.IoU > 0.25
    
    #results.to_csv("Figures/iou_dataframe_{}.csv".format(proportion))
    #comet_logger.experiment.log_asset("Figures/iou_dataframe_{}.csv".format(proportion))
    
    #true_positive = sum(results["match"] == True)
    #recall = true_positive / results.shape[0]
    #precision = true_positive / boxes.shape[0]
    
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
    
    if proportion == 0:
        num_annotations = 0
    else:
        num_annotations = train_annotations.shape[0]
    formatted_results = pd.DataFrame({"proportion":[proportion], "pretrained": [pretrained], "annotations": [num_annotations],"precision": [precision],"recall": [recall], "iteration":[iteration]})
    
    return formatted_results

def run(patch_size=900, generate=False, client=None):
    if generate:
        folder = '/orange/ewhite/b.weinstein/penguins/crops/'
        for filename in os.listdir(folder):
            file_path = os.path.join(folder, filename)
            try:
                if os.path.isfile(file_path) or os.path.islink(file_path):
                    os.unlink(file_path)
                elif os.path.isdir(file_path):
                    shutil.rmtree(file_path)
            except Exception as e:
                print('Failed to delete %s. Reason: %s' % (file_path, e))
                
        prepare_test(patch_size=patch_size)
        prepare_train(patch_size=int(patch_size))
  
    iteration_result = []
    futures = []
    
    # run zero shot only once
    #future = client.submit(training, pretrained=True, patch_size=patch_size, proportion=0)
    #futures.append(future)
    
    #future = client.submit(training, pretrained=False, patch_size=patch_size, proportion=0)
    #futures.append(future)
    
    #run x times to get uncertainty in sampling
    
    iteration = 0
    while iteration < 6:
        for x in [0, 1]:
            for y in [True, False]: 
                if client is not None:
                    future = client.submit(training,proportion=x, patch_size=patch_size, pretrained=y, iteration = iteration)
                    futures.append(future)
                else:
                    experiment_result = training(proportion=x, patch_size=patch_size, pretrained=y, iteration = iteration)
                    iteration_result.append(experiment_result)
        iteration+=1
                    
    if client is not None:
        wait(futures)
        for future in futures:
            iteration_result.append(future.result())

    print(iteration_result)
    results = pd.concat(iteration_result)
    results.to_csv("Figures/penguin_results_{}.csv".format(patch_size)) 

if __name__ == "__main__":
    #client = start_cluster.start(gpus=4, mem_size="30GB")
    run(client=None)
