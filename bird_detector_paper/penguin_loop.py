"""Script to take the trained everglades model and predict the penguin data"""
#srun -p gpu --gpus=1 --mem 40GB --time 5:00:00 --pty -u bash -i
# conda activate Zooniverse
import comet_ml
from deepforest import deepforest
from matplotlib import pyplot as plt
from shapely.geometry import Point, box
import geopandas as gpd
import shapely
import pandas as pd
import rasterio as rio
import numpy as np
import os
import shutil
import shapely

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
    gdf["geometry"] = [box(left, bottom, right, top) for left, bottom, right, top in gdf.geometry.buffer(0.4).bounds.values]
        
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
    df = shapefile_to_annotations(shapefile="/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.shp",
                                  rgb="/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
    df.to_csv("Figures/test_annotations.csv",index=False)
    
    src = rio.open("/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
    numpy_image = src.read()
    numpy_image = np.moveaxis(numpy_image,0,2)
    numpy_image = numpy_image[:,:,:3].astype("uint8")
    
    test_annotations = deepforest.preprocess.split_raster(numpy_image=numpy_image,
                                                          annotations_file="Figures/test_annotations.csv",
                                                          patch_size=patch_size, patch_overlap=0.05,
                                                          base_dir="crops", image_name="cape_wallace_survey_8.tif")
    print(test_annotations.head())
        
    test_annotations.to_csv("crops/test_annotations.csv",index=False, header=False)

def prepare_train(patch_size=2000):
    src = rio.open("/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.tif")
    numpy_image = src.read()
    numpy_image = np.moveaxis(numpy_image,0,2)
    training_image = numpy_image[:,:,:3].astype("uint8")
    
    df = shapefile_to_annotations(
        shapefile="/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.shp",
        rgb="/orange/ewhite/b.weinstein/penguins/offshore_rocks_cape_wallace_survey_4.tif")

    df.to_csv("Figures/offshore_rocks_cape_wallace_survey_4_annotations.csv",index=False)
    
    train_annotations = deepforest.preprocess.split_raster(
        numpy_image=training_image,
        annotations_file="Figures/offshore_rocks_cape_wallace_survey_4_annotations.csv",
        patch_size=patch_size,
        patch_overlap=0.05,
        base_dir="crops",
        image_name="offshore_rocks_cape_wallace_survey_4.tif",
        allow_empty=False
    )
    
    train_annotations.to_csv("crops/full_training_annotations.csv",index=False, header=False)
    
def training(proportion, epochs=10, patch_size=1000,pretrained=True):
    comet_experiment = comet_ml.Experiment(api_key="ypQZhYfs3nSyKzOfz13iuJpj2",project_name="everglades", workspace="bw4sz")
    
    comet_experiment.log_parameter("proportion",proportion)
    comet_experiment.log_parameter("patch_size",patch_size)
    
    comet_experiment.add_tag("Penguin")
    
    train_annotations = pd.read_csv("crops/full_training_annotations.csv", names=["image_path","xmin","ymin","xmax","ymax","label"])
    crops = train_annotations.image_path.unique()    
    
    if not proportion == 0:
        if proportion < 1:  
            selected_crops = np.random.choice(crops, size = int(proportion*len(crops)),replace=False)
            train_annotations = train_annotations[train_annotations.image_path.isin(selected_crops)]
    
    train_annotations.to_csv("crops/training_annotations.csv", index=False, header=False)
    
    comet_experiment.log_parameter("training_images",len(train_annotations.image_path.unique()))
    comet_experiment.log_parameter("training_annotations",train_annotations.shape[0])
        
    if pretrained:
        model_path = "/orange/ewhite/everglades/Zooniverse/predictions/20210131_015711.h5"
        model = deepforest.deepforest(weights=model_path)
    else:
        model = deepforest.deepforest()
        model.use_release()
    try:
        os.mkdir("/orange/ewhite/b.weinstein/penguins/{}/".format(proportion))
    except:
        pass
    
    model.config["save_path"] = "/orange/ewhite/b.weinstein/penguins/"
    model.config["epochs"] = epochs
    model.config["validation_annotations"] = "crops/test_annotations.csv"
    
    if not proportion == 0:
        model.train(annotations="crops/training_annotations.csv", comet_experiment=comet_experiment)
    
    model.evaluate_generator(annotations="crops/test_annotations.csv", color_annotation=(0,255,0),color_detection=(255,255,0), comet_experiment=comet_experiment)
    model.evaluate_generator(annotations="crops/training_annotations.csv", color_annotation=(0,255,0),color_detection=(255,255,0), comet_experiment=comet_experiment)
    
   
    src = rio.open("/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.tif")
    numpy_image = src.read()
    numpy_image = np.moveaxis(numpy_image,0,2)
    numpy_image = numpy_image[:,:,:3].astype("uint8")    
    boxes = model.predict_tile(numpy_image=numpy_image, return_plot=False, patch_size=patch_size, patch_overlap=0.05)
    
    if boxes is None:
        return 0,0
    
    bounds = src.bounds
    pixelSizeX, pixelSizeY  = src.res
    
    #subtract origin. Recall that numpy origin is top left! Not bottom left.
    boxes["xmin"] = (boxes["xmin"] *pixelSizeX) + bounds.left
    boxes["xmax"] = (boxes["xmax"] * pixelSizeX) + bounds.left
    boxes["ymin"] = bounds.top - (boxes["ymin"] * pixelSizeY) 
    boxes["ymax"] = bounds.top - (boxes["ymax"] * pixelSizeY)
    
    # combine column to a shapely Box() object, save shapefile
    boxes['geometry'] = boxes.apply(lambda x: shapely.geometry.box(x.xmin,x.ymin,x.xmax,x.ymax), axis=1)
    boxes = gpd.GeoDataFrame(boxes, geometry='geometry')
    
    boxes.crs = src.crs.to_wkt()
    boxes.to_file("Figures/penguin_predictions_{}.shp".format(proportion))
    comet_experiment.log_asset("Figures/penguin_predictions_{}.shp".format(proportion))
    
    #define in image coordinates and buffer to create a box
    gdf = gpd.read_file("/orange/ewhite/b.weinstein/penguins/cape_wallace_survey_8.shp")
    gdf = gdf[~gdf.geometry.isnull()]
    gdf["geometry"] = [box(left, bottom, right, top) for left, bottom, right, top in gdf.geometry.buffer(0.4).bounds.values]
    
    results = IoU.compute_IoU(gdf, boxes)
    results["match"] = results.IoU > 0.25
    
    results.to_csv("Figures/penguin_iou_dataframe_{}.csv".format(proportion))
    comet_experiment.log_asset("Figures/penguin_iou_dataframe_{}.csv".format(proportion))
    
    true_positive = sum(results["match"] == True)
    recall = true_positive / results.shape[0]
    precision = true_positive / boxes.shape[0]
    
    print("Recall is {}".format(recall))
    print("Precision is {}".format(precision))
    
    comet_experiment.log_metric("precision",precision)
    comet_experiment.log_metric("recall", recall)
    
    #repeat using predict_generator
    iou_dataframe = []
    image_boxes = model.predict_generator("crops/test_annotations.csv")
    ground_truth = pd.read_csv("crops/test_annotations.csv",names=["image_path","xmin","ymin","xmax","ymax","label"])
    for name, group in image_boxes.groupby("plot_name"):
        group = group.reset_index(drop=True)
        ground_df = ground_truth[ground_truth.image_path == "{}.png".format(name)].reset_index(drop=True)
        ground_df['geometry'] = ground_df.apply(
            lambda x: shapely.geometry.box(x.xmin, x.ymin, x.xmax, x.ymax), axis=1)
        ground_df = gpd.GeoDataFrame(ground_df, geometry='geometry')
        group['geometry'] = group.apply(
            lambda x: shapely.geometry.box(x.xmin, x.ymin, x.xmax, x.ymax), axis=1)
        predictions = gpd.GeoDataFrame(group, geometry='geometry')
        image_results = IoU.compute_IoU(ground_df, predictions)
        iou_dataframe.append(image_results)

    results = pd.concat(iou_dataframe)
    results["match"] = results.IoU > 0.25
    
    results.to_csv("Figures/crop_penguin_iou_dataframe_{}.csv".format(proportion))
    comet_experiment.log_asset("Figures/crop_penguin_iou_dataframe_{}.csv".format(proportion))
    
    true_positive = sum(results["match"] == True)
    recall = true_positive / results.shape[0]
    precision = true_positive / image_boxes.shape[0]
    
    print("Crop Recall is {}".format(recall))
    print("Crop Precision is {}".format(precision))
    
    comet_experiment.log_metric("crop_precision",precision)
    comet_experiment.log_metric("crop_recall", recall)    
    
    comet_experiment.end()
    
    return precision, recall

def run(patch_size=900):

    folder = 'crops/'
    for filename in os.listdir(folder):
        file_path = os.path.join(folder, filename)
        try:
            if os.path.isfile(file_path) or os.path.islink(file_path):
                os.unlink(file_path)
            elif os.path.isdir(file_path):
                shutil.rmtree(file_path)
        except Exception as e:
            print('Failed to delete %s. Reason: %s' % (file_path, e))
            
    proportion = []
    recall = []
    precision = []
    pretrained =[]
    
    prepare_test(patch_size=patch_size)
    #Only open training raster once because its so huge
    prepare_train(patch_size=int(patch_size))
    
    try:
        p , r = training(proportion=0, pretrained=True, patch_size=patch_size)
    except Exception as e:
        print(e)
        
    p , r = training(proportion=1, pretrained=True, patch_size=patch_size)
    
    for x in [0,0.25, 0.5, 0.75, 1]:
        print(x)
        for y in [True, False]:     
            p , r = training(proportion=x, pretrained=y, patch_size=patch_size)
            precision.append(p)
            recall.append(r)
            proportion.append(x)
            pretrained.append(y)
    
    results = pd.DataFrame({"precision":precision,"recall": recall,"proportion":proportion, "pretrained":pretrained})
    results.to_csv("Figures/results_{}.csv".format(patch_size)) 

if __name__ == "__main__":
    run()
    #for x in [1500,2000,2500,3000, 4000]:
        #run(patch_size=x)
